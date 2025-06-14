#pragma once

#include <string>
#include <functional>
#include <memory>
#include <thread>
#include <atomic>
#include <chrono>
#include "openvpn3_wrapper.h"

// Forward declaration
class OpenVPN3Wrapper;

class OpenVPNClient {
public:
    using StatusCallback = std::function<void(const std::string&, const std::string&)>;

    explicit OpenVPNClient(StatusCallback callback);
    ~OpenVPNClient();

    bool connect(const std::string& config, const std::string& username, const std::string& password);
    void disconnect();
    std::string getStatus() const;
    ConnectionStats getStats() const;

    // Check if real OpenVPN3 library is available
    static bool isOpenVPN3Available();

private:
    void runEventLoop();
    void runSimulationLoop();
    void updateStatus(const std::string& status, const std::string& message = "");
    bool parseConfig(const std::string& config);

    StatusCallback m_statusCallback;
    std::atomic<bool> m_connected{false};
    std::atomic<bool> m_connecting{false};
    std::atomic<bool> m_shouldStop{false};
    std::unique_ptr<std::thread> m_eventThread;

    // OpenVPN3 integration
    std::unique_ptr<OpenVPN3Wrapper> m_openvpn3Client;
    bool m_useOpenVPN3{false};

    // Connection info (for simulation fallback)
    std::string m_serverAddress;
    int m_serverPort = 1194;
    std::string m_protocol = "udp";
    std::string m_currentStatus = "disconnected";

    // Statistics (for simulation fallback)
    mutable std::atomic<uint64_t> m_bytesIn{0};
    mutable std::atomic<uint64_t> m_bytesOut{0};
    std::chrono::steady_clock::time_point m_connectTime;
};
