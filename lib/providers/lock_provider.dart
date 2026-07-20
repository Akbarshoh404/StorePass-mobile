import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App re-lock on backgrounding: biometric (Face ID/Touch ID/fingerprint),
/// a local PIN passcode, or both. Either one being set arms the lock — worth
/// it since the app displays wallet balances. Off by default.
class LockProvider extends ChangeNotifier {
  static const _biometricPrefsKey = 'biometric_lock_enabled';
  static const _pinHashPrefsKey = 'app_pin_hash';
  final LocalAuthentication _auth = LocalAuthentication();

  bool enabled = false; // biometric
  bool locked = false;
  bool biometricSupported = false;
  String? _pinHash;

  bool get pinSet => _pinHash != null;
  bool get lockActive => enabled || pinSet;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool(_biometricPrefsKey) ?? false;
    _pinHash = prefs.getString(_pinHashPrefsKey);
    try {
      biometricSupported = await _auth.isDeviceSupported();
    } catch (_) {
      biometricSupported = false;
    }
    if (!biometricSupported) enabled = false;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    enabled = value && biometricSupported;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricPrefsKey, enabled);
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    _pinHash = _hash(pin);
    await prefs.setString(_pinHashPrefsKey, _pinHash!);
    notifyListeners();
  }

  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    _pinHash = null;
    await prefs.remove(_pinHashPrefsKey);
    notifyListeners();
  }

  bool verifyPin(String pin) => _pinHash != null && _hash(pin) == _pinHash;

  String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();

  void lockIfEnabled() {
    if (lockActive && !locked) {
      locked = true;
      notifyListeners();
    }
  }

  Future<bool> unlockWithBiometrics() async {
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

  bool unlockWithPin(String pin) {
    if (!verifyPin(pin)) return false;
    locked = false;
    notifyListeners();
    return true;
  }
}
