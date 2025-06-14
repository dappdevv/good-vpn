#pragma once

#include <string>
#include <functional>
#include <memory>
#include <windows.h>

struct ConnectionStatsWin {
    uint64_t bytes_in = 0;
    uint64_t bytes_out = 0;
    uint32_t duration = 0;
    std::string server_ip;
    std::string local_ip;
};

class OpenVPN3ClientImplWin; // Forward declaration

class OpenVPN3WrapperWin {
public:
    using StatusCallback = std::function<void(const std::string&, const std::string&)>;
    
    explicit OpenVPN3WrapperWin(StatusCallback callback);
    ~OpenVPN3WrapperWin();
    
    // Core functionality
    bool Connect(const std::string& config, const std::string& username, const std::string& password);
    void Disconnect();
    std::string GetStatus() const;
    ConnectionStatsWin GetStats() const;
    
    // Utility
    static bool IsAvailable();
    
private:
    StatusCallback status_callback_;
    std::unique_ptr<OpenVPN3ClientImplWin> client_impl_;
};
