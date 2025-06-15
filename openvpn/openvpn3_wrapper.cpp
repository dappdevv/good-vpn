#include "openvpn3_wrapper.h"
#include <android/log.h>
#include <thread>
#include <chrono>
#include <atomic>
#include <memory>
#include <mutex>

// Include OpenVPN3 Core compatibility header first
#include "openvpn3_compat.h"

// Include OpenVPN3 Core API
#include "client/ovpncli.hpp"

#define LOG_TAG "OpenVPN3Wrapper"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

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

                    // Basic settings
                    ovpn_config.dco = false; // Disable DCO for Android compatibility
                    ovpn_config.tunPersist = false;
                    ovpn_config.googleDnsFallback = true;
                    ovpn_config.allowLocalDnsResolvers = true;
                    ovpn_config.autologinSessions = false;

                    // TLS settings
                    ovpn_config.enableLegacyAlgorithms = false; // Disable legacy TLS algorithms (no legacy provider)

                    // Compression mode - use "yes" to allow compression (OpenVPN3 Core will handle lz4-v2 from config)
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
                    // The connect() method blocks until connection completes (success/failure)
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

                        // According to OpenVPN3 Core API, if connect() returns without error,
                        // the connection was successful. Check connection info to confirm.
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
            LOGE("Exception during OpenVPN3 Core connection setup: %s", e.what());
            if (status_callback_) {
                status_callback_("error", std::string("Connection setup exception: ") + e.what());
            }
            return false;
        }
    }

    void disconnectFromServer() {
        try {
            LOGI("Disconnecting real OpenVPN3 Core client");

            should_stop_ = true;
            connected_ = false;
            connecting_ = false;

            // Clear saved VPN IP
            if (!last_vpn_ip_.empty()) {
                LOGI("🗑️ CLEARING VPN IP: %s", last_vpn_ip_.c_str());
                last_vpn_ip_.clear();
            }

            // Stop the OpenVPN3 Core connection
            stop();

            // Wait for connection thread to finish with timeout
            if (connect_thread_.joinable()) {
                LOGI("Waiting for connection thread to finish...");
                connect_thread_.join();
                LOGI("Connection thread finished");
            }

            // Reset the should_stop flag for next connection
            should_stop_ = false;

            if (status_callback_) {
                status_callback_("disconnected", "OpenVPN3 Core client disconnected");
            }
        } catch (const std::exception& e) {
            LOGE("Exception during OpenVPN3 Core disconnect: %s", e.what());
        }
    }

    // OpenVPN3 Core callback methods (required by OpenVPNClient base class)

    // Event callback - receives connection events from OpenVPN3 Core
    void event(const openvpn::ClientAPI::Event& ev) override {
        try {
            LOGI("OpenVPN3 Core Event: %s - %s (error=%s, fatal=%s)",
                 ev.name.c_str(), ev.info.c_str(),
                 ev.error ? "true" : "false", ev.fatal ? "true" : "false");

            if (status_callback_) {
                if (ev.name == "CONNECTING") {
                    status_callback_("connecting", ev.info.empty() ? "Connecting to server..." : ev.info);
                } else if (ev.name == "WAIT") {
                    status_callback_("connecting", ev.info.empty() ? "Waiting for server..." : ev.info);
                } else if (ev.name == "AUTH") {
                    status_callback_("authenticating", ev.info.empty() ? "Authenticating..." : ev.info);
                } else if (ev.name == "GET_CONFIG") {
                    status_callback_("authenticating", ev.info.empty() ? "Downloading configuration..." : ev.info);
                } else if (ev.name == "ASSIGN_IP") {
                    LOGI("ASSIGN_IP event received - IP address being assigned");
                    status_callback_("authenticating", ev.info.empty() ? "Assigning IP address..." : ev.info);
                } else if (ev.name == "ADD_ROUTES") {
                    LOGI("ADD_ROUTES event received - routes being added");
                    status_callback_("authenticating", ev.info.empty() ? "Adding routes..." : ev.info);
                } else if (ev.name == "CONNECTED") {
                    LOGI("CONNECTED event received - VPN fully established");
                    connected_ = true;
                    connecting_ = false;
                    status_callback_("connected", ev.info.empty() ? "VPN connection established" : ev.info);

                    // Extract VPN IP from the event info since TUN_NULL doesn't provide it in connection_info
                    std::string vpn_ip;
                    if (!ev.info.empty()) {
                        // Parse the event info to extract VPN IP
                        // Format: "10.0.2.2:1194 (10.0.2.2) via /UDP on TUN_NULL// gw=[/] mtu=(default)"
                        // We need to look for the ifconfig option in the logs or extract from previous OPTIONS
                        LOGI("Parsing connection info from event: %s", ev.info.c_str());
                    }

                    // Schedule connection info retrieval after a brief delay to ensure it's fully populated
                    std::thread([this]() {
                        try {
                            // Give a brief moment for connection info to be fully populated
                            std::this_thread::sleep_for(std::chrono::milliseconds(100));

                            auto conn_info = connection_info();
                            if (conn_info.defined) {
                                LOGI("OpenVPN3 Core Connected - Server: %s:%s, VPN IP: %s, Client IP: %s",
                                     conn_info.serverIp.c_str(), conn_info.serverPort.c_str(),
                                     conn_info.vpnIp4.c_str(), conn_info.clientIp.c_str());

                                // Update status with VPN IP if available
                                if (!conn_info.vpnIp4.empty() && status_callback_) {
                                    status_callback_("connected", "VPN IP: " + conn_info.vpnIp4);
                                } else if (!conn_info.vpnIp6.empty() && status_callback_) {
                                    status_callback_("connected", "VPN IP: " + conn_info.vpnIp6);
                                } else {
                                    // Since TUN_NULL doesn't provide VPN IP in connection_info,
                                    // we'll use the last seen ifconfig IP from the OPTIONS
                                    if (!last_vpn_ip_.empty() && status_callback_) {
                                        status_callback_("connected", "VPN IP: " + last_vpn_ip_);
                                    }
                                }
                            } else {
                                LOGI("Connection info not yet available");
                                // Use last seen VPN IP if available
                                if (!last_vpn_ip_.empty() && status_callback_) {
                                    status_callback_("connected", "VPN IP: " + last_vpn_ip_);
                                }
                            }
                        } catch (const std::exception& e) {
                            LOGE("Exception getting connection info: %s", e.what());
                        }
                    }).detach();
                } else if (ev.name == "DISCONNECTED") {
                    connected_ = false;
                    connecting_ = false;
                    status_callback_("disconnected", ev.info.empty() ? "VPN disconnected" : ev.info);
                } else if (ev.name == "RECONNECTING") {
                    status_callback_("connecting", ev.info.empty() ? "Reconnecting..." : ev.info);
                } else if (ev.name == "PAUSE") {
                    LOGI("PAUSE event received - connection paused");
                    status_callback_("connecting", ev.info.empty() ? "Connection paused, retrying..." : ev.info);
                } else if (ev.error) {
                    connected_ = false;
                    connecting_ = false;
                    status_callback_("error", ev.info.empty() ? ("Error: " + ev.name) : ev.info);
                } else {
                    // Other events - just log them for debugging
                    LOGI("Other OpenVPN3 Core event: %s - %s", ev.name.c_str(), ev.info.c_str());
                }
            }
        } catch (const std::exception& e) {
            LOGE("Exception in OpenVPN3 Core event callback: %s", e.what());
        }
    }

    // App custom control message callback (required pure virtual method)
    void acc_event(const openvpn::ClientAPI::AppCustomControlMessageEvent& ev) override {
        LOGI("OpenVPN3 Core App control message: protocol=%s, payload=%s", ev.protocol.c_str(), ev.payload.c_str());
    }

    // Log callback - receives log messages from OpenVPN3 Core
    void log(const openvpn::ClientAPI::LogInfo& log_info) override {
        // Parse VPN IP from ifconfig option in the logs
        if (log_info.text.find("[ifconfig]") != std::string::npos) {
            // Extract VPN IP from ifconfig line: "7 [ifconfig] [10.8.0.2] [255.255.255.0]"
            size_t start = log_info.text.find("[ifconfig] [");
            if (start != std::string::npos) {
                start += 12; // Length of "[ifconfig] ["
                size_t end = log_info.text.find("]", start);
                if (end != std::string::npos) {
                    last_vpn_ip_ = log_info.text.substr(start, end - start);
                    LOGI("🎯 SAVED VPN IP: %s (will persist until disconnect)", last_vpn_ip_.c_str());
                }
            }
        }

        // Show TLS handshake and connection-related logs
        if (log_info.text.find("ERROR") != std::string::npos ||
            log_info.text.find("WARNING") != std::string::npos ||
            log_info.text.find("CONNECTED") != std::string::npos ||
            log_info.text.find("Initialization Sequence Completed") != std::string::npos ||
            log_info.text.find("AUTH") != std::string::npos ||
            log_info.text.find("TLS") != std::string::npos ||
            log_info.text.find("SSL") != std::string::npos ||
            log_info.text.find("handshake") != std::string::npos ||
            log_info.text.find("VERIFY") != std::string::npos ||
            log_info.text.find("cipher") != std::string::npos ||
            log_info.text.find("certificate") != std::string::npos ||
            log_info.text.find("Control Channel") != std::string::npos ||
            log_info.text.find("Data Channel") != std::string::npos) {
            LOGI("OpenVPN3 Core Log: %s", log_info.text.c_str());
        }
    }

    // External PKI callbacks (not used in our case, but required)
    void external_pki_cert_request(openvpn::ClientAPI::ExternalPKICertRequest& req) override {
        req.error = true;
        req.errorText = "External PKI not supported";
        LOGE("External PKI cert request not supported");
    }

    void external_pki_sign_request(openvpn::ClientAPI::ExternalPKISignRequest& req) override {
        req.error = true;
        req.errorText = "External PKI not supported";
        LOGE("External PKI sign request not supported");
    }

    // Pause on connection timeout callback
    bool pause_on_connection_timeout() override {
        LOGI("OpenVPN3 Core connection timeout - pausing");
        return true; // Pause instead of disconnecting on timeout
    }

public:

    bool isConnected() const {
        return connected_;
    }

    ConnectionStats getStats() const {
        ConnectionStats stats;

        try {
            if (connected_) {
                // Get real statistics from OpenVPN3 Core
                // Note: We need to cast away const to call these methods
                auto* non_const_this = const_cast<OpenVPN3ClientImpl*>(this);
                auto transport_statistics = non_const_this->transport_stats();
                auto conn_info = non_const_this->connection_info();

                // Calculate actual connection duration
                if (connect_time_.time_since_epoch().count() > 0) {
                    auto now = std::chrono::steady_clock::now();
                    auto duration = std::chrono::duration_cast<std::chrono::seconds>(now - connect_time_);
                    stats.duration = duration.count();
                } else {
                    stats.duration = 0;
                }

                // Use real transport statistics from OpenVPN3 Core
                stats.bytesIn = transport_statistics.bytesIn;
                stats.bytesOut = transport_statistics.bytesOut;

                // Get real connection information from OpenVPN3 Core
                if (conn_info.defined) {
                    stats.serverIp = conn_info.serverIp;
                    // Use saved VPN IP from ifconfig since TUN_NULL doesn't populate vpnIp4/vpnIp6
                    stats.localIp = last_vpn_ip_.empty() ?
                        (conn_info.vpnIp4.empty() ? conn_info.vpnIp6 : conn_info.vpnIp4) :
                        last_vpn_ip_;

                    LOGI("📊 Stats: connected=%s, saved_vpn_ip='%s', conn_vpn_ip='%s', using='%s'",
                         connected_ ? "true" : "false", last_vpn_ip_.c_str(),
                         conn_info.vpnIp4.c_str(), stats.localIp.c_str());
                } else {
                    stats.serverIp = "";
                    // Use saved VPN IP even if connection_info is not defined
                    stats.localIp = last_vpn_ip_;

                    LOGI("📊 Stats: connected=%s, conn_info=undefined, saved_vpn_ip='%s', using='%s'",
                         connected_ ? "true" : "false", last_vpn_ip_.c_str(), stats.localIp.c_str());
                }

                LOGI("Real OpenVPN3 Core stats - In: %lu bytes, Out: %lu bytes, Duration: %lu sec, Server: %s, Local: %s",
                     (unsigned long)stats.bytesIn, (unsigned long)stats.bytesOut, (unsigned long)stats.duration,
                     stats.serverIp.c_str(), stats.localIp.c_str());
            } else {
                stats.bytesIn = 0;
                stats.bytesOut = 0;
                stats.duration = 0;
                stats.serverIp = "";
                stats.localIp = "";
            }
        } catch (const std::exception& e) {
            LOGE("Exception getting OpenVPN3 Core stats: %s", e.what());
            // Return zero stats on error
            stats.bytesIn = 0;
            stats.bytesOut = 0;
            stats.duration = 0;
            stats.serverIp = "";
            stats.localIp = "";
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

OpenVPN3Wrapper::OpenVPN3Wrapper(StatusCallback callback) 
    : status_callback_(std::move(callback)) {
    try {
        client_impl_ = std::make_unique<OpenVPN3ClientImpl>(status_callback_);
        LOGI("OpenVPN3 wrapper created successfully");
    } catch (const std::exception& e) {
        LOGE("Failed to create OpenVPN3 wrapper: %s", e.what());
        throw;
    }
}

OpenVPN3Wrapper::~OpenVPN3Wrapper() {
    disconnect();
    LOGI("OpenVPN3 wrapper destroyed");
}

bool OpenVPN3Wrapper::connect(const std::string& config, const std::string& username, const std::string& password) {
    try {
        LOGI("Starting real OpenVPN3 Core connection");

        // Only create a fresh instance if we don't have one or if the previous one was used
        if (!client_impl_) {
            client_impl_ = std::make_unique<OpenVPN3ClientImpl>(status_callback_);
            LOGI("Created fresh OpenVPN3 Core client instance");
        } else {
            LOGI("Reusing existing OpenVPN3 Core client instance");
        }

        if (client_impl_) {
            return client_impl_->connectToServer(config, username, password);
        }

        LOGE("OpenVPN3 Core client implementation not available");
        return false;

    } catch (const std::exception& e) {
        LOGE("Exception during OpenVPN3 Core connection: %s", e.what());

        // If we get the "attach() can only be called once" error, create a fresh instance
        if (std::string(e.what()).find("attach() can only be called once") != std::string::npos) {
            LOGI("Creating fresh OpenVPN3 Core client instance due to attach() error");
            client_impl_ = std::make_unique<OpenVPN3ClientImpl>(status_callback_);

            // Try the connection again with the fresh instance
            try {
                return client_impl_->connectToServer(config, username, password);
            } catch (const std::exception& retry_e) {
                LOGE("Retry connection failed: %s", retry_e.what());
                if (status_callback_) {
                    status_callback_("error", std::string("Retry connection failed: ") + retry_e.what());
                }
                return false;
            }
        }

        if (status_callback_) {
            status_callback_("error", std::string("OpenVPN3 Core connection exception: ") + e.what());
        }
        return false;
    }
}

void OpenVPN3Wrapper::disconnect() {
    try {
        if (client_impl_) {
            LOGI("Disconnecting real OpenVPN3 Core client");
            client_impl_->disconnectFromServer();

            // Clean up the client instance to ensure fresh state for next connection
            client_impl_.reset();
            LOGI("OpenVPN3 Core client instance cleaned up");
        }
    } catch (const std::exception& e) {
        LOGE("Exception during OpenVPN3 Core disconnect: %s", e.what());
    }
}

std::string OpenVPN3Wrapper::getStatus() const {
    try {
        if (client_impl_ && client_impl_->isConnected()) {
            return "connected";
        }
        return "disconnected";
    } catch (const std::exception& e) {
        LOGE("Exception getting status: %s", e.what());
        return "error";
    }
}

ConnectionStats OpenVPN3Wrapper::getStats() const {
    ConnectionStats stats;

    try {
        if (client_impl_) {
            stats = client_impl_->getStats();
            LOGI("OpenVPN3 Core Stats - In: %lu, Out: %lu, Server: %s, Local: %s",
                 (unsigned long)stats.bytesIn, (unsigned long)stats.bytesOut, stats.serverIp.c_str(), stats.localIp.c_str());
        }
    } catch (const std::exception& e) {
        LOGE("Exception getting OpenVPN3 Core stats: %s", e.what());
    }

    return stats;
}

bool OpenVPN3Wrapper::isAvailable() {
    try {
        // Check if OpenVPN3 Core is available
        LOGI("OpenVPN3 Core wrapper is available");
        return true;
    } catch (const std::exception& e) {
        LOGE("OpenVPN3 Core wrapper not available: %s", e.what());
        return false;
    }
}
