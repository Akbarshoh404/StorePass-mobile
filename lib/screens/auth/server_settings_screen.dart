import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../services/api_client.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late final TextEditingController _controller;
  bool _testing = false;
  String? _testResult;
  bool? _testOk;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: context.read<ApiConfig>().baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final config = context.read<ApiConfig>();
    final probe = ApiClient(config);
    try {
      await probe.listShops();
      setState(() {
        _testOk = true;
        _testResult = 'Connected — the StorePass API responded.';
      });
    } catch (e) {
      setState(() {
        _testOk = false;
        _testResult = e.toString();
      });
    } finally {
      setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final config = context.read<ApiConfig>();
    await config.setBaseUrl(_controller.text);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ApiConfig>();
    return Scaffold(
      appBar: AppBar(title: const Text('Server settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Point the app at your StorePass backend. On an Android emulator, '
            '"localhost" refers to the emulator itself — use 10.0.2.2 instead. '
            'On a physical device, use your computer\'s LAN IP address.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Backend URL',
              hintText: 'http://10.0.2.2:8000',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _testing ? null : _test,
            icon: _testing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.wifi_tethering_rounded),
            label: const Text('Test connection'),
          ),
          if (_testResult != null) ...[
            const SizedBox(height: 12),
            Text(
              _testResult!,
              style: TextStyle(
                color: _testOk == true ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Save')),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await config.resetToDefault();
              _controller.text = config.baseUrl;
            },
            child: const Text('Reset to default'),
          ),
        ],
      ),
    );
  }
}
