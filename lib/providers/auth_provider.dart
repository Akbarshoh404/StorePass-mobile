import 'package:flutter/foundation.dart';

import '../models/principal.dart';
import '../services/api_client.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// Tracks the current logged-in identity (or lack of one). [restore] is
/// called once at startup to silently re-check the persisted session cookie
/// against `/users/me`, so a returning user skips the login screen.
class AuthProvider extends ChangeNotifier {
  final ApiClient _api;
  AuthProvider(this._api) {
    _api.onUnauthorized = _handleUnauthorized;
  }

  AuthStatus status = AuthStatus.unknown;
  Principal? principal;

  void _handleUnauthorized() {
    // A 401 while already signed out (e.g. a failed login attempt) is just
    // the normal "wrong credentials" case — only an expired session while
    // we thought we were signed in should force the app back to login.
    if (status == AuthStatus.signedIn) {
      principal = null;
      status = AuthStatus.signedOut;
      notifyListeners();
    }
  }

  Future<void> restore() async {
    try {
      principal = await _api.me();
      status = AuthStatus.signedIn;
    } catch (_) {
      principal = null;
      status = AuthStatus.signedOut;
    }
    notifyListeners();
  }

  Future<void> login({required String contact, required String password}) async {
    principal = await _api.login(contact: contact, password: password);
    status = AuthStatus.signedIn;
    notifyListeners();
  }

  Future<void> register({required String name, required String contact, required String password}) async {
    principal = await _api.register(name: name, contact: contact, password: password);
    status = AuthStatus.signedIn;
    notifyListeners();
  }

  Future<void> loginWithGoogle(String idToken) async {
    principal = await _api.loginWithGoogle(idToken);
    status = AuthStatus.signedIn;
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? password}) async {
    principal = await _api.updateMe(name: name, password: password);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } finally {
      principal = null;
      status = AuthStatus.signedOut;
      notifyListeners();
    }
  }
}
