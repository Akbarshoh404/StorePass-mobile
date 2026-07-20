import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/lock_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_client.dart';
import '../pin_entry_screen.dart';

/// Shared across all three roles: identity hero, account/security settings
/// grouped into cards, and sign out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final principal = auth.principal;
    final heroBg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0B0B10)
        : const Color(0xFF16161C);

    return Scaffold(
      body: principal == null
          ? const SizedBox.shrink()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _ProfileHero(background: heroBg)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SettingsGroup(
                        title: 'Account',
                        rows: [
                          _SettingsRow(
                            icon: Icons.badge_outlined,
                            title: 'Display name',
                            subtitle: principal.name,
                            onTap: () => _showEditNameSheet(context),
                          ),
                          _SettingsRow(
                            icon: Icons.lock_outline_rounded,
                            title: 'Password',
                            subtitle: principal.hasPassword
                                ? 'Set — you can sign in with it anytime'
                                : 'Not set — sign-in only works via Google',
                            trailingBadge: principal.hasPassword ? null : 'Unprotected',
                            onTap: () => _showPasswordSheet(context, hasPassword: principal.hasPassword),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const _SecurityGroup(),
                      const SizedBox(height: 20),
                      _SettingsGroup(
                        title: 'Preferences',
                        rows: [
                          _SettingsRow.custom(
                            icon: Icons.brightness_6_rounded,
                            title: 'Appearance',
                            trailing: const _AppearanceControl(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _SettingsGroup(
                        rows: [
                          _SettingsRow(
                            icon: Icons.logout_rounded,
                            title: 'Sign out',
                            destructive: true,
                            onTap: () => context.read<AuthProvider>().logout(),
                          ),
                        ],
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final Color background;
  const _ProfileHero({required this.background});

  @override
  Widget build(BuildContext context) {
    final principal = context.watch<AuthProvider>().principal!;
    final initial = principal.name.isNotEmpty ? principal.name[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 32),
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            principal.name,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            principal.contact,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 14),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              principal.role.name[0].toUpperCase() + principal.role.name.substring(1),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String? title;
  final List<_SettingsRow> rows;
  const _SettingsGroup({this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title!.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.6),
            ),
          ),
        ],
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingBadge;
  final Widget? trailing;
  final bool destructive;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingBadge,
    this.onTap,
    this.destructive = false,
  }) : trailing = null;

  const _SettingsRow.custom({required this.icon, required this.title, required this.trailing})
      : subtitle = null,
        trailingBadge = null,
        destructive = false,
        onTap = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = destructive ? theme.colorScheme.error : theme.colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: destructive ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: theme.textTheme.bodyLarge?.copyWith(color: color)),
      subtitle: subtitle != null ? Text(subtitle!, style: theme.textTheme.bodySmall) : null,
      trailing: trailing ??
          (trailingBadge != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        trailingBadge!,
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                  ],
                )
              : (onTap != null ? Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant) : null)),
      onTap: onTap,
    );
  }
}

class _AppearanceControl extends StatelessWidget {
  const _AppearanceControl();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded)),
        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded)),
        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded)),
      ],
      selected: {theme.mode},
      showSelectedIcon: false,
      onSelectionChanged: (s) => context.read<ThemeProvider>().setMode(s.first),
    );
  }
}

class _SecurityGroup extends StatelessWidget {
  const _SecurityGroup();

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<LockProvider>();
    final rows = <_SettingsRow>[
      if (lock.biometricSupported)
        _SettingsRow.custom(
          icon: Icons.fingerprint_rounded,
          title: 'Biometric unlock',
          trailing: Switch(value: lock.enabled, onChanged: (v) => context.read<LockProvider>().setEnabled(v)),
        ),
      _SettingsRow(
        icon: Icons.pin_outlined,
        title: 'App passcode',
        subtitle: lock.pinSet ? 'On — required to open the app' : 'Off',
        onTap: () => _handlePasscodeTap(context, lock),
      ),
    ];
    return _SettingsGroup(title: 'Security', rows: rows);
  }

  Future<void> _handlePasscodeTap(BuildContext context, LockProvider lock) async {
    if (!lock.pinSet) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PinEntryScreen(flow: PinFlow.create)),
      );
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.password_rounded),
              title: const Text('Change passcode'),
              onTap: () => Navigator.of(context).pop('change'),
            ),
            ListTile(
              leading: Icon(Icons.lock_open_rounded, color: Theme.of(context).colorScheme.error),
              title: Text('Turn off passcode', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () => Navigator.of(context).pop('disable'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'change') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PinEntryScreen(flow: PinFlow.verifyToChange)),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PinEntryScreen(flow: PinFlow.verifyToDisable)),
      );
    }
  }
}

Future<void> _showEditNameSheet(BuildContext context) {
  final principal = context.read<AuthProvider>().principal!;
  final controller = TextEditingController(text: principal.name);
  final formKey = GlobalKey<FormState>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _SheetForm(
      title: 'Display name',
      formKey: formKey,
      fields: [
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Display name'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
      ],
      submitLabel: 'Save',
      onSubmit: () => sheetContext.read<AuthProvider>().updateProfile(name: controller.text.trim()),
    ),
  );
}

Future<void> _showPasswordSheet(BuildContext context, {required bool hasPassword}) {
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _SheetForm(
      title: hasPassword ? 'Change password' : 'Set a password',
      subtitle: hasPassword
          ? null
          : "You currently sign in with Google only. Add a password so you can sign in without it too.",
      formKey: formKey,
      fields: [
        if (hasPassword)
          TextFormField(
            controller: currentController,
            decoration: const InputDecoration(labelText: 'Current password'),
            obscureText: true,
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
        if (hasPassword) const SizedBox(height: 12),
        TextFormField(
          controller: newController,
          decoration: const InputDecoration(labelText: 'New password'),
          obscureText: true,
          validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
        ),
      ],
      submitLabel: hasPassword ? 'Update password' : 'Set password',
      onSubmit: () => sheetContext.read<AuthProvider>().updateProfile(
            password: newController.text,
            currentPassword: hasPassword ? currentController.text : null,
          ),
    ),
  );
}

/// Shared bottom-sheet shell for the small forms above — title, optional
/// helper text, fields, an inline error, and a submit button.
class _SheetForm extends StatefulWidget {
  final String title;
  final String? subtitle;
  final GlobalKey<FormState> formKey;
  final List<Widget> fields;
  final String submitLabel;
  final Future<void> Function() onSubmit;

  const _SheetForm({
    required this.title,
    this.subtitle,
    required this.formKey,
    required this.fields,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  State<_SheetForm> createState() => _SheetFormState();
}

class _SheetFormState extends State<_SheetForm> {
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (!widget.formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit();
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: widget.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 6),
              Text(widget.subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            ...widget.fields,
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.submitLabel),
            ),
          ],
        ),
      ),
    );
  }
}
