import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_client.dart';
import '../auth/server_settings_screen.dart';

/// Shared across all three roles: display name / password editing, theme
/// toggle, backend server settings, and sign out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _passwordController = TextEditingController();
  bool _saving = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: context.read<AuthProvider>().principal?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      await context.read<AuthProvider>().updateProfile(
            name: _nameController.text.trim(),
            password: _passwordController.text.isEmpty ? null : _passwordController.text,
          );
      _passwordController.clear();
      setState(() => _success = 'Profile updated.');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final principal = auth.principal;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (principal != null) ...[
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(principal.name.isNotEmpty ? principal.name[0].toUpperCase() : '?')),
                title: Text(principal.name),
                subtitle: Text('${principal.contact} · ${principal.role.name}'),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'New password (optional)',
                    helperText: 'Leave blank to keep current password',
                  ),
                  obscureText: true,
                  validator: (v) => (v != null && v.isNotEmpty && v.length < 6) ? 'Minimum 6 characters' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                if (_success != null) ...[
                  const SizedBox(height: 12),
                  Text(_success!, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save changes'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.brightness_6_rounded),
            title: const Text('Appearance'),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded)),
                ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded)),
                ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded)),
              ],
              selected: {theme.mode},
              onSelectionChanged: (s) => context.read<ThemeProvider>().setMode(s.first),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings_ethernet_rounded),
            title: const Text('Server settings'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ServerSettingsScreen())),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: Theme.of(context).colorScheme.error),
            title: Text('Sign out', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
    );
  }
}
