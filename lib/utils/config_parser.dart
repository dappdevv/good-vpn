import 'dart:convert';
import 'dart:math';
import '../models/vpn_config.dart';

class OpenVpnConfigParser {
  static VpnConfig parseConfig(String configContent, {String? fileName}) {
    final lines = configContent.split('\n');
    final Map<String, String> options = {};
    final List<String> remotes = [];
    
    String? currentBlock;
    final Map<String, List<String>> blocks = {};
    
    // Parse the config file line by line
    for (String line in lines) {
      line = line.trim();
      
      // Skip empty lines and comments
      if (line.isEmpty || line.startsWith('#') || line.startsWith(';')) {
        continue;
      }
      
      // Handle block start/end
      if (line.startsWith('<') && line.endsWith('>')) {
        if (line.startsWith('</')) {
          currentBlock = null;
        } else {
          currentBlock = line.substring(1, line.length - 1);
          blocks[currentBlock] = [];
        }
        continue;
      }
      
      // If we're in a block, add the line to the block
      if (currentBlock != null) {
        blocks[currentBlock]!.add(line);
        continue;
      }
      
      // Parse regular options
      final parts = line.split(RegExp(r'\s+'));
      if (parts.isNotEmpty) {
        final key = parts[0].toLowerCase();
        final value = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        
        if (key == 'remote') {
          remotes.add(value);
        } else {
          options[key] = value;
        }
      }
    }
    
    // Extract basic configuration
    final server = _extractServer(options, remotes);
    final port = _extractPort(options, remotes);
    final protocol = _extractProtocol(options);
    final name = fileName ?? 'OpenVPN Config ${_generateId()}';
    
    return VpnConfig(
      id: _generateId(),
      name: name,
      server: server,
      port: port,
      protocol: protocol,
      username: options['auth-user-pass'] != null ? '' : null,
      certificateAuthority: blocks['ca']?.join('\n'),
      clientCertificate: blocks['cert']?.join('\n'),
      clientKey: blocks['key']?.join('\n'),
      tlsAuth: blocks['tls-auth']?.join('\n'),
      tlsCrypt: blocks['tls-crypt']?.join('\n'),
      remotes: remotes,
      additionalOptions: options,
      createdAt: DateTime.now(),
    );
  }
  
  static String _extractServer(Map<String, String> options, List<String> remotes) {
    if (remotes.isNotEmpty) {
      final parts = remotes.first.split(' ');
      return parts.isNotEmpty ? parts[0] : 'unknown';
    }
    
    return options['remote']?.split(' ').first ?? 'unknown';
  }
  
  static int _extractPort(Map<String, String> options, List<String> remotes) {
    if (remotes.isNotEmpty) {
      final parts = remotes.first.split(' ');
      if (parts.length > 1) {
        return int.tryParse(parts[1]) ?? 1194;
      }
    }
    
    final portStr = options['port'] ?? options['lport'] ?? options['rport'];
    if (portStr != null) {
      return int.tryParse(portStr) ?? 1194;
    }
    
    return 1194; // Default OpenVPN port
  }
  
  static String _extractProtocol(Map<String, String> options) {
    final proto = options['proto'] ?? options['protocol'];
    if (proto != null) {
      return proto.toLowerCase().contains('tcp') ? 'tcp' : 'udp';
    }
    return 'udp'; // Default protocol
  }
  
  static String _generateId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }
  
  static String generateConfigFile(VpnConfig config) {
    final buffer = StringBuffer();
    
    // Basic connection settings
    buffer.writeln('client');
    buffer.writeln('dev tun');
    buffer.writeln('proto ${config.protocol}');
    
    // Remote servers
    if (config.remotes.isNotEmpty) {
      for (final remote in config.remotes) {
        buffer.writeln('remote $remote');
      }
    } else {
      buffer.writeln('remote ${config.server} ${config.port}');
    }
    
    // Authentication
    if (config.requiresAuth) {
      buffer.writeln('auth-user-pass');
    }
    
    // Certificates and keys
    if (config.certificateAuthority != null) {
      buffer.writeln('<ca>');
      buffer.writeln(config.certificateAuthority);
      buffer.writeln('</ca>');
    }
    
    if (config.clientCertificate != null) {
      buffer.writeln('<cert>');
      buffer.writeln(config.clientCertificate);
      buffer.writeln('</cert>');
    }
    
    if (config.clientKey != null) {
      buffer.writeln('<key>');
      buffer.writeln(config.clientKey);
      buffer.writeln('</key>');
    }
    
    if (config.tlsAuth != null) {
      buffer.writeln('<tls-auth>');
      buffer.writeln(config.tlsAuth);
      buffer.writeln('</tls-auth>');
    }
    
    if (config.tlsCrypt != null) {
      buffer.writeln('<tls-crypt>');
      buffer.writeln(config.tlsCrypt);
      buffer.writeln('</tls-crypt>');
    }
    
    // Additional options
    for (final entry in config.additionalOptions.entries) {
      if (entry.value.isEmpty) {
        buffer.writeln(entry.key);
      } else {
        buffer.writeln('${entry.key} ${entry.value}');
      }
    }
    
    // Common security options
    buffer.writeln('resolv-retry infinite');
    buffer.writeln('nobind');
    buffer.writeln('persist-key');
    buffer.writeln('persist-tun');
    buffer.writeln('verb 3');
    
    return buffer.toString();
  }
}
