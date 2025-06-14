#include "vpn_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>
#include <cstring>
#include <memory>
#include <string>
#include <map>
#include <thread>
#include <chrono>

#define VPN_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), vpn_plugin_get_type(), VpnPlugin))

struct _VpnPlugin {
  GObject parent_instance;
  FlMethodChannel* channel;
  FlEventChannel* event_channel;
  FlEventSink* event_sink;
  gboolean is_connected;
  gchar* current_server_ip;
  gint64 connected_at;
  gint64 bytes_in;
  gint64 bytes_out;
};

G_DEFINE_TYPE(VpnPlugin, vpn_plugin, G_TYPE_OBJECT)

// Forward declarations
static void vpn_plugin_dispose(GObject* object);
static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                          gpointer user_data);
static FlMethodResponse* initialize(VpnPlugin* self);
static FlMethodResponse* has_permission(VpnPlugin* self);
static FlMethodResponse* request_permission(VpnPlugin* self);
static FlMethodResponse* connect_vpn(VpnPlugin* self, FlValue* args);
static FlMethodResponse* disconnect_vpn(VpnPlugin* self);
static FlMethodResponse* get_connection_stats(VpnPlugin* self);
static FlMethodResponse* dispose_vpn(VpnPlugin* self);
static void update_status(VpnPlugin* self, const gchar* state, const gchar* message);

static void vpn_plugin_class_init(VpnPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = vpn_plugin_dispose;
}

static void vpn_plugin_init(VpnPlugin* self) {
  self->is_connected = FALSE;
  self->current_server_ip = nullptr;
  self->connected_at = 0;
  self->bytes_in = 0;
  self->bytes_out = 0;
}

static void vpn_plugin_dispose(GObject* object) {
  VpnPlugin* self = VPN_PLUGIN(object);
  
  if (self->current_server_ip) {
    g_free(self->current_server_ip);
    self->current_server_ip = nullptr;
  }
  
  G_OBJECT_CLASS(vpn_plugin_parent_class)->dispose(object);
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                          gpointer user_data) {
  VpnPlugin* self = VPN_PLUGIN(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  FlMethodResponse* response = nullptr;

  if (strcmp(method, "initialize") == 0) {
    response = initialize(self);
  } else if (strcmp(method, "hasPermission") == 0) {
    response = has_permission(self);
  } else if (strcmp(method, "requestPermission") == 0) {
    response = request_permission(self);
  } else if (strcmp(method, "connect") == 0) {
    response = connect_vpn(self, fl_method_call_get_args(method_call));
  } else if (strcmp(method, "disconnect") == 0) {
    response = disconnect_vpn(self);
  } else if (strcmp(method, "getConnectionStats") == 0) {
    response = get_connection_stats(self);
  } else if (strcmp(method, "dispose") == 0) {
    response = dispose_vpn(self);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static FlMethodResponse* initialize(VpnPlugin* self) {
  update_status(self, "disconnected", "VPN initialized");
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
}

static FlMethodResponse* has_permission(VpnPlugin* self) {
  // On Linux, check if user has sudo privileges or is in appropriate groups
  gboolean has_perm = (geteuid() == 0); // Simple check for root
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(has_perm)));
}

static FlMethodResponse* request_permission(VpnPlugin* self) {
  // On Linux, permissions are typically handled at the system level
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
}

static FlMethodResponse* connect_vpn(VpnPlugin* self, FlValue* args) {
  if (self->is_connected) {
    update_status(self, "error", "Already connected");
    return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(FALSE)));
  }

  FlValue* config_value = fl_value_lookup_string(args, "config");
  FlValue* username_value = fl_value_lookup_string(args, "username");
  FlValue* password_value = fl_value_lookup_string(args, "password");
  FlValue* server_name_value = fl_value_lookup_string(args, "serverName");

  if (!config_value) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_CONFIG", 
                                                          "Configuration is required", 
                                                          nullptr));
  }

  const gchar* config = fl_value_get_string(config_value);
  const gchar* username = username_value ? fl_value_get_string(username_value) : nullptr;
  const gchar* password = password_value ? fl_value_get_string(password_value) : nullptr;
  const gchar* server_name = server_name_value ? fl_value_get_string(server_name_value) : nullptr;

  update_status(self, "connecting", "Establishing VPN connection...");

  // Parse server info from config (simplified)
  const gchar* remote_start = strstr(config, "remote ");
  if (remote_start) {
    remote_start += 7; // Skip "remote "
    const gchar* line_end = strchr(remote_start, '\n');
    if (!line_end) line_end = remote_start + strlen(remote_start);
    
    const gchar* space = strchr(remote_start, ' ');
    gsize server_len = space ? (space - remote_start) : (line_end - remote_start);
    
    if (self->current_server_ip) {
      g_free(self->current_server_ip);
    }
    self->current_server_ip = g_strndup(remote_start, server_len);
  }

  // Simulate connection process (in a real implementation, this would use OpenVPN)
  std::thread([self]() {
    std::this_thread::sleep_for(std::chrono::seconds(2));
    
    self->is_connected = TRUE;
    self->connected_at = g_get_real_time() / 1000; // Convert to milliseconds
    self->bytes_in = 0;
    self->bytes_out = 0;
    
    update_status(self, "connected", "Connected to VPN");
  }).detach();

  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
}

static FlMethodResponse* disconnect_vpn(VpnPlugin* self) {
  if (!self->is_connected) {
    return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }

  update_status(self, "disconnecting", "Disconnecting...");

  self->is_connected = FALSE;
  self->connected_at = 0;
  self->bytes_in = 0;
  self->bytes_out = 0;
  
  if (self->current_server_ip) {
    g_free(self->current_server_ip);
    self->current_server_ip = nullptr;
  }

  update_status(self, "disconnected", "Disconnected");
  
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
}

static FlMethodResponse* get_connection_stats(VpnPlugin* self) {
  if (!self->is_connected) {
    return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
  }

  FlValue* stats = fl_value_new_map();
  
  gint64 duration = (g_get_real_time() / 1000) - self->connected_at;
  duration /= 1000; // Convert to seconds
  
  fl_value_set_string_take(stats, "bytesIn", fl_value_new_int(self->bytes_in));
  fl_value_set_string_take(stats, "bytesOut", fl_value_new_int(self->bytes_out));
  fl_value_set_string_take(stats, "duration", fl_value_new_int(duration));
  fl_value_set_string_take(stats, "serverIp", fl_value_new_string(self->current_server_ip ? self->current_server_ip : ""));
  fl_value_set_string_take(stats, "localIp", fl_value_new_string("192.168.1.100"));

  return FL_METHOD_RESPONSE(fl_method_success_response_new(stats));
}

static FlMethodResponse* dispose_vpn(VpnPlugin* self) {
  if (self->is_connected) {
    disconnect_vpn(self);
  }
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
}

static void update_status(VpnPlugin* self, const gchar* state, const gchar* message) {
  if (!self->event_sink) return;

  FlValue* status = fl_value_new_map();
  fl_value_set_string_take(status, "state", fl_value_new_string(state));
  fl_value_set_string_take(status, "message", fl_value_new_string(message));

  if (self->is_connected) {
    fl_value_set_string_take(status, "serverIp", fl_value_new_string(self->current_server_ip ? self->current_server_ip : ""));
    fl_value_set_string_take(status, "localIp", fl_value_new_string("192.168.1.100"));
    fl_value_set_string_take(status, "bytesIn", fl_value_new_int(self->bytes_in));
    fl_value_set_string_take(status, "bytesOut", fl_value_new_int(self->bytes_out));
    
    if (self->connected_at > 0) {
      gint64 duration = (g_get_real_time() / 1000) - self->connected_at;
      duration /= 1000; // Convert to seconds
      fl_value_set_string_take(status, "duration", fl_value_new_int(duration));
      fl_value_set_string_take(status, "connectedAt", fl_value_new_int(self->connected_at));
    }
  }

  fl_event_sink_success(self->event_sink, status, nullptr);
}

static FlMethodErrorResponse* event_listen_cb(FlEventChannel* channel,
                                             FlValue* args,
                                             gpointer user_data) {
  VpnPlugin* self = VPN_PLUGIN(user_data);
  // Event sink will be set by the framework
  return nullptr;
}

static FlMethodErrorResponse* event_cancel_cb(FlEventChannel* channel,
                                             FlValue* args,
                                             gpointer user_data) {
  VpnPlugin* self = VPN_PLUGIN(user_data);
  self->event_sink = nullptr;
  return nullptr;
}

void vpn_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  VpnPlugin* plugin = VPN_PLUGIN(g_object_new(vpn_plugin_get_type(), nullptr));

  plugin->channel = fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                                         "fl_openvpn_client",
                                         FL_METHOD_CODEC(fl_standard_method_codec_new()));
  fl_method_channel_set_method_call_handler(plugin->channel, method_call_cb,
                                           g_object_ref(plugin),
                                           g_object_unref);

  plugin->event_channel = fl_event_channel_new(fl_plugin_registrar_get_messenger(registrar),
                                               "fl_openvpn_client/status",
                                               FL_METHOD_CODEC(fl_standard_method_codec_new()));
  fl_event_channel_set_stream_handlers(plugin->event_channel, event_listen_cb, event_cancel_cb,
                                      g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
