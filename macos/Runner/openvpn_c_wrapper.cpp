#include <iostream>
#include <memory>
#include <string>

// Include the OpenVPN client
#include "../../openvpn/openvpn_client.h"

// C interface for Swift
extern "C" {

struct OpenVPNClientWrapper {
    std::unique_ptr<OpenVPNClient> client;
    std::string lastStatus;
    
    OpenVPNClientWrapper() : lastStatus("disconnected") {
        try {
            client = std::make_unique<OpenVPNClient>([this](const std::string& status, const std::string& message) {
                this->lastStatus = status;
                std::cout << "OpenVPN Status: " << status << " - " << message << std::endl;
            });
        } catch (const std::exception& e) {
            std::cerr << "Failed to create OpenVPN client: " << e.what() << std::endl;
        }
    }
};

void* openvpn_client_create() {
    try {
        std::cout << "Creating OpenVPN client for macOS..." << std::endl;
        return new OpenVPNClientWrapper();
    } catch (const std::exception& e) {
        std::cerr << "Failed to create OpenVPN client wrapper: " << e.what() << std::endl;
        return nullptr;
    }
}

void openvpn_client_destroy(void* client) {
    if (client) {
        std::cout << "Destroying OpenVPN client..." << std::endl;
        delete static_cast<OpenVPNClientWrapper*>(client);
    }
}

bool openvpn_client_connect(void* client, const char* config, const char* username, const char* password) {
    if (!client) {
        std::cerr << "Invalid OpenVPN client" << std::endl;
        return false;
    }
    
    auto wrapper = static_cast<OpenVPNClientWrapper*>(client);
    if (!wrapper->client) {
        std::cerr << "OpenVPN client not initialized" << std::endl;
        return false;
    }
    
    try {
        std::cout << "Starting OpenVPN connection..." << std::endl;
        std::string configStr = config ? config : "";
        std::string usernameStr = username ? username : "";
        std::string passwordStr = password ? password : "";
        
        return wrapper->client->connect(configStr, usernameStr, passwordStr);
    } catch (const std::exception& e) {
        std::cerr << "OpenVPN connect failed: " << e.what() << std::endl;
        return false;
    }
}

void openvpn_client_disconnect(void* client) {
    if (!client) {
        std::cerr << "Invalid OpenVPN client" << std::endl;
        return;
    }
    
    auto wrapper = static_cast<OpenVPNClientWrapper*>(client);
    if (!wrapper->client) {
        std::cerr << "OpenVPN client not initialized" << std::endl;
        return;
    }
    
    try {
        std::cout << "Disconnecting OpenVPN..." << std::endl;
        wrapper->client->disconnect();
    } catch (const std::exception& e) {
        std::cerr << "OpenVPN disconnect failed: " << e.what() << std::endl;
    }
}

const char* openvpn_client_get_status(void* client) {
    if (!client) {
        return "error";
    }
    
    auto wrapper = static_cast<OpenVPNClientWrapper*>(client);
    if (!wrapper->client) {
        return "error";
    }
    
    try {
        return wrapper->lastStatus.c_str();
    } catch (const std::exception& e) {
        std::cerr << "OpenVPN get status failed: " << e.what() << std::endl;
        return "error";
    }
}

bool openvpn_client_is_available() {
    try {
        return OpenVPNClient::isOpenVPN3Available();
    } catch (const std::exception& e) {
        std::cerr << "OpenVPN availability check failed: " << e.what() << std::endl;
        return false;
    }
}

uint64_t openvpn_client_get_bytes_in(void* client) {
    if (!client) return 0;
    auto wrapper = static_cast<OpenVPNClientWrapper*>(client);
    if (!wrapper->client) return 0;
    try {
        return wrapper->client->getStats().bytesIn;
    } catch (const std::exception& e) {
        std::cerr << "OpenVPN get bytes in failed: " << e.what() << std::endl;
        return 0;
    }
}

uint64_t openvpn_client_get_bytes_out(void* client) {
    if (!client) return 0;
    auto wrapper = static_cast<OpenVPNClientWrapper*>(client);
    if (!wrapper->client) return 0;
    try {
        return wrapper->client->getStats().bytesOut;
    } catch (const std::exception& e) {
        std::cerr << "OpenVPN get bytes out failed: " << e.what() << std::endl;
        return 0;
    }
}

uint64_t openvpn_client_get_duration(void* client) {
    if (!client) return 0;
    auto wrapper = static_cast<OpenVPNClientWrapper*>(client);
    if (!wrapper->client) return 0;
    try {
        return wrapper->client->getStats().duration;
    } catch (const std::exception& e) {
        std::cerr << "OpenVPN get duration failed: " << e.what() << std::endl;
        return 0;
    }
}

const char* openvpn_client_get_server_ip(void* client) {
    if (!client) return "";
    auto wrapper = static_cast<OpenVPNClientWrapper*>(client);
    if (!wrapper->client) return "";
    try {
        static std::string serverIp;
        serverIp = wrapper->client->getStats().serverIp;
        return serverIp.c_str();
    } catch (const std::exception& e) {
        std::cerr << "OpenVPN get server IP failed: " << e.what() << std::endl;
        return "";
    }
}

const char* openvpn_client_get_local_ip(void* client) {
    if (!client) return "";
    auto wrapper = static_cast<OpenVPNClientWrapper*>(client);
    if (!wrapper->client) return "";
    try {
        static std::string localIp;
        localIp = wrapper->client->getStats().localIp;
        std::cout << "📊 macOS Stats: Local IP = '" << localIp << "'" << std::endl;
        return localIp.c_str();
    } catch (const std::exception& e) {
        std::cerr << "OpenVPN get local IP failed: " << e.what() << std::endl;
        return "";
    }
}

} // extern "C"
