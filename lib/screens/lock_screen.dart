import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/lock_provider.dart';
import '../widgets/brand_mark.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _authenticating = false;
  bool _usingPin = false;
  String _entered = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    final lock = context.read<LockProvider>();
    // Prefer biometrics up front when available; a set PIN not enabled
    // alongside it is the fallback shown immediately instead.
    _usingPin = !lock.enabled && lock.pinSet;
    if (lock.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometrics());
    }
  }

  Future<void> _tryBiometrics() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    final ok = await context.read<LockProvider>().unlockWithBiometrics();
    if (mounted) setState(() => _authenticating = false);
    if (!ok && mounted && context.read<LockProvider>().pinSet) {
      setState(() => _usingPin = true);
    }
  }

  void _onDigit(String digit) {
    final lock = context.read<LockProvider>();
    if (_entered.length >= 6) return;
    setState(() {
      _entered += digit;
      _error = null;
    });
    if (_entered.length == 6) {
      final ok = lock.unlockWithPin(_entered);
      if (!ok) {
        setState(() {
          _error = 'Incorrect passcode';
          _entered = '';
        });
      }
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<LockProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: _usingPin && lock.pinSet
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandMark(),
                    const SizedBox(height: 20),
                    Text('Enter your passcode', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (i) {
                        final filled = i < _entered.length;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled ? theme.colorScheme.onSurface : Colors.transparent,
                            border: Border.all(color: theme.colorScheme.outline, width: 1.5),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 20,
                      child: _error != null
                          ? Text(_error!, style: TextStyle(color: theme.colorScheme.error))
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _MiniKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
                    if (lock.enabled) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _usingPin = false);
                          _tryBiometrics();
                        },
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: const Text('Use biometrics instead'),
                      ),
                    ],
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandMark(),
                    const SizedBox(height: 24),
                    Text('StorePass is locked', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _authenticating ? null : _tryBiometrics,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: Text(_authenticating ? 'Verifying…' : 'Unlock'),
                    ),
                    if (lock.pinSet) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _usingPin = true),
                        child: const Text('Use passcode instead'),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _MiniKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  const _MiniKeypad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows
          .map(
            (row) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                if (key.isEmpty) return const SizedBox(width: 60, height: 60);
                return Padding(
                  padding: const EdgeInsets.all(4),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        key == '⌫' ? onBackspace() : onDigit(key);
                      },
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Center(
                          child: key == '⌫'
                              ? Icon(Icons.backspace_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant)
                              : Text(key, style: theme.textTheme.titleLarge),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          )
          .toList(),
    );
  }
}
