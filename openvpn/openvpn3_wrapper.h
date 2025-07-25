#pragma once

#include <string>
#include <functional>
#include <memory>

// Forward declarations to avoid including heavy OpenVPN3 headers in header file
namespace openvpn {
    namespace ClientAPI {
        class OpenVPNClient;
    }
}

struct ConnectionStats {
    uint64_t bytesIn = 0;
    uint64_t bytesOut = 0;
    uint64_t duration = 0;
    std::string serverIp;
    std::string localIp;
};

class OpenVPN3ClientImpl; // Forward declaration

class OpenVPN3Wrapper {
public:
    using StatusCallback = std::function<void(const std::string&, const std::string&)>;
    
    explicit OpenVPN3Wrapper(StatusCallback callback);
    ~OpenVPN3Wrapper();
    
    // Core functionality
    bool connect(const std::string& config, const std::string& username, const std::string& password);
    void disconnect();
    bool isConnected() const;
    ConnectionStats getStats() const;
    std::string getStatus() const;
    std::string getLocalIP() const;
    
    // Utility
    static bool isAvailable();
    
private:
    std::unique_ptr<OpenVPN3ClientImpl> impl_;
};
