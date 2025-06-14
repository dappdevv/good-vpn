#pragma once

// Minimal OpenVPN3 client interface for compilation
// In production, replace with actual OpenVPN3 library

#include <string>
#include <functional>

namespace openvpn {
    class ClientAPI {
    public:
        struct Config {
            std::string content;
            std::string username;
            std::string password;
        };
        
        struct Status {
            std::string name;
            std::string message;
        };
        
        using StatusCallback = std::function<void(const Status&)>;
        
        bool connect(const Config& config, StatusCallback callback) {
            // Placeholder implementation
            return true;
        }
        
        void disconnect() {
            // Placeholder implementation
        }
    };
}
