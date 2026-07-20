import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/lock_provider.dart';
import '../widgets/brand_mark.dart';
import 'pin_entry_screen.dart';

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
  final _shakeKey = GlobalKey<ShakeState>();

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
    if (_entered.length >= pinLength) return;
    HapticFeedback.selectionClick();
    setState(() {
      _entered += digit;
      _error = null;
    });
    if (_entered.length == pinLength) {
      final ok = lock.unlockWithPin(_entered);
      if (ok) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
        _shakeKey.currentState?.shake();
        setState(() {
          _error = 'Incorrect passcode';
          _entered = '';
        });
      }
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    HapticFeedback.selectionClick();
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
                    const SizedBox(height: 24),
                    Text('Enter Passcode', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 28),
                    Shake(
                      key: _shakeKey,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(pinLength, (i) => PinDot(filled: i < _entered.length)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 20,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: _error != null ? 1 : 0,
                        child: Text(
                          _error ?? '',
                          style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Keypad(onDigit: _onDigit, onBackspace: _onBackspace),
                    if (lock.enabled) ...[
                      const SizedBox(height: 16),
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
                    const SizedBox(height: 20),
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
