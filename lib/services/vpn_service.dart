import 'dart:async';
import '../models/vpn_config.dart';
import '../models/vpn_status.dart';

abstract class VpnService {
  /// Stream of VPN connection status updates
  Stream<VpnStatus> get statusStream;
  
  /// Current VPN status
  VpnStatus get currentStatus;
  
  /// Connect to VPN using the provided configuration
  Future<bool> connect(VpnConfig config, {String? username, String? password});
  
  /// Disconnect from VPN
  Future<bool> disconnect();
  
  /// Check if VPN permission is granted
  Future<bool> hasPermission();
  
  /// Request VPN permission from user
  Future<bool> requestPermission();
  
  /// Get current connection statistics
  Future<Map<String, dynamic>?> getConnectionStats();
  
  /// Initialize the VPN service
  Future<void> initialize();
  
  /// Dispose resources
  Future<void> dispose();
  
  /// Check if the service is available on current platform
  bool get isAvailable;
  
  /// Get platform-specific error messages
  String? getLastError();
}

class VpnServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const VpnServiceException(this.message, {this.code, this.originalError});
  
  @override
  String toString() {
    if (code != null) {
      return 'VpnServiceException($code): $message';
    }
    return 'VpnServiceException: $message';
  }
}

enum VpnPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  unknown,
}
