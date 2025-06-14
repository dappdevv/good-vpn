import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/vpn_provider.dart';
import '../models/vpn_config.dart';
import '../utils/config_parser.dart';
import '../utils/sample_configs.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VPN Configurations'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddConfigOptions,
          ),
        ],
      ),
      body: Consumer<VpnProvider>(
        builder: (context, vpnProvider, child) {
          final configs = vpnProvider.configs;
          
          if (configs.isEmpty) {
            return _buildEmptyState();
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: configs.length,
            itemBuilder: (context, index) {
              final config = configs[index];
              return _buildConfigCard(config, vpnProvider);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No VPN Configurations',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add your first configuration to get started',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddConfigOptions,
            icon: const Icon(Icons.add),
            label: const Text('Add Configuration'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard(VpnConfig config, VpnProvider vpnProvider) {
    final isActive = vpnProvider.activeConfig?.id == config.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isActive ? 4 : 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isActive 
              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive 
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                    ),
                    child: Icon(
                      Icons.vpn_key,
                      color: isActive ? Colors.white : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                config.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? Theme.of(context).primaryColor : null,
                                ),
                              ),
                            ),
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          config.displayServer,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleConfigAction(value, config, vpnProvider),
                    itemBuilder: (context) => [
                      if (!isActive)
                        const PopupMenuItem(
                          value: 'activate',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline),
                              SizedBox(width: 8),
                              Text('Set as Active'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildConfigDetails(config),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigDetails(VpnConfig config) {
    return Column(
      children: [
        Row(
          children: [
            _buildDetailChip('Protocol', config.protocol.toUpperCase()),
            const SizedBox(width: 8),
            _buildDetailChip('Port', config.port.toString()),
            if (config.requiresAuth) ...[
              const SizedBox(width: 8),
              _buildDetailChip('Auth', 'Required', color: Colors.orange),
            ],
          ],
        ),
        if (config.hasCertificates) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              _buildDetailChip('Certificates', 'Included', color: Colors.green),
            ],
          ),
        ],
        if (config.lastUsed != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Last used: ${_formatDate(config.lastUsed!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDetailChip(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (color ?? Colors.grey).withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color ?? Colors.grey[700],
        ),
      ),
    );
  }

  void _showAddConfigOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add VPN Configuration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('Import .ovpn file'),
              subtitle: const Text('Import from OpenVPN configuration file'),
              onTap: () {
                Navigator.pop(context);
                _importConfigFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Import from project'),
              subtitle: const Text('Import vm01.ovpn from sample_configs'),
              onTap: () {
                Navigator.pop(context);
                _importFromProject();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Manual configuration'),
              subtitle: const Text('Create configuration manually'),
              onTap: () {
                Navigator.pop(context);
                _showManualConfigDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Load sample configurations'),
              subtitle: const Text('Add demo configurations for testing'),
              onTap: () {
                Navigator.pop(context);
                _loadSampleConfigs();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importConfigFile() async {
    try {
      print('🔍 Starting file picker...');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ovpn', 'conf'],
        allowMultiple: false,
        withData: true,
      );

      print('📁 File picker result: ${result != null ? 'Success' : 'Cancelled'}');

      if (result != null) {
        print('📄 Files selected: ${result.files.length}');

        if (result.files.isNotEmpty) {
          final file = result.files.first;
          print('📋 File info: ${file.name}, size: ${file.size} bytes');

          String content;

          // Try to read from path first, then from bytes
          if (file.path != null) {
            print('📖 Reading from file path: ${file.path}');
            final fileObj = File(file.path!);
            content = await fileObj.readAsString();
          } else if (file.bytes != null) {
            print('📖 Reading from file bytes');
            content = String.fromCharCodes(file.bytes!);
          } else {
            throw Exception('No file data available');
          }

          print('📝 File content length: ${content.length} characters');
          print('📝 First 100 characters: ${content.substring(0, content.length > 100 ? 100 : content.length)}');

          final config = OpenVpnConfigParser.parseConfig(
            content,
            fileName: file.name,
          );

          print('⚙️ Config parsed: ${config.name} (${config.server}:${config.port})');

          final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
          await vpnProvider.addConfig(config);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Configuration "${config.name}" imported successfully'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }

          print('✅ Configuration imported successfully');
        } else {
          print('⚠️ No files in result');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No file selected'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        print('ℹ️ File picker cancelled by user');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File selection cancelled'),
              backgroundColor: Colors.grey,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error importing config: $e');
      print('📚 Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import configuration: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _importFromProject() async {
    try {
      print('📁 Importing vm01.ovpn from project...');

      // Try to read the vm01.ovpn file from the project
      final configPath = 'sample_configs/vm01.ovpn';

      // First try to read from assets
      try {
        final content = await rootBundle.loadString(configPath);
        print('📄 Loaded vm01.ovpn from assets (${content.length} characters)');

        final config = OpenVpnConfigParser.parseConfig(
          content,
          fileName: 'vm01.ovpn',
        );

        final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
        await vpnProvider.addConfig(config);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('VM OpenVPN configuration imported successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        print('✅ VM configuration imported successfully');
        return;
      } catch (assetError) {
        print('⚠️ Could not load from assets: $assetError');
      }

      // Try to read from file system as fallback
      try {
        final file = File(configPath);
        if (await file.exists()) {
          final content = await file.readAsString();
          print('📄 Loaded vm01.ovpn from file system (${content.length} characters)');

          final config = OpenVpnConfigParser.parseConfig(
            content,
            fileName: 'vm01.ovpn',
          );

          final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
          await vpnProvider.addConfig(config);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('VM OpenVPN configuration imported successfully'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }

          print('✅ VM configuration imported successfully');
          return;
        }
      } catch (fileError) {
        print('⚠️ Could not load from file system: $fileError');
      }

      throw Exception('vm01.ovpn not found in assets or file system');

    } catch (e, stackTrace) {
      print('❌ Error importing VM config: $e');
      print('📚 Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import VM configuration: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showManualConfigDialog() {
    final nameController = TextEditingController();
    final serverController = TextEditingController();
    final portController = TextEditingController(text: '1194');
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedProtocol = 'udp';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Manual Configuration'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Configuration Name',
                    hintText: 'My VPN Server',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: serverController,
                  decoration: const InputDecoration(
                    labelText: 'Server Address',
                    hintText: 'vpn.example.com',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: portController,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedProtocol,
                        decoration: const InputDecoration(
                          labelText: 'Protocol',
                        ),
                        items: ['udp', 'tcp'].map((protocol) {
                          return DropdownMenuItem(
                            value: protocol,
                            child: Text(protocol.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedProtocol = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password (optional)',
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    serverController.text.isNotEmpty) {
                  final config = SampleConfigs.createManualConfig(
                    name: nameController.text,
                    server: serverController.text,
                    port: int.tryParse(portController.text) ?? 1194,
                    protocol: selectedProtocol,
                    username: usernameController.text.isNotEmpty
                        ? usernameController.text : null,
                    password: passwordController.text.isNotEmpty
                        ? passwordController.text : null,
                  );

                  final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
                  vpnProvider.addConfig(config);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Configuration "${config.name}" created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSampleConfigs() async {
    try {
      final sampleConfigs = await SampleConfigs.loadSampleConfigs();
      final vpnProvider = Provider.of<VpnProvider>(context, listen: false);

      for (final config in sampleConfigs) {
        await vpnProvider.addConfig(config);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${sampleConfigs.length} sample configurations loaded'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load sample configurations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleConfigAction(String action, VpnConfig config, VpnProvider vpnProvider) {
    switch (action) {
      case 'activate':
        vpnProvider.setActiveConfig(config);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${config.name} set as active configuration'),
          ),
        );
        break;
      case 'edit':
        // TODO: Implement edit functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Edit functionality coming soon'),
          ),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(config, vpnProvider);
        break;
    }
  }

  void _showDeleteConfirmation(VpnConfig config, VpnProvider vpnProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Configuration'),
        content: Text('Are you sure you want to delete "${config.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              vpnProvider.removeConfig(config.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Configuration "${config.name}" deleted'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Recently';
    }
  }
}
