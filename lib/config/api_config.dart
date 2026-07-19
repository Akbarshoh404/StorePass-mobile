import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the StorePass backend base URL as a single runtime variable.
///
/// Resolution order:
/// 1. A URL saved earlier via [setBaseUrl] (persisted in SharedPreferences) —
///    lets the app point at a different backend without a rebuild (handy
///    since "localhost" means something different on an emulator vs. a
///    physical device on the same Wi-Fi as the dev machine).
/// 2. `--dart-define=API_BASE_URL=...` passed at build/run time.
/// 3. A sensible per-platform default matching the backend's dev server
///    (`uvicorn main:app --reload` on port 8000).
class ApiConfig extends ChangeNotifier {
  static const _prefsKey = 'api_base_url';
  static const _dartDefine = String.fromEnvironment('API_BASE_URL');

  String _baseUrl = _defaultBaseUrl();
  bool _loaded = false;

  String get baseUrl => _baseUrl;
  bool get loaded => _loaded;

  static String _defaultBaseUrl() {
    if (_dartDefine.isNotEmpty) return _dartDefine;
    if (!kIsWeb && Platform.isAndroid) {
      // 10.0.2.2 is the Android emulator's alias for the host machine's localhost.
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved.isNotEmpty) {
      _baseUrl = saved;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setBaseUrl(String url) async {
    final trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.isEmpty || trimmed == _baseUrl) return;
    _baseUrl = trimmed;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, trimmed);
  }

  Future<void> resetToDefault() async {
    _baseUrl = _defaultBaseUrl();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
