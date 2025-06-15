import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/vpn_config.dart';
import '../models/vpn_status.dart';
import '../services/vpn_service.dart';
import '../services/openvpn_service.dart';
import '../utils/storage_helper.dart';

class VpnProvider extends ChangeNotifier {
  final VpnService _vpnService = OpenVpnService();
  
  List<VpnConfig> _configs = [];
  VpnConfig? _activeConfig;
  VpnStatus _status = const VpnStatus(state: VpnConnectionState.disconnected);
  bool _isInitialized = false;
  StreamSubscription? _statusSubscription;
  Timer? _statsTimer;
  
  // Getters
  List<VpnConfig> get configs => List.unmodifiable(_configs);
  VpnConfig? get activeConfig => _activeConfig;
  VpnStatus get status => _status;
  bool get isInitialized => _isInitialized;
  bool get isConnected => _status.isConnected;
  bool get isConnecting => _status.isConnecting;
  bool get canConnect => _activeConfig != null && _status.isDisconnected;
  
  // Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _vpnService.initialize();
      await _loadConfigs();
      await _loadActiveConfig();
      
      _statusSubscription = _vpnService.statusStream.listen((status) {
        _status = status;

        // Start/stop stats polling based on connection state
        if (status.isConnected && _statsTimer == null) {
          _startStatsPolling();
        } else if (!status.isConnected && _statsTimer != null) {
          _stopStatsPolling();
        }

        notifyListeners();
      });
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize VPN provider: $e');
      rethrow;
    }
  }
  
  // Load configurations from storage
  Future<void> _loadConfigs() async {
    try {
      final configsJson = await StorageHelper.loadConfigs();
      if (configsJson != null) {
        final List<dynamic> configsList = jsonDecode(configsJson);
        _configs = configsList.map((json) => VpnConfig.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Failed to load configs: $e');
      _configs = [];
    }
  }

  // Load active configuration
  Future<void> _loadActiveConfig() async {
    try {
      final activeConfigId = await StorageHelper.loadActiveConfig();
      if (activeConfigId != null) {
        try {
          _activeConfig = _configs.firstWhere(
            (config) => config.id == activeConfigId,
          );
        } catch (e) {
          _activeConfig = _configs.isNotEmpty ? _configs.first : null;
        }
      } else if (_configs.isNotEmpty) {
        _activeConfig = _configs.first;
      }
    } catch (e) {
      debugPrint('Failed to load active config: $e');
      _activeConfig = _configs.isNotEmpty ? _configs.first : null;
    }
  }

  // Save configurations to storage
  Future<void> _saveConfigs() async {
    try {
      final configsJson = jsonEncode(_configs.map((config) => config.toJson()).toList());
      await StorageHelper.saveConfigs(configsJson);
    } catch (e) {
      debugPrint('Failed to save configs: $e');
    }
  }

  // Save active configuration
  Future<void> _saveActiveConfig() async {
    try {
      if (_activeConfig != null) {
        await StorageHelper.saveActiveConfig(_activeConfig!.id);
      } else {
        await StorageHelper.deleteActiveConfig();
      }
    } catch (e) {
      debugPrint('Failed to save active config: $e');
    }
  }
  
  // Add a new VPN configuration
  Future<void> addConfig(VpnConfig config) async {
    _configs.add(config);
    await _saveConfigs();
    
    // Set as active if it's the first config
    if (_activeConfig == null) {
      await setActiveConfig(config);
    }
    
    notifyListeners();
  }
  
  // Update an existing configuration
  Future<void> updateConfig(VpnConfig config) async {
    final index = _configs.indexWhere((c) => c.id == config.id);
    if (index != -1) {
      _configs[index] = config;
      await _saveConfigs();
      
      // Update active config if it's the same
      if (_activeConfig?.id == config.id) {
        _activeConfig = config;
        await _saveActiveConfig();
      }
      
      notifyListeners();
    }
  }
  
  // Remove a configuration
  Future<void> removeConfig(String configId) async {
    _configs.removeWhere((config) => config.id == configId);
    await _saveConfigs();
    
    // Clear active config if it was removed
    if (_activeConfig?.id == configId) {
      _activeConfig = _configs.isNotEmpty ? _configs.first : null;
      await _saveActiveConfig();
    }
    
    notifyListeners();
  }
  
  // Set active configuration
  Future<void> setActiveConfig(VpnConfig? config) async {
    _activeConfig = config;
    await _saveActiveConfig();
    notifyListeners();
  }
  
  // Connect to VPN
  Future<bool> connect({String? username, String? password}) async {
    if (_activeConfig == null) {
      throw Exception('No active configuration selected');
    }
    
    try {
      final success = await _vpnService.connect(
        _activeConfig!,
        username: username,
        password: password,
      );
      
      if (success) {
        // Update last used timestamp
        final updatedConfig = _activeConfig!.copyWith(lastUsed: DateTime.now());
        await updateConfig(updatedConfig);
      }
      
      return success;
    } catch (e) {
      debugPrint('Failed to connect: $e');
      rethrow;
    }
  }
  
  // Disconnect from VPN
  Future<bool> disconnect() async {
    try {
      return await _vpnService.disconnect();
    } catch (e) {
      debugPrint('Failed to disconnect: $e');
      rethrow;
    }
  }
  
  // Check VPN permission
  Future<bool> hasPermission() async {
    return await _vpnService.hasPermission();
  }
  
  // Request VPN permission
  Future<bool> requestPermission() async {
    return await _vpnService.requestPermission();
  }
  
  // Get connection statistics
  Future<Map<String, dynamic>?> getConnectionStats() async {
    return await _vpnService.getConnectionStats();
  }

  // Start periodic stats polling when connected
  void _startStatsPolling() {
    debugPrint('🔄 Starting stats polling...');
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final stats = await _vpnService.getConnectionStats();
        if (stats != null && _status.isConnected) {
          // Update status with latest stats including VPN IP
          _status = _status.copyWith(
            serverIp: stats['serverIp'] as String?,
            localIp: stats['localIp'] as String?,
            bytesIn: stats['bytesIn'] as int?,
            bytesOut: stats['bytesOut'] as int?,
            duration: stats['duration'] != null
                ? Duration(seconds: stats['duration'] as int)
                : null,
          );
          notifyListeners();
        }
      } catch (e) {
        debugPrint('❌ Error polling stats: $e');
      }
    });
  }

  // Stop stats polling
  void _stopStatsPolling() {
    debugPrint('⏹️ Stopping stats polling...');
    _statsTimer?.cancel();
    _statsTimer = null;
  }
  
  @override
  void dispose() {
    _statusSubscription?.cancel();
    _stopStatsPolling();
    _vpnService.dispose();
    super.dispose();
  }
}
