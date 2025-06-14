#pragma once

// Minimal OpenVPN interface for Windows compilation
// In production, replace with actual OpenVPN library

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    char* config;
    char* username;
    char* password;
} openvpn_config_t;

typedef struct {
    unsigned long bytes_in;
    unsigned long bytes_out;
    unsigned long duration;
    char server_ip[64];
    char local_ip[64];
} openvpn_stats_t;

typedef void (*openvpn_status_callback_t)(const char* status, const char* message);

int openvpn_connect(const openvpn_config_t* config, openvpn_status_callback_t callback);
void openvpn_disconnect(void);
int openvpn_get_stats(openvpn_stats_t* stats);

#ifdef __cplusplus
}
#endif
