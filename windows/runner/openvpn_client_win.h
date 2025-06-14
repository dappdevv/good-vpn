#pragma once

#include <string>
#include <functional>
#include <memory>
#include <thread>
#include <atomic>
#include <chrono>
#include <windows.h>

struct ConnectionStatsWin {
    uint64_t bytes_in = 0;
    uint64_t bytes_out = 0;
    uint32_t duration = 0;
    std::string server_ip;
    std::string local_ip;
};

// Forward declaration for OpenVPN3 wrapper
class OpenVPN3WrapperWin;

class OpenVPNClientWin {
public:
    using StatusCallback = std::function<void(const std::string&, const std::string&)>;

    explicit OpenVPNClientWin(StatusCallback callback);
    ~OpenVPNClientWin();

    bool Connect(const std::string& config, const std::string& username, const std::string& password);
    void Disconnect();
    std::string GetStatus() const;
    ConnectionStatsWin GetStats() const;

    // Check if real OpenVPN3 library is available
    static bool IsOpenVPN3Available();

private:
    void RunEventLoop();
    void RunSimulationLoop();
    void UpdateStatus(const std::string& status, const std::string& message = "");
    bool ParseConfig(const std::string& config);
    bool CreateTunInterface();
    void CloseTunInterface();
    void ProcessPackets();

    StatusCallback status_callback_;
    std::atomic<bool> connected_{false};
    std::atomic<bool> connecting_{false};
    std::atomic<bool> should_stop_{false};
    std::unique_ptr<std::thread> event_thread_;
    std::unique_ptr<std::thread> packet_thread_;

    // OpenVPN3 integration
    std::unique_ptr<OpenVPN3WrapperWin> openvpn3_client_;
    bool use_openvpn3_{false};

    // Connection info (for simulation fallback)
    std::string server_address_;
    int server_port_ = 1194;
    std::string protocol_ = "udp";
    std::string current_status_ = "disconnected";

    // Windows-specific handles (for simulation fallback)
    HANDLE tun_handle_ = INVALID_HANDLE_VALUE;
    SOCKET udp_socket_ = INVALID_SOCKET;

    // Statistics (for simulation fallback)
    mutable std::atomic<uint64_t> bytes_in_{0};
    mutable std::atomic<uint64_t> bytes_out_{0};
    std::chrono::steady_clock::time_point connect_time_;
};
