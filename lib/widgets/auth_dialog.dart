import 'package:flutter/material.dart';

class AuthDialog extends StatefulWidget {
  final String serverName;
  final String? initialUsername;

  const AuthDialog({
    super.key,
    required this.serverName,
    this.initialUsername,
  });

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _saveCredentials = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialUsername != null) {
      _usernameController.text = widget.initialUsername!;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('VPN Authentication'),
          const SizedBox(height: 4),
          Text(
            widget.serverName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            autofocus: widget.initialUsername == null,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            autofocus: widget.initialUsername != null,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Save credentials'),
            subtitle: const Text('Store securely for future connections'),
            value: _saveCredentials,
            onChanged: (value) {
              setState(() {
                _saveCredentials = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _usernameController.text.isNotEmpty && 
                     _passwordController.text.isNotEmpty
              ? () {
                  Navigator.pop(context, {
                    'username': _usernameController.text,
                    'password': _passwordController.text,
                    'saveCredentials': _saveCredentials,
                  });
                }
              : null,
          child: const Text('Connect'),
        ),
      ],
    );
  }
}

class AuthResult {
  final String username;
  final String password;
  final bool saveCredentials;

  const AuthResult({
    required this.username,
    required this.password,
    required this.saveCredentials,
  });
}

Future<AuthResult?> showAuthDialog(
  BuildContext context, {
  required String serverName,
  String? initialUsername,
}) async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AuthDialog(
      serverName: serverName,
      initialUsername: initialUsername,
    ),
  );

  if (result != null) {
    return AuthResult(
      username: result['username'] as String,
      password: result['password'] as String,
      saveCredentials: result['saveCredentials'] as bool,
    );
  }

  return null;
}
