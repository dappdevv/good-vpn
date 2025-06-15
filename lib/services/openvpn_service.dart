import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/vpn_config.dart';
import '../models/vpn_status.dart';
import '../utils/config_parser.dart';
import 'vpn_service.dart';

class OpenVpnService implements VpnService {
  static const MethodChannel _channel = MethodChannel('fl_openvpn_client');
  static const EventChannel _statusChannel = EventChannel('fl_openvpn_client/status');
  
  final StreamController<VpnStatus> _statusController = StreamController<VpnStatus>.broadcast();
  StreamSubscription? _statusSubscription;
  VpnStatus _currentStatus = const VpnStatus(state: VpnConnectionState.disconnected);
  String? _lastError;
  
  @override
  Stream<VpnStatus> get statusStream => _statusController.stream;
  
  @override
  VpnStatus get currentStatus => _currentStatus;
  
  @override
  bool get isAvailable {
    // Check platform availability
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }
  
  @override
  Future<void> initialize() async {
    if (!isAvailable) {
      throw const VpnServiceException('OpenVPN is not available on this platform');
    }

    try {
      debugPrint('🚀 Initializing real OpenVPN service...');
      await _channel.invokeMethod('initialize');
      _setupStatusListener();
      debugPrint('✅ OpenVPN service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize OpenVPN service: $e');
      throw VpnServiceException('Failed to initialize OpenVPN service: $e');
    }
  }
  
  void _setupStatusListener() {
    try {
      debugPrint('📡 Setting up real OpenVPN status listener...');
      _statusSubscription = _statusChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          try {
            final status = _parseStatusEvent(event);
            _currentStatus = status;
            _statusController.add(status);
            debugPrint('📊 Status update: ${status.state} - ${status.message}');
          } catch (e) {
            debugPrint('❌ Error parsing status event: $e');
          }
        },
        onError: (error) {
          debugPrint('❌ Status stream error: $error');
          final errorStatus = VpnStatus(
            state: VpnConnectionState.error,
            errorMessage: error.toString(),
          );
          _currentStatus = errorStatus;
          _statusController.add(errorStatus);
        },
      );
      debugPrint('✅ Status listener setup complete');
    } catch (e) {
      debugPrint('❌ Failed to setup status listener: $e');
      throw VpnServiceException('Failed to setup status listener: $e');
    }
  }
  
  VpnStatus _parseStatusEvent(dynamic event) {
    if (event is Map) {
      final state = _parseConnectionState(event['state'] as String?);
      return VpnStatus(
        state: state,
        message: event['message'] as String?,
        serverIp: event['serverIp'] as String?,
        localIp: event['localIp'] as String?,
        bytesIn: event['bytesIn'] as int?,
        bytesOut: event['bytesOut'] as int?,
        duration: event['duration'] != null 
            ? Duration(seconds: event['duration'] as int)
            : null,
        connectedAt: event['connectedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(event['connectedAt'] as int)
            : null,
        errorMessage: event['errorMessage'] as String?,
      );
    }
    
    return const VpnStatus(state: VpnConnectionState.disconnected);
  }
  
  VpnConnectionState _parseConnectionState(String? state) {
    switch (state?.toLowerCase()) {
      case 'connected':
        return VpnConnectionState.connected;
      case 'connecting':
        return VpnConnectionState.connecting;
      case 'disconnecting':
        return VpnConnectionState.disconnecting;
      case 'authenticating':
        return VpnConnectionState.authenticating;
      case 'reconnecting':
        return VpnConnectionState.reconnecting;
      case 'error':
        return VpnConnectionState.error;
      default:
        return VpnConnectionState.disconnected;
    }
  }
  
  @override
  Future<bool> connect(VpnConfig config, {String? username, String? password}) async {
    try {
      if (!await hasPermission()) {
        final granted = await requestPermission();
        if (!granted) {
          throw const VpnServiceException('VPN permission not granted');
        }
      }

      final configString = OpenVpnConfigParser.generateConfigFile(config);

      debugPrint('🚀 Attempting real OpenVPN connection to ${config.server}:${config.port}');
      debugPrint('📄 Config: ${config.name}');
      debugPrint('🔧 Using OpenVPN3 ClientAPI implementation');
      debugPrint('📝 Config length: ${configString.length} characters');

      final result = await _channel.invokeMethod('connect', {
        'config': configString,
        'username': username ?? config.username,
        'password': password ?? config.password,
        'serverName': config.name,
      });

      debugPrint('✅ Platform channel connect result: $result');
      return result as bool? ?? false;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ Failed to connect: $e');
      throw VpnServiceException('Failed to connect: $e');
    }
  }
  
  @override
  Future<bool> disconnect() async {
    try {
      debugPrint('🔌 Disconnecting from real OpenVPN connection');

      final result = await _channel.invokeMethod('disconnect');
      debugPrint('✅ Platform channel disconnect result: $result');
      return result as bool? ?? false;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ Failed to disconnect: $e');
      throw VpnServiceException('Failed to disconnect: $e');
    }
  }

  @override
  Future<bool> hasPermission() async {
    try {
      final result = await _channel.invokeMethod('hasPermission');
      debugPrint('🔐 VPN permission check result: $result');
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('Error checking VPN permission: $e');
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      debugPrint('🔐 Requesting VPN permission...');
      final result = await _channel.invokeMethod('requestPermission');
      debugPrint('✅ VPN permission request result: $result');
      return result as bool? ?? false;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ Failed to request VPN permission: $e');
      throw VpnServiceException('Failed to request permission: $e');
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getConnectionStats() async {
    try {
      final result = await _channel.invokeMethod('getConnectionStats');
      debugPrint('📊 Real connection stats: $result');

      if (result == null) return null;

      // Convert Map<Object?, Object?> to Map<String, dynamic>
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting connection stats: $e');
      return null;
    }
  }

  @override
  String? getLastError() => _lastError;

  @override
  Future<void> dispose() async {
    await _statusSubscription?.cancel();
    await _statusController.close();

    try {
      await _channel.invokeMethod('dispose');
      debugPrint('🧹 OpenVPN service disposed');
    } catch (e) {
      debugPrint('❌ Error disposing OpenVPN service: $e');
    }
  }


}
