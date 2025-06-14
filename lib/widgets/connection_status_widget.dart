import 'package:flutter/material.dart';
import '../models/vpn_status.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final VpnStatus status;
  final Animation<double>? pulseAnimation;

  const ConnectionStatusWidget({
    super.key,
    required this.status,
    this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status Icon
        AnimatedBuilder(
          animation: pulseAnimation ?? const AlwaysStoppedAnimation(1.0),
          builder: (context, child) {
            return Transform.scale(
              scale: status.isConnecting ? pulseAnimation?.value ?? 1.0 : 1.0,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStatusColor(status.state),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(status.state).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _getStatusIcon(status.state),
                  size: 60,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 20),
        
        // Status Text
        Text(
          status.stateDisplayName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: _getStatusColor(status.state),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Status Message
        if (status.message != null)
          Text(
            status.message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        
        // Error Message
        if (status.hasError && status.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status.errorMessage!,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Connection Details
        if (status.isConnected) ...[
          const SizedBox(height: 16),
          _buildConnectionDetails(context),
        ],
      ],
    );
  }

  Widget _buildConnectionDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          if (status.serverIp != null)
            _buildDetailRow(
              context,
              'Server IP',
              status.serverIp!,
              Icons.dns,
            ),
          
          if (status.localIp != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              'Local IP',
              status.localIp!,
              Icons.device_hub,
            ),
          ],
          
          if (status.connectedAt != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              'Connected Since',
              _formatTime(status.connectedAt!),
              Icons.access_time,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.green[700],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.green[700],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.green[800],
              fontSize: 14,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(VpnConnectionState state) {
    switch (state) {
      case VpnConnectionState.connected:
        return Colors.green;
      case VpnConnectionState.connecting:
      case VpnConnectionState.authenticating:
      case VpnConnectionState.reconnecting:
        return Colors.orange;
      case VpnConnectionState.disconnecting:
        return Colors.blue;
      case VpnConnectionState.error:
        return Colors.red;
      case VpnConnectionState.disconnected:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(VpnConnectionState state) {
    switch (state) {
      case VpnConnectionState.connected:
        return Icons.shield;
      case VpnConnectionState.connecting:
      case VpnConnectionState.authenticating:
      case VpnConnectionState.reconnecting:
        return Icons.sync;
      case VpnConnectionState.disconnecting:
        return Icons.sync_disabled;
      case VpnConnectionState.error:
        return Icons.error;
      case VpnConnectionState.disconnected:
        return Icons.shield_outlined;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
