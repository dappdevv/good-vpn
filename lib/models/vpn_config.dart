class VpnConfig {
  final String id;
  final String name;
  final String server;
  final int port;
  final String protocol; // udp or tcp
  final String? username;
  final String? password;
  final String? certificateAuthority;
  final String? clientCertificate;
  final String? clientKey;
  final String? tlsAuth;
  final String? tlsCrypt;
  final List<String> remotes;
  final Map<String, String> additionalOptions;
  final DateTime createdAt;
  final DateTime? lastUsed;
  final bool isActive;

  const VpnConfig({
    required this.id,
    required this.name,
    required this.server,
    required this.port,
    this.protocol = 'udp',
    this.username,
    this.password,
    this.certificateAuthority,
    this.clientCertificate,
    this.clientKey,
    this.tlsAuth,
    this.tlsCrypt,
    this.remotes = const [],
    this.additionalOptions = const {},
    required this.createdAt,
    this.lastUsed,
    this.isActive = false,
  });

  VpnConfig copyWith({
    String? id,
    String? name,
    String? server,
    int? port,
    String? protocol,
    String? username,
    String? password,
    String? certificateAuthority,
    String? clientCertificate,
    String? clientKey,
    String? tlsAuth,
    String? tlsCrypt,
    List<String>? remotes,
    Map<String, String>? additionalOptions,
    DateTime? createdAt,
    DateTime? lastUsed,
    bool? isActive,
  }) {
    return VpnConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      server: server ?? this.server,
      port: port ?? this.port,
      protocol: protocol ?? this.protocol,
      username: username ?? this.username,
      password: password ?? this.password,
      certificateAuthority: certificateAuthority ?? this.certificateAuthority,
      clientCertificate: clientCertificate ?? this.clientCertificate,
      clientKey: clientKey ?? this.clientKey,
      tlsAuth: tlsAuth ?? this.tlsAuth,
      tlsCrypt: tlsCrypt ?? this.tlsCrypt,
      remotes: remotes ?? this.remotes,
      additionalOptions: additionalOptions ?? this.additionalOptions,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'server': server,
      'port': port,
      'protocol': protocol,
      'username': username,
      'password': password,
      'certificateAuthority': certificateAuthority,
      'clientCertificate': clientCertificate,
      'clientKey': clientKey,
      'tlsAuth': tlsAuth,
      'tlsCrypt': tlsCrypt,
      'remotes': remotes,
      'additionalOptions': additionalOptions,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory VpnConfig.fromJson(Map<String, dynamic> json) {
    return VpnConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      server: json['server'] as String,
      port: json['port'] as int,
      protocol: json['protocol'] as String? ?? 'udp',
      username: json['username'] as String?,
      password: json['password'] as String?,
      certificateAuthority: json['certificateAuthority'] as String?,
      clientCertificate: json['clientCertificate'] as String?,
      clientKey: json['clientKey'] as String?,
      tlsAuth: json['tlsAuth'] as String?,
      tlsCrypt: json['tlsCrypt'] as String?,
      remotes: List<String>.from(json['remotes'] as List? ?? []),
      additionalOptions: Map<String, String>.from(json['additionalOptions'] as Map? ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed'] as String) : null,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  String get displayServer => remotes.isNotEmpty ? remotes.first : '$server:$port';

  bool get requiresAuth => username != null || password != null;

  bool get hasCertificates => 
      certificateAuthority != null || 
      clientCertificate != null || 
      clientKey != null;

  @override
  String toString() {
    return 'VpnConfig(id: $id, name: $name, server: $server:$port)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VpnConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
