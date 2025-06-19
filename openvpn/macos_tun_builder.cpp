#include "macos_tun_builder.h"

#ifdef __APPLE__

#include <sys/socket.h>
#include <sys/kern_control.h>
#include <sys/ioctl.h>
#include <sys/sys_domain.h>
#include <net/if_utun.h>
#include <net/route.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <fcntl.h>
#include <iostream>
#include <cstring>

// Include OpenVPN3 Core headers
#include "build/deps/openvpn3-core/openvpn/tun/builder/base.hpp"

using namespace openvpn;

/**
 * macOS utun TUN builder implementation
 */
class MacOSTunBuilderImpl : public TunBuilderBase {
private:
    int tun_fd_;
    std::string tun_name_;
    std::vector<std::string> routes_;
    std::string vpn_ip_;
    std::string vpn_netmask_;
    std::string gateway_;
    
public:
    MacOSTunBuilderImpl() : tun_fd_(-1) {}
    
    virtual ~MacOSTunBuilderImpl() {
        if (tun_fd_ >= 0) {
            close(tun_fd_);
        }
    }
    
    // Initialize a new TUN builder session
    bool tun_builder_new() override {
        std::cout << "🔧 macOS TUN: Starting new TUN builder session" << std::endl;
        routes_.clear();
        vpn_ip_.clear();
        vpn_netmask_.clear();
        gateway_.clear();
        return true;
    }
    
    // Set VPN IP address and netmask
    bool tun_builder_set_layer(int layer) override {
        return layer == 3; // Only support Layer 3 (IP)
    }
    
    bool tun_builder_set_remote_address(const std::string& address, bool ipv6) override {
        if (!ipv6) {
            std::cout << "🔧 macOS TUN: Remote address: " << address << std::endl;
        }
        return true;
    }
    
    bool tun_builder_add_address(const std::string& address,
                                int prefix_length,
                                const std::string& gateway,
                                bool ipv6,
                                bool net30) override {
        if (!ipv6) {
            vpn_ip_ = address;
            gateway_ = gateway;
            // Convert prefix length to netmask
            uint32_t mask = (0xFFFFFFFF << (32 - prefix_length)) & 0xFFFFFFFF;
            vpn_netmask_ = std::to_string((mask >> 24) & 0xFF) + "." +
                          std::to_string((mask >> 16) & 0xFF) + "." +
                          std::to_string((mask >> 8) & 0xFF) + "." +
                          std::to_string(mask & 0xFF);
            
            std::cout << "🔧 macOS TUN: VPN IP: " << vpn_ip_ << "/" << prefix_length 
                      << " Gateway: " << gateway_ << std::endl;
        }
        return true;
    }
    
    bool tun_builder_add_route(const std::string& address,
                              int prefix_length,
                              int metric,
                              bool ipv6) override {
        if (!ipv6) {
            std::string route = address + "/" + std::to_string(prefix_length);
            routes_.push_back(route);
            std::cout << "🔧 macOS TUN: Adding route: " << route << std::endl;
        }
        return true;
    }
    
    bool tun_builder_set_dns_options(const DnsOptions& dns) override {
        std::cout << "🔧 macOS TUN: DNS options configured" << std::endl;
        return true;
    }
    
    bool tun_builder_set_mtu(int mtu) override {
        std::cout << "🔧 macOS TUN: MTU: " << mtu << std::endl;
        return true;
    }
    
    // Establish the TUN interface
    int tun_builder_establish() override {
        std::cout << "🔧 macOS TUN: Establishing utun interface..." << std::endl;

        // Create utun socket
        tun_fd_ = socket(PF_SYSTEM, SOCK_DGRAM, SYSPROTO_CONTROL);
        if (tun_fd_ < 0) {
            std::cerr << "❌ Failed to create utun socket: " << strerror(errno) << std::endl;
            return -1;
        }

        // Connect to utun control
        struct sockaddr_ctl sc;
        struct ctl_info ctlInfo;

        memset(&ctlInfo, 0, sizeof(ctlInfo));
        strncpy(ctlInfo.ctl_name, UTUN_CONTROL_NAME, sizeof(ctlInfo.ctl_name));

        if (ioctl(tun_fd_, CTLIOCGINFO, &ctlInfo) == -1) {
            std::cerr << "❌ Failed to get utun control info: " << strerror(errno) << std::endl;
            close(tun_fd_);
            tun_fd_ = -1;
            return -1;
        }

        sc.sc_id = ctlInfo.ctl_id;
        sc.sc_len = sizeof(sc);
        sc.sc_family = AF_SYSTEM;
        sc.ss_sysaddr = AF_SYS_CONTROL;
        sc.sc_unit = 0; // Let system choose unit number

        if (connect(tun_fd_, (struct sockaddr *)&sc, sizeof(sc)) == -1) {
            std::cerr << "❌ Failed to connect to utun control: " << strerror(errno) << std::endl;
            close(tun_fd_);
            tun_fd_ = -1;
            return -1;
        }

        // Get interface name
        char ifname_buf[256];
        socklen_t ifname_len = sizeof(ifname_buf);
        if (getsockopt(tun_fd_, SYSPROTO_CONTROL, UTUN_OPT_IFNAME,
                      ifname_buf, &ifname_len) == -1) {
            std::cerr << "❌ Failed to get utun interface name: " << strerror(errno) << std::endl;
            close(tun_fd_);
            tun_fd_ = -1;
            return -1;
        }
        tun_name_ = std::string(ifname_buf);

        std::cout << "✅ macOS TUN: Created interface " << tun_name_ << " (fd=" << tun_fd_ << ")" << std::endl;

        // Configure the interface with VPN IP
        if (!configureInterface()) {
            std::cerr << "❌ Failed to configure interface" << std::endl;
            close(tun_fd_);
            tun_fd_ = -1;
            return -1;
        }

        return tun_fd_;
    }

private:
    bool configureInterface() {
        if (vpn_ip_.empty() || tun_name_.empty()) {
            std::cerr << "❌ Missing VPN IP or interface name for configuration" << std::endl;
            return false;
        }

        std::cout << "🔧 Configuring interface " << tun_name_ << " with IP " << vpn_ip_ << std::endl;

        // Configure IP address using ifconfig
        std::string cmd = "ifconfig " + tun_name_ + " " + vpn_ip_ + " " + vpn_ip_ + " up";
        std::cout << "🔧 Running: " << cmd << std::endl;

        int result = system(cmd.c_str());
        if (result != 0) {
            std::cerr << "❌ Failed to configure IP address" << std::endl;
            return false;
        }

        // Add routes
        for (const auto& route : routes_) {
            std::string route_cmd = "route add -net " + route + " -interface " + tun_name_;
            std::cout << "🔧 Adding route: " << route_cmd << std::endl;
            system(route_cmd.c_str());
        }

        std::cout << "✅ Interface " << tun_name_ << " configured successfully" << std::endl;
        return true;
    }

public:
    
    bool tun_builder_persist() override {
        return false; // Don't persist
    }
    
    void tun_builder_teardown(bool disconnect) override {
        std::cout << "🔧 macOS TUN: Tearing down interface " << tun_name_ << std::endl;
        if (tun_fd_ >= 0) {
            close(tun_fd_);
            tun_fd_ = -1;
        }
    }
};

// MacOSTunBuilder implementation
class MacOSTunBuilder::Impl {
public:
    std::unique_ptr<MacOSTunBuilderImpl> builder_;
    
    Impl() {
        builder_ = std::make_unique<MacOSTunBuilderImpl>();
    }
};

MacOSTunBuilder::MacOSTunBuilder() : impl_(std::make_unique<Impl>()) {}

MacOSTunBuilder::~MacOSTunBuilder() = default;

std::unique_ptr<openvpn::TunBuilderBase> MacOSTunBuilder::createTunBuilder() {
    return std::make_unique<MacOSTunBuilderImpl>();
}

bool MacOSTunBuilder::isAvailable() {
    // Check if we can create a utun socket
    int test_fd = socket(PF_SYSTEM, SOCK_DGRAM, SYSPROTO_CONTROL);
    if (test_fd >= 0) {
        close(test_fd);
        return true;
    }
    return false;
}

#else

// Non-macOS implementation
MacOSTunBuilder::MacOSTunBuilder() {}
MacOSTunBuilder::~MacOSTunBuilder() {}

std::unique_ptr<openvpn::TunBuilderBase> MacOSTunBuilder::createTunBuilder() {
    return nullptr;
}

bool MacOSTunBuilder::isAvailable() {
    return false;
}

#endif // __APPLE__
