#include "OpenVPNMacWrapper.h"
#include "../../openvpn/openvpn3_wrapper.h"
#include <memory>
#include <string>
#include <iostream>

// Internal structure to hold the C++ OpenVPN3Wrapper
struct OpenVPNClient {
    std::unique_ptr<OpenVPN3Wrapper> wrapper;
    OpenVPNStatusCallback callback;
    std::string lastStatus;
    
    OpenVPNClient(OpenVPNStatusCallback cb) : callback(cb), lastStatus("disconnected") {
        // Create the wrapper with a lambda that calls the C callback
        wrapper = std::make_unique<OpenVPN3Wrapper>([this](const std::string& state, const std::string& message) {
            this->lastStatus = state;
            if (this->callback) {
                this->callback(state.c_str(), message.c_str());
            }
        });
    }
};

extern "C" {

OpenVPNClient* openvpn_create(OpenVPNStatusCallback callback) {
    try {
        std::cout << "Creating OpenVPN client for macOS..." << std::endl;
        return new OpenVPNClient(callback);
    } catch (const std::exception& e) {
        std::cerr << "Failed to create OpenVPN client: " << e.what() << std::endl;
        return nullptr;
    }
}

void openvpn_destroy(OpenVPNClient* client) {
    if (client) {
        std::cout << "Destroying OpenVPN client..." << std::endl;
        delete client;
    }
}

bool openvpn_connect(OpenVPNClient* client, const char* config, const char* username, const char* password) {
    if (!client || !client->wrapper) {
        std::cerr << "Invalid OpenVPN client" << std::endl;
        return false;
    }
    
    try {
        std::cout << "Starting OpenVPN connection..." << std::endl;
        std::string configStr = config ? config : "";
        std::string usernameStr = username ? username : "";
        std::string passwordStr = password ? password : "";
        
        return client->wrapper->connect(configStr, usernameStr, passwordStr);
    } catch (const std::exception& e) {
        std::cerr << "OpenVPN connect failed: " << e.what() << std::endl;
        return false;
    }
}

void openvpn_disconnect(OpenVPNClient* client) {
    if (!client || !client->wrapper) {
        std::cerr << "Invalid OpenVPN client" << std::endl;
        return;
    }
    
    try {
        std::cout << "Disconnecting OpenVPN..." << std::endl;
        client->wrapper->disconnect();
    } catch (const std::exception& e) {
        std::cerr << "OpenVPN disconnect failed: " << e.what() << std::endl;
    }
}

const char* openvpn_get_status(OpenVPNClient* client) {
    if (!client || !client->wrapper) {
        return "error";
    }
    
    try {
        return client->lastStatus.c_str();
    } catch (const std::exception& e) {
        std::cerr << "OpenVPN get status failed: " << e.what() << std::endl;
        return "error";
    }
}

OpenVPNStats openvpn_get_stats(OpenVPNClient* client) {
    OpenVPNStats stats = {0};
    
    if (!client || !client->wrapper) {
        return stats;
    }
    
    try {
        auto cppStats = client->wrapper->getStats();
        stats.bytesIn = cppStats.bytesIn;
        stats.bytesOut = cppStats.bytesOut;
        stats.duration = cppStats.duration;
        
        // Copy strings safely
        strncpy(stats.serverIp, cppStats.serverIp.c_str(), sizeof(stats.serverIp) - 1);
        strncpy(stats.localIp, cppStats.localIp.c_str(), sizeof(stats.localIp) - 1);
        stats.serverIp[sizeof(stats.serverIp) - 1] = '\0';
        stats.localIp[sizeof(stats.localIp) - 1] = '\0';
        
        return stats;
    } catch (const std::exception& e) {
        std::cerr << "OpenVPN get stats failed: " << e.what() << std::endl;
        return stats;
    }
}

bool openvpn_is_available(void) {
    try {
        return OpenVPN3Wrapper::isAvailable();
    } catch (const std::exception& e) {
        std::cerr << "OpenVPN availability check failed: " << e.what() << std::endl;
        return false;
    }
}

} // extern "C"
