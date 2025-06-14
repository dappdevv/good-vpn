import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class StorageHelper {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _configsFileName = 'vpn_configs.json';
  static const String _activeConfigFileName = 'active_config.txt';

  static Future<void> writeSecure(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Secure storage failed, using file storage: $e');
      }
      await _writeToFile(key, value);
    }
  }

  static Future<String?> readSecure(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Secure storage failed, using file storage: $e');
      }
      return await _readFromFile(key);
    }
  }

  static Future<void> deleteSecure(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Secure storage failed, using file storage: $e');
      }
      await _deleteFromFile(key);
    }
  }

  static Future<void> _writeToFile(String key, String value) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$key.txt');
      await file.writeAsString(value);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('File storage write failed: $e');
      }
    }
  }

  static Future<String?> _readFromFile(String key) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$key.txt');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('File storage read failed: $e');
      }
    }
    return null;
  }

  static Future<void> _deleteFromFile(String key) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$key.txt');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('File storage delete failed: $e');
      }
    }
  }

  // Convenience methods for common operations
  static Future<void> saveConfigs(String configsJson) async {
    await writeSecure('vpn_configs', configsJson);
  }

  static Future<String?> loadConfigs() async {
    return await readSecure('vpn_configs');
  }

  static Future<void> saveActiveConfig(String configId) async {
    await writeSecure('active_config', configId);
  }

  static Future<String?> loadActiveConfig() async {
    return await readSecure('active_config');
  }

  static Future<void> deleteActiveConfig() async {
    await deleteSecure('active_config');
  }
}
