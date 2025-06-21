#include "openvpn3_wrapper.h"
#include <thread>
#include <chrono>
#include <atomic>
#include <memory>
#include <mutex>
#include <iostream>

// Include OpenVPN3 Core compatibility header first
#include "openvpn3_compat.h"

// Include OpenVPN3 Core API
#include "client/ovpncli.hpp"

#define LOG_TAG "OpenVPN3Wrapper"

// Generic logging that works on all platforms
#define LOGI(...) do { printf("[INFO] " LOG_TAG ": " __VA_ARGS__); printf("\n"); fflush(stdout); } while(0)
#define LOGE(...) do { printf("[ERROR] " LOG_TAG ": " __VA_ARGS__); printf("\n"); fflush(stdout); } while(0)

// Real OpenVPN3 client implementation using OpenVPN3 Core API
class OpenVPN3ClientImpl : public openvpn::ClientAPI::OpenVPNClient {
public:
    OpenVPN3ClientImpl(OpenVPN3Wrapper::StatusCallback callback)
        : status_callback_(std::move(callback)), connected_(false), connecting_(false), should_stop_(false) {
        LOGI("Real OpenVPN3 Core client implementation created");
    }

    ~OpenVPN3ClientImpl() {
        disconnectFromServer();
    }

    // Real OpenVPN3 connection method using OpenVPN3 Core API
    bool connectToServer(const std::string& config, const std::string& username, const std::string& password) {
        try {
            LOGI("Starting real OpenVPN3 Core connection");

            // Check if already connecting or connected
            if (connecting_ || connected_) {
                LOGI("Already connecting or connected, ignoring new connection request");
                return true; // Return true since we're already in the desired state
            }

            if (status_callback_) {
                status_callback_("connecting", "Initializing OpenVPN3 Core...");
            }

            connecting_ = true;
            connected_ = false;
            should_stop_ = false;

            // Store credentials
            username_ = username;
            password_ = password;

            // Start real OpenVPN3 Core connection in background thread
            connect_thread_ = std::thread([this, config]() {
                try {
                    // Parse OpenVPN configuration using OpenVPN3 Core
                    openvpn::ClientAPI::Config ovpn_config;
                    ovpn_config.content = config;

                    // Connection timeout for TLS handshake
                    ovpn_config.connTimeout = 120; // 2 minutes for TLS handshake

                    // Basic settings - generic for all platforms
                    ovpn_config.dco = false; // Disable DCO for compatibility
                    ovpn_config.tunPersist = false;
                    ovpn_config.googleDnsFallback = true;
                    ovpn_config.allowLocalDnsResolvers = true;
                    ovpn_config.autologinSessions = false;

                    LOGI("Using generic cross-platform OpenVPN3 configuration");

                    // TLS settings
                    ovpn_config.enableLegacyAlgorithms = false; // Disable legacy TLS algorithms

                    // Compression mode - use "yes" to allow compression
                    ovpn_config.compressionMode = "yes";

                    LOGI("Evaluating OpenVPN configuration with OpenVPN3 Core...");
                    if (status_callback_) {
                        status_callback_("connecting", "Evaluating configuration...");
                    }

                    auto eval_result = eval_config(ovpn_config);

                    if (eval_result.error) {
                        LOGE("OpenVPN3 Core configuration evaluation failed: %s", eval_result.message.c_str());
                        if (status_callback_) {
                            status_callback_("error", "Configuration error: " + eval_result.message);
                        }
                        connecting_ = false;
                        return;
                    }

                    LOGI("OpenVPN3 Core configuration evaluated successfully");
                    LOGI("Profile: %s, Server: %s:%s, Protocol: %s",
                         eval_result.profileName.c_str(),
                         eval_result.remoteHost.c_str(),
                         eval_result.remotePort.c_str(),
                         eval_result.remoteProto.c_str());

                    // Provide credentials if needed
                    if (!eval_result.autologin && !username_.empty()) {
                        LOGI("Providing user credentials to OpenVPN3 Core");
                        if (status_callback_) {
                            status_callback_("authenticating", "Providing credentials...");
                        }

                        openvpn::ClientAPI::ProvideCreds creds;
                        creds.username = username_;
                        creds.password = password_;

                        auto creds_status = provide_creds(creds);
                        if (creds_status.error) {
                            LOGE("OpenVPN3 Core failed to accept credentials: %s", creds_status.message.c_str());
                            if (status_callback_) {
                                status_callback_("error", "Credential error: " + creds_status.message);
                            }
                            connecting_ = false;
                            return;
                        }
                        LOGI("Credentials provided to OpenVPN3 Core successfully");
                    }

                    // Start the real OpenVPN3 Core connection
                    LOGI("Starting OpenVPN3 Core connection process...");
                    if (status_callback_) {
                        status_callback_("connecting", "Starting OpenVPN3 Core connection...");
                    }

                    connect_time_ = std::chrono::steady_clock::now();

                    // This will call our event() callback methods as the connection progresses
                    auto connect_status = connect();

                    // The connect() method has completed - check the result
                    if (connect_status.error) {
                        LOGE("OpenVPN3 Core connection failed: %s", connect_status.message.c_str());
                        connected_ = false;
                        connecting_ = false;
                        if (status_callback_) {
                            status_callback_("error", "Connection failed: " + connect_status.message);
                        }
                    } else {
                        LOGI("OpenVPN3 Core connect() completed successfully");

                        // Check connection info to confirm
                        auto conn_info = connection_info();
                        if (conn_info.defined && !conn_info.vpnIp4.empty()) {
                            LOGI("Connection established successfully - VPN IP: %s", conn_info.vpnIp4.c_str());
                            connected_ = true;
                            connecting_ = false;
                            if (status_callback_) {
                                status_callback_("connected", "VPN connection established - IP: " + conn_info.vpnIp4);
                            }
                        } else {
                            LOGI("Connection completed but no VPN IP assigned");
                            connected_ = false;
                            connecting_ = false;
                            if (status_callback_) {
                                status_callback_("disconnected", "Connection ended - no VPN IP");
                            }
                        }
                    }

                    connected_ = false;
                    connecting_ = false;

                } catch (const std::exception& e) {
                    LOGE("OpenVPN3 Core connection exception: %s", e.what());
                    if (status_callback_) {
                        status_callback_("error", std::string("Connection exception: ") + e.what());
                    }
                    connected_ = false;
                    connecting_ = false;
                }
            });

            return true;

        } catch (const std::exception& e) {
            LOGE("Failed to start OpenVPN3 connection: %s", e.what());
            if (status_callback_) {
                status_callback_("error", std::string("Connection startup failed: ") + e.what());
            }
            connecting_ = false;
            return false;
        }
    }

    void disconnectFromServer() {
        try {
            LOGI("Disconnecting OpenVPN3 Core client");
            should_stop_ = true;
            
            if (connecting_ || connected_) {
                stop();
                connected_ = false;
                connecting_ = false;
                
                if (status_callback_) {
                    status_callback_("disconnected", "Disconnected");
                }
            }
            
            if (connect_thread_.joinable()) {
                connect_thread_.join();
            }
            
            LOGI("OpenVPN3 Core client disconnected");
        } catch (const std::exception& e) {
            LOGE("Error during disconnect: %s", e.what());
        }
    }

    // OpenVPN3 Core callback methods
    void event(const openvpn::ClientAPI::Event& ev) override {
        LOGI("OpenVPN3 Event: %s - %s", ev.name.c_str(), ev.info.c_str());
        
        if (ev.name == "CONNECTED") {
            LOGI("✅ OpenVPN3 Core reports connection established");
            connected_ = true;
            connecting_ = false;
            if (status_callback_) {
                status_callback_("connected", "Connected to VPN server");
            }
        } else if (ev.name == "DISCONNECTED") {
            LOGI("📱 OpenVPN3 Core reports disconnection");
            connected_ = false;
            connecting_ = false;
            if (status_callback_) {
                status_callback_("disconnected", "Disconnected from VPN server");
            }
        } else if (ev.name == "RECONNECTING") {
            LOGI("🔄 OpenVPN3 Core is reconnecting");
            if (status_callback_) {
                status_callback_("connecting", "Reconnecting...");
            }
        } else if (ev.name == "RESOLVE") {
            LOGI("🔍 OpenVPN3 Core resolving server: %s", ev.info.c_str());
            if (status_callback_) {
                status_callback_("connecting", "Resolving server: " + ev.info);
            }
        } else if (ev.name == "TCP_CONNECT") {
            LOGI("🔗 OpenVPN3 Core TCP connecting to: %s", ev.info.c_str());
            if (status_callback_) {
                status_callback_("connecting", "TCP connecting to: " + ev.info);
            }
        } else if (ev.name == "TLS_HANDSHAKE") {
            LOGI("🤝 OpenVPN3 Core TLS handshake in progress");
            if (status_callback_) {
                status_callback_("authenticating", "TLS handshake...");
            }
        } else if (ev.name == "AUTH") {
            LOGI("🔐 OpenVPN3 Core authentication in progress");
            if (status_callback_) {
                status_callback_("authenticating", "Authenticating...");
            }
        } else if (ev.name == "GET_CONFIG") {
            LOGI("⚙️ OpenVPN3 Core receiving configuration");
            if (status_callback_) {
                status_callback_("authenticating", "Receiving configuration...");
            }
        } else if (ev.name == "ASSIGN_IP") {
            LOGI("🌐 OpenVPN3 Core IP assignment: %s", ev.info.c_str());
            if (status_callback_) {
                status_callback_("connecting", "IP assignment: " + ev.info);
            }
        } else if (ev.name.find("ERROR") != std::string::npos || ev.fatal) {
            LOGE("❌ OpenVPN3 Core error: %s - %s", ev.name.c_str(), ev.info.c_str());
            connected_ = false;
            connecting_ = false;
            if (status_callback_) {
                status_callback_("error", ev.name + ": " + ev.info);
            }
        }
    }

    void acc_event(const openvpn::ClientAPI::AppCustomControlMessageEvent& ev) override {
        LOGI("OpenVPN3 Custom Control Message: %s", ev.message.c_str());
    }

    void log(const openvpn::ClientAPI::LogInfo& log_info) override {
        // Filter out verbose logs to reduce noise
        if (log_info.text.find("MANAGEMENT:") == std::string::npos &&
            log_info.text.find("PUSH:") == std::string::npos) {
            LOGI("OpenVPN3 Log: %s", log_info.text.c_str());
        }
    }

    void external_pki_cert_request(openvpn::ClientAPI::ExternalPKICertRequest& req) override {
        LOGI("External PKI certificate request");
        req.error = true;
        req.errorText = "External PKI not supported";
    }

    void external_pki_sign_request(openvpn::ClientAPI::ExternalPKISignRequest& req) override {
        LOGI("External PKI sign request");
        req.error = true;
        req.errorText = "External PKI not supported";
    }

    bool pause_on_connection_timeout() override {
        LOGI("Connection timeout - pausing");
        return false; // Don't pause, let it fail
    }

    // TUN builder methods - generic implementations
    bool tun_builder_new() override {
        LOGI("TUN builder: Starting new session");
        return true;
    }

    bool tun_builder_set_layer(int layer) override {
        LOGI("TUN builder: Layer %d", layer);
        return true;
    }

    bool tun_builder_set_remote_address(const std::string& address, bool ipv6) override {
        LOGI("TUN builder: Remote address: %s", address.c_str());
        return true;
    }

    bool tun_builder_add_address(const std::string& address, int prefix_length, const std::string& gateway, bool ipv6, bool net30) override {
        LOGI("TUN builder: VPN IP: %s/%d (gateway: %s)", address.c_str(), prefix_length, gateway.c_str());
        last_vpn_ip_ = address; // Store the VPN IP for stats
        return true;
    }

    bool tun_builder_add_route(const std::string& address, int prefix_length, int metric, bool ipv6) override {
        LOGI("TUN builder: Route: %s/%d (metric: %d)", address.c_str(), prefix_length, metric);
        return true;
    }

    bool tun_builder_set_dns_options(const openvpn::DnsOptions& dns) override {
        LOGI("TUN builder: DNS options configured");
        return true;
    }

    bool tun_builder_set_mtu(int mtu) override {
        LOGI("TUN builder: MTU: %d", mtu);
        return true;
    }

    int tun_builder_establish() override {
        LOGI("TUN builder: Establishing interface...");
        // Return a dummy file descriptor - platform-specific implementations
        // should override this method to create actual interfaces
        return 1; // Dummy fd for generic implementation
    }

    bool tun_builder_persist() override {
        LOGI("TUN builder: Interface persistence requested");
        return false; // Generic implementation doesn't persist
    }

    void tun_builder_teardown(bool disconnect) override {
        LOGI("TUN builder: Tearing down interface (disconnect: %s)", disconnect ? "yes" : "no");
    }

public:
    bool isConnected() const {
        return connected_.load();
    }

    ConnectionStats getStats() const {
        std::lock_guard<std::mutex> lock(stats_mutex_);
        ConnectionStats stats = {};
        
        if (connected_ || connecting_) {
            try {
                // Get connection info from OpenVPN3 Core
                auto conn_info = connection_info();
                
                if (conn_info.defined) {
                    // Use OpenVPN3 Core connection info
                    if (!conn_info.vpnIp4.empty()) {
                        stats.localIp = conn_info.vpnIp4;
                        LOGI("Stats: Using OpenVPN3 Core VPN IP: %s", stats.localIp.c_str());
                    } else if (!last_vpn_ip_.empty()) {
                        stats.localIp = last_vpn_ip_;
                        LOGI("Stats: Using saved VPN IP: %s", stats.localIp.c_str());
                    }
                    
                    stats.serverIp = conn_info.serverHost;
                    stats.bytesIn = conn_info.bytesIn;
                    stats.bytesOut = conn_info.bytesOut;
                } else {
                    LOGI("Stats: No connection info available");
                }
                
                // Calculate duration
                if (connected_) {
                    auto now = std::chrono::steady_clock::now();
                    auto duration = std::chrono::duration_cast<std::chrono::seconds>(now - connect_time_);
                    stats.duration = duration.count();
                }
                
            } catch (const std::exception& e) {
                LOGE("Error getting connection stats: %s", e.what());
            }
        }
        
        return stats;
    }

private:
    OpenVPN3Wrapper::StatusCallback status_callback_;
    std::atomic<bool> connected_;
    std::atomic<bool> connecting_;
    std::atomic<bool> should_stop_;
    std::thread connect_thread_;
    std::chrono::steady_clock::time_point connect_time_;
    std::string username_;
    std::string password_;
    std::string last_vpn_ip_;  // Store the last seen VPN IP from ifconfig option
    mutable std::mutex stats_mutex_;
};

// OpenVPN3Wrapper implementation
OpenVPN3Wrapper::OpenVPN3Wrapper(StatusCallback callback) 
    : impl_(std::make_unique<OpenVPN3ClientImpl>(std::move(callback))) {
    LOGI("OpenVPN3 wrapper created successfully");
}

OpenVPN3Wrapper::~OpenVPN3Wrapper() {
    if (impl_) {
        impl_->disconnectFromServer();
    }
}

bool OpenVPN3Wrapper::connect(const std::string& config, const std::string& username, const std::string& password) {
    if (!impl_) {
        LOGE("OpenVPN3 wrapper not initialized");
        return false;
    }
    return impl_->connectToServer(config, username, password);
}

void OpenVPN3Wrapper::disconnect() {
    if (impl_) {
        impl_->disconnectFromServer();
    }
}

bool OpenVPN3Wrapper::isConnected() const {
    return impl_ ? impl_->isConnected() : false;
}

ConnectionStats OpenVPN3Wrapper::getStats() const {
    return impl_ ? impl_->getStats() : ConnectionStats{};
}

bool OpenVPN3Wrapper::isAvailable() {
    return true; // OpenVPN3 Core is always available in generic implementation
}
