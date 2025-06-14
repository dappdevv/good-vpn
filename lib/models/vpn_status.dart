enum VpnConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
  authenticating,
  reconnecting,
}

class VpnStatus {
  final VpnConnectionState state;
  final String? message;
  final DateTime? connectedAt;
  final String? serverIp;
  final String? localIp;
  final int? bytesIn;
  final int? bytesOut;
  final Duration? duration;
  final String? errorMessage;

  const VpnStatus({
    required this.state,
    this.message,
    this.connectedAt,
    this.serverIp,
    this.localIp,
    this.bytesIn,
    this.bytesOut,
    this.duration,
    this.errorMessage,
  });

  VpnStatus copyWith({
    VpnConnectionState? state,
    String? message,
    DateTime? connectedAt,
    String? serverIp,
    String? localIp,
    int? bytesIn,
    int? bytesOut,
    Duration? duration,
    String? errorMessage,
  }) {
    return VpnStatus(
      state: state ?? this.state,
      message: message ?? this.message,
      connectedAt: connectedAt ?? this.connectedAt,
      serverIp: serverIp ?? this.serverIp,
      localIp: localIp ?? this.localIp,
      bytesIn: bytesIn ?? this.bytesIn,
      bytesOut: bytesOut ?? this.bytesOut,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isConnected => state == VpnConnectionState.connected;
  bool get isConnecting => state == VpnConnectionState.connecting;
  bool get isDisconnected => state == VpnConnectionState.disconnected;
  bool get hasError => state == VpnConnectionState.error;

  String get stateDisplayName {
    switch (state) {
      case VpnConnectionState.disconnected:
        return 'Disconnected';
      case VpnConnectionState.connecting:
        return 'Connecting';
      case VpnConnectionState.connected:
        return 'Connected';
      case VpnConnectionState.disconnecting:
        return 'Disconnecting';
      case VpnConnectionState.error:
        return 'Error';
      case VpnConnectionState.authenticating:
        return 'Authenticating';
      case VpnConnectionState.reconnecting:
        return 'Reconnecting';
    }
  }

  @override
  String toString() {
    return 'VpnStatus(state: $state, message: $message, serverIp: $serverIp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VpnStatus &&
        other.state == state &&
        other.message == message &&
        other.connectedAt == connectedAt &&
        other.serverIp == serverIp &&
        other.localIp == localIp &&
        other.bytesIn == bytesIn &&
        other.bytesOut == bytesOut &&
        other.duration == duration &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      state,
      message,
      connectedAt,
      serverIp,
      localIp,
      bytesIn,
      bytesOut,
      duration,
      errorMessage,
    );
  }
}
