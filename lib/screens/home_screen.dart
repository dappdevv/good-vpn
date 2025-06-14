import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vpn_provider.dart';
import '../models/vpn_status.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/server_list_widget.dart';
import '../widgets/auth_dialog.dart';
import 'config_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _pulseController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenVPN Client'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ConfigScreen()),
                  );
                  break;
                case 'about':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 8),
                    Text('About'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<VpnProvider>(
        builder: (context, vpnProvider, child) {
          if (!vpnProvider.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connection Status Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        ConnectionStatusWidget(
                          status: vpnProvider.status,
                          pulseAnimation: _pulseAnimation,
                        ),
                        const SizedBox(height: 20),
                        _buildConnectionButton(vpnProvider),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Server Selection Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Server Configuration',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ConfigScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ServerListWidget(
                          configs: vpnProvider.configs,
                          activeConfig: vpnProvider.activeConfig,
                          onConfigSelected: (config) {
                            vpnProvider.setActiveConfig(config);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Statistics Card
                if (vpnProvider.isConnected) _buildStatisticsCard(vpnProvider),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildConnectionButton(VpnProvider vpnProvider) {
    final status = vpnProvider.status;
    final isConnecting = status.isConnecting || status.state == VpnConnectionState.authenticating;
    final isConnected = status.isConnected;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isConnecting ? null : () => _handleConnectionToggle(vpnProvider),
        style: ElevatedButton.styleFrom(
          backgroundColor: isConnected 
              ? Colors.red 
              : Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: isConnecting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Connecting...'),
                ],
              )
            : Text(
                isConnected ? 'Disconnect' : 'Connect',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
  
  Widget _buildStatisticsCard(VpnProvider vpnProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Duration',
                    _formatDuration(vpnProvider.status.duration),
                    Icons.timer,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Server IP',
                    vpnProvider.status.serverIp ?? 'Unknown',
                    Icons.dns,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Downloaded',
                    _formatBytes(vpnProvider.status.bytesIn),
                    Icons.download,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Uploaded',
                    _formatBytes(vpnProvider.status.bytesOut),
                    Icons.upload,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Future<void> _handleConnectionToggle(VpnProvider vpnProvider) async {
    try {
      if (vpnProvider.isConnected) {
        await vpnProvider.disconnect();
      } else {
        if (vpnProvider.activeConfig == null) {
          _showNoConfigDialog();
          return;
        }
        
        // Check for permission first
        if (!await vpnProvider.hasPermission()) {
          final granted = await vpnProvider.requestPermission();
          if (!granted) {
            _showPermissionDeniedDialog();
            return;
          }
        }

        // Check if authentication is required
        String? username;
        String? password;

        if (vpnProvider.activeConfig!.requiresAuth) {
          final authResult = await showAuthDialog(
            context,
            serverName: vpnProvider.activeConfig!.name,
            initialUsername: vpnProvider.activeConfig!.username,
          );

          if (authResult == null) {
            // User cancelled authentication
            return;
          }

          username = authResult.username;
          password = authResult.password;

          // Optionally save credentials if user requested
          if (authResult.saveCredentials) {
            final updatedConfig = vpnProvider.activeConfig!.copyWith(
              username: username,
              password: password,
            );
            await vpnProvider.updateConfig(updatedConfig);
          }
        }

        await vpnProvider.connect(username: username, password: password);
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }
  
  void _showNoConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Configuration'),
        content: const Text('Please add a VPN configuration first.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConfigScreen()),
              );
            },
            child: const Text('Add Config'),
          ),
        ],
      ),
    );
  }
  
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('VPN permission is required to establish a connection.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00:00';
    
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    
    return '$hours:$minutes:$seconds';
  }
  
  String _formatBytes(int? bytes) {
    if (bytes == null) return '0 B';
    
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var suffixIndex = 0;
    
    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }
    
    return '${size.toStringAsFixed(1)} ${suffixes[suffixIndex]}';
  }
}
