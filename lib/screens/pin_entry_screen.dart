import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/lock_provider.dart';

enum PinFlow { create, verifyToDisable, verifyToChange }

const _pinLength = 6;

/// A single Apple-Passcode-style flow: numeric dot progress + a 3x4 keypad.
/// [PinFlow.create] asks for a new passcode twice (create, then confirm).
/// [PinFlow.verifyToDisable]/[PinFlow.verifyToChange] ask for the existing
/// one before disabling it or handing off to a fresh [PinFlow.create].
class PinEntryScreen extends StatefulWidget {
  final PinFlow flow;
  const PinEntryScreen({super.key, required this.flow});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String _entered = '';
  String? _firstEntry; // held during create's confirm step
  String? _error;
  bool _confirming = false;

  String get _title {
    if (widget.flow != PinFlow.create) return 'Enter your passcode';
    return _confirming ? 'Confirm passcode' : 'Set a passcode';
  }

  void _onDigit(String digit) {
    if (_entered.length >= _pinLength) return;
    setState(() {
      _entered += digit;
      _error = null;
    });
    if (_entered.length == _pinLength) _submit();
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _submit() async {
    final lock = context.read<LockProvider>();

    if (widget.flow == PinFlow.create) {
      if (!_confirming) {
        setState(() {
          _firstEntry = _entered;
          _entered = '';
          _confirming = true;
        });
        return;
      }
      if (_entered != _firstEntry) {
        setState(() {
          _error = "Passcodes didn't match — try again";
          _entered = '';
          _firstEntry = null;
          _confirming = false;
        });
        return;
      }
      await lock.setPin(_entered);
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    // verifyToDisable / verifyToChange
    if (!lock.verifyPin(_entered)) {
      setState(() {
        _error = 'Incorrect passcode';
        _entered = '';
      });
      return;
    }
    if (widget.flow == PinFlow.verifyToDisable) {
      await lock.clearPin();
      if (mounted) Navigator.of(context).pop(true);
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PinEntryScreen(flow: PinFlow.create)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Text(_title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (i) {
                final filled = i < _entered.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
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
            const SizedBox(height: 16),
            SizedBox(
              height: 20,
              child: _error != null
                  ? Text(_error!, style: TextStyle(color: theme.colorScheme.error))
                  : null,
            ),
            const Spacer(),
            _Keypad(onDigit: _onDigit, onBackspace: _onBackspace),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  const _Keypad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows
          .map(
            (row) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                if (key.isEmpty) return const SizedBox(width: 76, height: 76);
                return _KeypadButton(
                  label: key,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (key == '⌫') {
                      onBackspace();
                    } else {
                      onDigit(key);
                    }
                  },
                );
              }).toList(),
            ),
          )
          .toList(),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _KeypadButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 64,
            height: 64,
            child: Center(
              child: label == '⌫'
                  ? Icon(Icons.backspace_outlined, color: theme.colorScheme.onSurfaceVariant)
                  : Text(label, style: theme.textTheme.headlineSmall),
            ),
          ),
        ),
      ),
    );
  }
}
