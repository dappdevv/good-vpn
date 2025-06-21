#include <iostream>
#include <string>
#include <memory>
#include <thread>
#include <chrono>

// OpenVPN3 Core includes
#include "openvpn_client.hpp"

extern "C" {
    
struct OpenVPNClient {
    std::unique_ptr<openvpn::ClientAPI::OpenVPNClient> client;
    openvpn::ClientAPI::Config config;
    openvpn::ClientAPI::EvalConfig eval;
    openvpn::ClientAPI::Status status;
    bool connected = false;
    uint64_t bytes_in = 0;
    uint64_t bytes_out = 0;
    std::string server_ip;
    std::string local_ip;
    std::string last_status = "disconnected";
};

// Create OpenVPN client instance
void* openvpn_client_create() {
    try {
        auto wrapper = new OpenVPNClient();
        wrapper->client.reset(new openvpn::ClientAPI::OpenVPNClient());
        std::cout << "[OpenVPN3] Client created successfully" << std::endl;
        return wrapper;
    } catch (const std::exception& e) {
        std::cerr << "[OpenVPN3] Failed to create client: " << e.what() << std::endl;
        return nullptr;
    }
}

// Destroy OpenVPN client instance
void openvpn_client_destroy(void* client_ptr) {
    if (client_ptr) {
        auto wrapper = static_cast<OpenVPNClient*>(client_ptr);
        if (wrapper->connected) {
            wrapper->client->stop();
        }
        delete wrapper;
        std::cout << "[OpenVPN3] Client destroyed" << std::endl;
    }
}

// Check if OpenVPN library is available
bool openvpn_client_is_available() {
    try {
        // Try to create a temporary client to verify library availability
        std::unique_ptr<openvpn::ClientAPI::OpenVPNClient> test_client(new openvpn::ClientAPI::OpenVPNClient());
        std::cout << "[OpenVPN3] Library is available" << std::endl;
        return true;
    } catch (const std::exception& e) {
        std::cerr << "[OpenVPN3] Library not available: " << e.what() << std::endl;
        return false;
    }
}

// Connect to VPN
bool openvpn_client_connect(void* client_ptr, const char* config_str, const char* username, const char* password) {
    if (!client_ptr || !config_str) {
        std::cerr << "[OpenVPN3] Invalid parameters for connect" << std::endl;
        return false;
    }
    
    auto wrapper = static_cast<OpenVPNClient*>(client_ptr);
    
    try {
        // Set up configuration
        wrapper->config.content = std::string(config_str);
        wrapper->config.guiVersion = "fl_openvpn_client_ios_1.0";
        wrapper->config.compressionMode = "yes";
        wrapper->config.allowUnusedAddrFamilies = true;
        wrapper->config.tunPersist = false;
        wrapper->config.googleDnsFallback = true;
        
        // Set credentials if provided
        if (username && password) {
            wrapper->config.username = std::string(username);
            wrapper->config.password = std::string(password);
            std::cout << "[OpenVPN3] Using provided credentials" << std::endl;
        }
        
        // Evaluate configuration
        wrapper->eval = wrapper->client->eval_config(wrapper->config);
        if (wrapper->eval.error) {
            std::cerr << "[OpenVPN3] Config evaluation failed: " << wrapper->eval.message << std::endl;
            return false;
        }
        
        std::cout << "[OpenVPN3] Configuration evaluated successfully" << std::endl;
        
        // Start connection in background thread
        std::thread([wrapper]() {
            try {
                wrapper->status = wrapper->client->connect();
                wrapper->connected = !wrapper->status.error;
                
                if (wrapper->connected) {
                    wrapper->last_status = "connected";
                    std::cout << "[OpenVPN3] Connection established successfully" << std::endl;
                } else {
                    wrapper->last_status = "error: " + wrapper->status.message;
                    std::cerr << "[OpenVPN3] Connection failed: " << wrapper->status.message << std::endl;
                }
            } catch (const std::exception& e) {
                wrapper->connected = false;
                wrapper->last_status = "error: " + std::string(e.what());
                std::cerr << "[OpenVPN3] Connection exception: " << e.what() << std::endl;
            }
        }).detach();
        
        // Give connection time to initialize
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        
        return true;
        
    } catch (const std::exception& e) {
        std::cerr << "[OpenVPN3] Connect failed: " << e.what() << std::endl;
        wrapper->last_status = "error: " + std::string(e.what());
        return false;
    }
}

// Disconnect from VPN
void openvpn_client_disconnect(void* client_ptr) {
    if (!client_ptr) return;
    
    auto wrapper = static_cast<OpenVPNClient*>(client_ptr);
    
    try {
        if (wrapper->connected && wrapper->client) {
            wrapper->client->stop();
            wrapper->connected = false;
            wrapper->last_status = "disconnected";
            wrapper->bytes_in = 0;
            wrapper->bytes_out = 0;
            std::cout << "[OpenVPN3] Disconnected successfully" << std::endl;
        }
    } catch (const std::exception& e) {
        std::cerr << "[OpenVPN3] Disconnect failed: " << e.what() << std::endl;
    }
}

// Check if connected
bool openvpn_client_is_connected(void* client_ptr) {
    if (!client_ptr) return false;
    
    auto wrapper = static_cast<OpenVPNClient*>(client_ptr);
    return wrapper->connected;
}

// Get connection status
const char* openvpn_client_get_status(void* client_ptr) {
    if (!client_ptr) return "error: no client";
    
    auto wrapper = static_cast<OpenVPNClient*>(client_ptr);
    
    try {
        if (wrapper->client && wrapper->connected) {
            // Update status from client
            auto transport_stats = wrapper->client->transport_stats();
            if (transport_stats.error) {
                wrapper->last_status = "error: " + transport_stats.message;
            } else {
                wrapper->last_status = "connected";
                wrapper->bytes_in = transport_stats.bytesIn;
                wrapper->bytes_out = transport_stats.bytesOut;
            }
        }
    } catch (const std::exception& e) {
        wrapper->last_status = "error: " + std::string(e.what());
    }
    
    return wrapper->last_status.c_str();
}

// Get bytes received
uint64_t openvpn_client_get_bytes_in(void* client_ptr) {
    if (!client_ptr) return 0;
    
    auto wrapper = static_cast<OpenVPNClient*>(client_ptr);
    
    try {
        if (wrapper->client && wrapper->connected) {
            auto stats = wrapper->client->transport_stats();
            if (!stats.error) {
                wrapper->bytes_in = stats.bytesIn;
            }
        }
    } catch (const std::exception& e) {
        std::cerr << "[OpenVPN3] Error getting bytes in: " << e.what() << std::endl;
    }
    
    return wrapper->bytes_in;
}

// Get bytes sent
uint64_t openvpn_client_get_bytes_out(void* client_ptr) {
    if (!client_ptr) return 0;
    
    auto wrapper = static_cast<OpenVPNClient*>(client_ptr);
    
    try {
        if (wrapper->client && wrapper->connected) {
            auto stats = wrapper->client->transport_stats();
            if (!stats.error) {
                wrapper->bytes_out = stats.bytesOut;
            }
        }
    } catch (const std::exception& e) {
        std::cerr << "[OpenVPN3] Error getting bytes out: " << e.what() << std::endl;
    }
    
    return wrapper->bytes_out;
}

// Get local VPN IP
const char* openvpn_client_get_local_ip(void* client_ptr) {
    if (!client_ptr) return nullptr;
    
    auto wrapper = static_cast<OpenVPNClient*>(client_ptr);
    
    try {
        if (wrapper->client && wrapper->connected) {
            // In a real implementation, this would get the actual tunnel IP
            // For now, return a typical VPN IP range
            wrapper->local_ip = "10.8.0.2";  // Common OpenVPN client IP
            return wrapper->local_ip.c_str();
        }
    } catch (const std::exception& e) {
        std::cerr << "[OpenVPN3] Error getting local IP: " << e.what() << std::endl;
    }
    
    return nullptr;
}

} // extern "C" 