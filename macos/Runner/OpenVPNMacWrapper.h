#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// C interface for OpenVPN3 wrapper to be called from Swift
typedef struct OpenVPNClient OpenVPNClient;

// Status callback function type
typedef void (*OpenVPNStatusCallback)(const char* state, const char* message);

// Connection statistics structure
typedef struct {
    unsigned long long bytesIn;
    unsigned long long bytesOut;
    unsigned long long duration;
    char serverIp[256];
    char localIp[256];
} OpenVPNStats;

// Create OpenVPN client instance
OpenVPNClient* openvpn_create(OpenVPNStatusCallback callback);

// Destroy OpenVPN client instance
void openvpn_destroy(OpenVPNClient* client);

// Connect to OpenVPN server
bool openvpn_connect(OpenVPNClient* client, const char* config, const char* username, const char* password);

// Disconnect from OpenVPN server
void openvpn_disconnect(OpenVPNClient* client);

// Get connection status
const char* openvpn_get_status(OpenVPNClient* client);

// Get connection statistics
OpenVPNStats openvpn_get_stats(OpenVPNClient* client);

// Check if OpenVPN is available
bool openvpn_is_available(void);

#ifdef __cplusplus
}
#endif
