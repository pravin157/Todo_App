import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ServerConfigDialog extends StatefulWidget {
  final VoidCallback onConfigChanged;

  const ServerConfigDialog({super.key, required this.onConfigChanged});

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late TextEditingController _urlController;
  bool _isTesting = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiService.instance.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _statusMessage = null;
    });

    final testService = ApiService.instance;
    testService.setBaseUrl(_urlController.text.trim());

    try {
      final todos = await testService.getTodos();
      setState(() {
        _isTesting = false;
        _isSuccess = true;
        _statusMessage = 'Connected successfully! Found ${todos.length} tasks.';
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _isSuccess = false;
        _statusMessage = '$e';
      });
    }
  }

  void _save() {
    ApiService.instance.setBaseUrl(_urlController.text.trim());
    widget.onConfigChanged();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.dns_rounded),
          SizedBox(width: 10),
          Text('Server Configuration'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configure Django Backend API URL:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'http://127.0.0.1:8000/api',
                prefixIcon: const Icon(Icons.link_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Quick Presets:',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('127.0.0.1:8000 (USB / PC)'),
                  onPressed: () {
                    setState(() {
                      _urlController.text = 'http://127.0.0.1:8000/api';
                    });
                  },
                ),
                ActionChip(
                  label: const Text('10.0.2.2:8000 (Emulator)'),
                  onPressed: () {
                    setState(() {
                      _urlController.text = 'http://10.0.2.2:8000/api';
                    });
                  },
                ),
                ActionChip(
                  label: const Text('10.163.155.79:8000 (Wi-Fi)'),
                  onPressed: () {
                    setState(() {
                      _urlController.text = 'http://10.163.155.79:8000/api';
                    });
                  },
                ),
              ],
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle : Icons.error_outline,
                      color: _isSuccess ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _isSuccess ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: _isTesting ? null : _testConnection,
          icon: _isTesting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.network_check_rounded),
          label: const Text('Test'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save & Apply'),
        ),
      ],
    );
  }
}
