import 'package:flutter_test/flutter_test.dart';
import 'package:fl_openvpn_client/models/vpn_config.dart';
import 'package:fl_openvpn_client/utils/config_parser.dart';

void main() {
  group('VPN Configuration Tests', () {
    test('VpnConfig creation and serialization', () {
      final config = VpnConfig(
        id: 'test-id',
        name: 'Test Server',
        server: 'test.example.com',
        port: 1194,
        protocol: 'udp',
        username: 'testuser',
        createdAt: DateTime.now(),
      );

      expect(config.name, 'Test Server');
      expect(config.server, 'test.example.com');
      expect(config.port, 1194);
      expect(config.protocol, 'udp');
      expect(config.requiresAuth, true);

      // Test JSON serialization
      final json = config.toJson();
      final deserializedConfig = VpnConfig.fromJson(json);

      expect(deserializedConfig.id, config.id);
      expect(deserializedConfig.name, config.name);
      expect(deserializedConfig.server, config.server);
      expect(deserializedConfig.port, config.port);
    });

    test('OpenVPN config parsing', () {
      const configContent = '''
client
dev tun
proto udp
remote vpn.example.com 1194
auth-user-pass
cipher AES-256-CBC
verb 3
''';

      final config = OpenVpnConfigParser.parseConfig(
        configContent,
        fileName: 'test.ovpn',
      );

      expect(config.name, 'test.ovpn');
      expect(config.server, 'vpn.example.com');
      expect(config.port, 1194);
      expect(config.protocol, 'udp');
    });

    test('OpenVPN config generation', () {
      final config = VpnConfig(
        id: 'test-id',
        name: 'Test Server',
        server: 'test.example.com',
        port: 1194,
        protocol: 'tcp',
        username: 'testuser',
        createdAt: DateTime.now(),
      );

      final configString = OpenVpnConfigParser.generateConfigFile(config);

      expect(configString.contains('client'), true);
      expect(configString.contains('dev tun'), true);
      expect(configString.contains('proto tcp'), true);
      expect(configString.contains('remote test.example.com 1194'), true);
      expect(configString.contains('auth-user-pass'), true);
    });

    test('Config with certificates', () {
      final config = VpnConfig(
        id: 'test-id',
        name: 'Secure Server',
        server: 'secure.example.com',
        port: 443,
        protocol: 'tcp',
        certificateAuthority: 'test-ca-cert',
        clientCertificate: 'test-client-cert',
        clientKey: 'test-client-key',
        createdAt: DateTime.now(),
      );

      expect(config.hasCertificates, true);
      expect(config.requiresAuth, false);

      final configString = OpenVpnConfigParser.generateConfigFile(config);
      expect(configString.contains('<ca>'), true);
      expect(configString.contains('<cert>'), true);
      expect(configString.contains('<key>'), true);
    });

    test('Config equality and hashCode', () {
      final config1 = VpnConfig(
        id: 'same-id',
        name: 'Test Server',
        server: 'test.example.com',
        port: 1194,
        createdAt: DateTime.now(),
      );

      final config2 = VpnConfig(
        id: 'same-id',
        name: 'Different Name',
        server: 'different.example.com',
        port: 443,
        createdAt: DateTime.now(),
      );

      final config3 = VpnConfig(
        id: 'different-id',
        name: 'Test Server',
        server: 'test.example.com',
        port: 1194,
        createdAt: DateTime.now(),
      );

      // Configs with same ID should be equal
      expect(config1, config2);
      expect(config1.hashCode, config2.hashCode);

      // Configs with different ID should not be equal
      expect(config1, isNot(config3));
      expect(config1.hashCode, isNot(config3.hashCode));
    });
  });
}
