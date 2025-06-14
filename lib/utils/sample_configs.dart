import 'package:flutter/services.dart';
import '../models/vpn_config.dart';
import 'config_parser.dart';

class SampleConfigs {
  static const List<String> _sampleConfigPaths = [
    'sample_configs/sample_server.ovpn',
    'sample_configs/corporate_vpn.ovpn',
    'sample_configs/vm01.ovpn',
  ];

  static Future<List<VpnConfig>> loadSampleConfigs() async {
    final List<VpnConfig> configs = [];
    
    for (final path in _sampleConfigPaths) {
      try {
        final content = await rootBundle.loadString(path);
        final fileName = path.split('/').last;
        final config = OpenVpnConfigParser.parseConfig(content, fileName: fileName);
        configs.add(config);
      } catch (e) {
        print('Failed to load sample config $path: $e');
      }
    }
    
    return configs;
  }

  static VpnConfig createManualConfig({
    required String name,
    required String server,
    required int port,
    String protocol = 'udp',
    String? username,
    String? password,
  }) {
    return VpnConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      server: server,
      port: port,
      protocol: protocol,
      username: username,
      password: password,
      createdAt: DateTime.now(),
    );
  }
}
