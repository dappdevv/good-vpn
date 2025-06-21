#pragma once

#include <string>
#include <memory>

namespace openvpn {
namespace ClientAPI {

// Configuration structure
struct Config {
    std::string content;
    std::string guiVersion;
    std::string compressionMode;
    std::string username;
    std::string password;
    bool allowUnusedAddrFamilies = true;
    bool tunPersist = false;
    bool googleDnsFallback = true;
};

// Configuration evaluation result
struct EvalConfig {
    bool error = false;
    std::string message;
};

// Connection status
struct Status {
    bool error = false;
    std::string message;
};

// Transport statistics
struct TransportStats {
    bool error = false;
    std::string message;
    uint64_t bytesIn = 0;
    uint64_t bytesOut = 0;
};

// Main OpenVPN client class
class OpenVPNClient {
public:
    OpenVPNClient() = default;
    virtual ~OpenVPNClient() = default;
    
    // Evaluate configuration
    virtual EvalConfig eval_config(const Config& config) {
        EvalConfig result;
        if (config.content.empty()) {
            result.error = true;
            result.message = "Empty configuration";
        } else {
            result.error = false;
            result.message = "Configuration valid";
        }
        return result;
    }
    
    // Connect to VPN
    virtual Status connect() {
        Status result;
        result.error = false;
        result.message = "Connected successfully";
        return result;
    }
    
    // Stop VPN connection
    virtual void stop() {
        // Implementation would stop the connection
    }
    
    // Get transport statistics
    virtual TransportStats transport_stats() {
        TransportStats stats;
        stats.error = false;
        stats.bytesIn = 1024;  // Mock data
        stats.bytesOut = 512;  // Mock data
        return stats;
    }
};

} // namespace ClientAPI
} // namespace openvpn 