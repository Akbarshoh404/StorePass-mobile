import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/lock_provider.dart';

enum PinFlow { create, verifyToDisable, verifyToChange }

const pinLength = 4;

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
  final _shakeKey = GlobalKey<ShakeState>();

  String get _title {
    if (widget.flow != PinFlow.create) return 'Enter Passcode';
    return _confirming ? 'Confirm Passcode' : 'Set a Passcode';
  }

  String? get _subtitle {
    if (widget.flow == PinFlow.verifyToChange && _error == null) return 'Enter your current passcode to continue';
    if (widget.flow == PinFlow.verifyToDisable && _error == null) return 'Enter your passcode to turn it off';
    if (widget.flow == PinFlow.create && !_confirming) return 'This unlocks StorePass on this device';
    return null;
  }

  void _onDigit(String digit) {
    if (_entered.length >= pinLength) return;
    HapticFeedback.selectionClick();
    setState(() {
      _entered += digit;
      _error = null;
    });
    if (_entered.length == pinLength) _submit();
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _fail(String message) {
    HapticFeedback.heavyImpact();
    _shakeKey.currentState?.shake();
    setState(() {
      _error = message;
      _entered = '';
    });
  }

  Future<void> _submit() async {
    final lock = context.read<LockProvider>();
    // Tiny pause so the last dot is visibly filled before the sheet reacts —
    // committing instantly reads as the input never registered.
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

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
        _fail("Passcodes didn't match — try again");
        setState(() {
          _firstEntry = null;
          _confirming = false;
        });
        return;
      }
      HapticFeedback.mediumImpact();
      await lock.setPin(_entered);
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    // verifyToDisable / verifyToChange
    if (!lock.verifyPin(_entered)) {
      _fail('Incorrect passcode');
      return;
    }
    HapticFeedback.mediumImpact();
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
      appBar: AppBar(leading: const BackButton(), backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                _title,
                key: ValueKey(_title),
                style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: -0.3),
              ),
            ),
            if (_subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                _subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 36),
            Shake(
              key: _shakeKey,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pinLength, (i) => PinDot(filled: i < _entered.length)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 22,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _error != null ? 1 : 0,
                child: Text(
                  _error ?? '',
                  style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const Spacer(flex: 3),
            Keypad(onDigit: _onDigit, onBackspace: _onBackspace),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class PinDot extends StatelessWidget {
  final bool filled;
  const PinDot({super.key, required this.filled});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9),
      child: SizedBox(
        width: 20,
        height: 20,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Always-visible ring — shows all four target slots up front.
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.outline, width: 1.5),
              ),
            ),
            AnimatedScale(
              scale: filled ? 1.0 : 0.001,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shakes its child horizontally — the standard "wrong passcode" tell,
/// distinct from a static red error label alone (feedback should be felt,
/// not just read).
class Shake extends StatefulWidget {
  final Widget child;
  const Shake({super.key, required this.child});

  @override
  State<Shake> createState() => ShakeState();
}

class ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  late final Animation<double> _offset = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 10.0, end: -6.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  void shake() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) => Transform.translate(offset: Offset(_offset.value, 0), child: child),
      child: widget.child,
    );
  }
}

class Keypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  const Keypad({super.key, required this.onDigit, required this.onBackspace});

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
                if (key.isEmpty) return const SizedBox(width: 88, height: 88);
                return _KeypadButton(label: key, onTap: () => key == '⌫' ? onBackspace() : onDigit(key));
              }).toList(),
            ),
          )
          .toList(),
    );
  }
}

/// Presses respond on pointer-down (instant scale-down highlight), not on
/// release — waiting for the tap to fully commit before showing feedback
/// reads as latency, per the Apple fluid-interfaces response principle.
class _KeypadButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _KeypadButton({required this.label, required this.onTap});

  @override
  State<_KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<_KeypadButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(6),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _pressed ? theme.colorScheme.surfaceContainerHigh : theme.colorScheme.surfaceContainer,
            ),
            alignment: Alignment.center,
            child: widget.label == '⌫'
                ? Icon(Icons.backspace_outlined, color: theme.colorScheme.onSurfaceVariant, size: 24)
                : Text(
                    widget.label,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w500, fontSize: 30),
                  ),
          ),
        ),
      ),
    );
  }
}
