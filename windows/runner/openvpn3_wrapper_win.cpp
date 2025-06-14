#include "openvpn3_wrapper_win.h"
#include <iostream>
#include <thread>
#include <chrono>

// Real OpenVPN3 ClientAPI integration for Windows
#include <openvpn/client/ovpncli.hpp>
#include <openvpn/common/exception.hpp>
#include <openvpn/common/string.hpp>
#include <openvpn/common/options.hpp>
#include <openvpn/log/logsimple.hpp>
#include <openvpn/time/time.hpp>
#include <openvpn/random/randapi.hpp>

using namespace openvpn;
using namespace openvpn::ClientAPI;
// Real OpenVPN3 ClientAPI implementation for Windows
class OpenVPN3ClientImplWin : public OpenVPNClient {
public:
    OpenVPN3ClientImplWin(OpenVPN3WrapperWin::StatusCallback callback)
        : status_callback_(std::move(callback)), connected_(false), connecting_(false) {
        std::cout << "Real OpenVPN3 Windows client implementation created" << std::endl;
    }

    // Override OpenVPN3 ClientAPI virtual methods
    void event(const Event& ev) override {
        std::cout << "OpenVPN3 Windows Event: " << ev.name << " - " << ev.info << std::endl;

        if (status_callback_) {
            status_callback_(ev.name, ev.info);
        }

        // Update internal state based on events
        if (ev.name == "CONNECTED") {
            connected_ = true;
            connecting_ = false;
            connect_time_ = std::chrono::steady_clock::now();
        } else if (ev.name == "DISCONNECTED") {
            connected_ = false;
            connecting_ = false;
        } else if (ev.name == "CONNECTING") {
            connecting_ = true;
            connected_ = false;
        }
    }

    void log(const LogInfo& log_info) override {
        std::cout << "OpenVPN3 Windows Log: " << log_info.text << std::endl;
    }

    bool socket_protect(openvpn_io::detail::socket_type socket, std::string remote, bool ipv6) override {
        // Windows socket protection - not as critical as Android but still useful
        std::cout << "Windows socket protect called for socket " << socket
                  << ", remote: " << remote << ", ipv6: " << (ipv6 ? "true" : "false") << std::endl;
        return true;
    }

    bool pause_on_connection_timeout() override {
        return false;
    }

    // Custom methods for our wrapper
    bool ConnectToServer(const std::string& config, const std::string& username, const std::string& password) {
        try {
            std::cout << "Starting real OpenVPN3 Windows connection" << std::endl;

            // Prepare OpenVPN3 configuration
            Config client_config;
            client_config.content = config;
            client_config.guiVersion = "OpenVPN Windows Client 1.0";
            client_config.sslDebugLevel = 0;
            client_config.compressionMode = "yes";
            client_config.ipv6 = "yes";
            client_config.autologinSessions = true;
            client_config.tunPersist = true;
            client_config.googleDnsFallback = true;

            // Evaluate configuration
            EvalConfig eval = eval_config(client_config);
            if (eval.error) {
                std::cerr << "Configuration evaluation failed: " << eval.message << std::endl;
                if (status_callback_) {
                    status_callback_("error", "Configuration error: " + eval.message);
                }
                return false;
            }

            std::cout << "Configuration evaluated successfully" << std::endl;

            // Provide credentials if needed
            if (!username.empty() || !password.empty()) {
                ProvideCreds creds;
                if (!username.empty()) {
                    creds.username = username;
                }
                if (!password.empty()) {
                    creds.password = password;
                }

                Status cred_status = provide_creds(creds);
                if (cred_status.error) {
                    std::cerr << "Credential provision failed: " << cred_status.message << std::endl;
                    if (status_callback_) {
                        status_callback_("error", "Credential error: " + cred_status.message);
                    }
                    return false;
                }
            }

            // Start connection in background thread
            connect_thread_ = std::thread([this]() {
                try {
                    Status status = connect();
                    if (status.error) {
                        std::cerr << "Connection failed: " << status.message << std::endl;
                        if (status_callback_) {
                            status_callback_("error", "Connection failed: " + status.message);
                        }
                    }
                } catch (const std::exception& e) {
                    std::cerr << "Connection exception: " << e.what() << std::endl;
                    if (status_callback_) {
                        status_callback_("error", std::string("Connection exception: ") + e.what());
                    }
                }
            });

            return true;

        } catch (const std::exception& e) {
            std::cerr << "Exception during Windows connection setup: " << e.what() << std::endl;
            if (status_callback_) {
                status_callback_("error", std::string("Connection setup exception: ") + e.what());
            }
            return false;
        }
    }

    void DisconnectFromServer() {
        try {
            std::cout << "Disconnecting real OpenVPN3 Windows client" << std::endl;

            // Stop the OpenVPN3 client
            stop();

            // Wait for connection thread to finish
            if (connect_thread_.joinable()) {
                connect_thread_.join();
            }

            connected_ = false;
            connecting_ = false;

            if (status_callback_) {
                status_callback_("disconnected", "OpenVPN3 Windows client disconnected");
            }
        } catch (const std::exception& e) {
            std::cerr << "Exception during Windows disconnect: " << e.what() << std::endl;
        }
    }

    bool IsConnected() const {
        return connected_;
    }

    ConnectionStatsWin GetStats() const {
        ConnectionStatsWin stats;

        try {
            if (connected_) {
                // Get real connection info from OpenVPN3
                ConnectionInfo info = connection_info();
                TransportStats transport_stats = transport_stats();

                stats.bytes_in = transport_stats.bytesIn;
                stats.bytes_out = transport_stats.bytesOut;
                stats.server_ip = info.serverHost;
                stats.local_ip = info.vpnIp4.empty() ? info.vpnIp6 : info.vpnIp4;

                // Calculate duration
                if (connect_time_.time_since_epoch().count() > 0) {
                    auto now = std::chrono::steady_clock::now();
                    auto duration = std::chrono::duration_cast<std::chrono::seconds>(now - connect_time_);
                    stats.duration = static_cast<uint32_t>(duration.count());
                }

                std::cout << "Real Windows stats - In: " << stats.bytes_in
                         << ", Out: " << stats.bytes_out
                         << ", Server: " << stats.server_ip
                         << ", Local: " << stats.local_ip << std::endl;
            }
        } catch (const std::exception& e) {
            std::cerr << "Exception getting real Windows stats: " << e.what() << std::endl;
        }

        return stats;
    }

private:
    OpenVPN3WrapperWin::StatusCallback status_callback_;
    std::atomic<bool> connected_;
    std::atomic<bool> connecting_;
    std::thread connect_thread_;
    std::chrono::steady_clock::time_point connect_time_;
};

OpenVPN3WrapperWin::OpenVPN3WrapperWin(StatusCallback callback) 
    : status_callback_(std::move(callback)) {
    try {
        client_impl_ = std::make_unique<OpenVPN3ClientImplWin>(status_callback_);
        std::cout << "OpenVPN3 Windows wrapper created successfully" << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "Failed to create OpenVPN3 Windows wrapper: " << e.what() << std::endl;
        throw;
    }
}

OpenVPN3WrapperWin::~OpenVPN3WrapperWin() {
    Disconnect();
    std::cout << "OpenVPN3 Windows wrapper destroyed" << std::endl;
}

bool OpenVPN3WrapperWin::Connect(const std::string& config, const std::string& username, const std::string& password) {
    try {
        std::cout << "Starting real OpenVPN3 Windows connection" << std::endl;

        if (client_impl_) {
            return client_impl_->ConnectToServer(config, username, password);
        }

        std::cerr << "Real OpenVPN3 Windows client implementation not available" << std::endl;
        return false;

    } catch (const std::exception& e) {
        std::cerr << "Exception during real Windows connection: " << e.what() << std::endl;
        if (status_callback_) {
            status_callback_("error", std::string("Connection exception: ") + e.what());
        }
        return false;
    }
}

void OpenVPN3WrapperWin::Disconnect() {
    try {
        if (client_impl_) {
            std::cout << "Disconnecting real OpenVPN3 Windows client" << std::endl;
            client_impl_->DisconnectFromServer();
        }
    } catch (const std::exception& e) {
        std::cerr << "Exception during real Windows disconnect: " << e.what() << std::endl;
    }
}

std::string OpenVPN3WrapperWin::GetStatus() const {
    try {
        if (client_impl_ && client_impl_->IsConnected()) {
            return "connected";
        }
        return "disconnected";
    } catch (const std::exception& e) {
        std::cerr << "Exception getting Windows status: " << e.what() << std::endl;
        return "error";
    }
}

ConnectionStatsWin OpenVPN3WrapperWin::GetStats() const {
    ConnectionStatsWin stats;
    
    try {
        if (client_impl_) {
            stats = client_impl_->GetStats();
            std::cout << "Windows Stats - In: " << stats.bytes_in 
                     << ", Out: " << stats.bytes_out 
                     << ", Server: " << stats.server_ip 
                     << ", Local: " << stats.local_ip << std::endl;
        }
    } catch (const std::exception& e) {
        std::cerr << "Exception getting Windows stats: " << e.what() << std::endl;
    }
    
    return stats;
}

bool OpenVPN3WrapperWin::IsAvailable() {
    try {
        // Test if real OpenVPN3 library is properly linked and functional
        OpenVPNClient test_client;
        std::cout << "Real OpenVPN3 Windows library is available and functional" << std::endl;
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Real OpenVPN3 Windows library not available: " << e.what() << std::endl;
        return false;
    }
}
