import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opt-in biometric re-lock: when enabled, backgrounding the app arms a lock
/// that requires Face ID/Touch ID/fingerprint (or device PIN as a fallback)
/// before the UI is shown again — worth it since the app displays wallet
/// balances. Off by default, and only offerable on devices that support it.
class LockProvider extends ChangeNotifier {
  static const _prefsKey = 'biometric_lock_enabled';
  final LocalAuthentication _auth = LocalAuthentication();

  bool enabled = false;
  bool locked = false;
  bool supported = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool(_prefsKey) ?? false;
    try {
      supported = await _auth.isDeviceSupported();
    } catch (_) {
      supported = false;
    }
    if (!supported) enabled = false;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    enabled = value && supported;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
  }

  void lockIfEnabled() {
    if (enabled && !locked) {
      locked = true;
      notifyListeners();
    }
  }

  Future<bool> unlock() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock StorePass',
        persistAcrossBackgrounding: true,
      );
      if (ok) {
        locked = false;
        notifyListeners();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }
}
