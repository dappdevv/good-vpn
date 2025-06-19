#pragma once

#include <string>
#include <vector>
#include <memory>

// Forward declaration for OpenVPN3 Core TunBuilderBase
namespace openvpn {
    class TunBuilderBase;
}

/**
 * macOS-specific TUN builder implementation
 * Creates a real utun interface for VPN traffic routing
 */
class MacOSTunBuilder {
public:
    MacOSTunBuilder();
    ~MacOSTunBuilder();
    
    // Create OpenVPN3 Core TunBuilderBase implementation
    std::unique_ptr<openvpn::TunBuilderBase> createTunBuilder();
    
    // Check if TUN builder is available on this system
    static bool isAvailable();
    
private:
    class Impl;
    std::unique_ptr<Impl> impl_;
};
