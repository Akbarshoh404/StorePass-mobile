/// Holds the StorePass backend base URL as a single runtime variable.
///
/// Resolution order:
/// 1. `--dart-define=API_BASE_URL=...` passed at build/run time — for
///    pointing a local dev build at a local server.
/// 2. The deployed production backend — this app talks to one real backend
///    by default, not a local dev server, so it works out of the box on a
///    real device with no manual setup and no in-app override to go stale.
library;

import 'package:flutter/foundation.dart';

class ApiConfig extends ChangeNotifier {
  static const _dartDefine = String.fromEnvironment('API_BASE_URL');
  static const _productionUrl = 'https://storepass.backend.akbarshoh-dev.uz';

  final String baseUrl = _dartDefine.isNotEmpty ? _dartDefine : _productionUrl;
}
