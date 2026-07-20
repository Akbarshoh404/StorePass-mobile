import 'package:flutter/foundation.dart';

/// Captures uncaught Flutter framework errors and uncaught async/platform
/// errors in one place. No remote crash reporting is wired up yet — there's
/// no Sentry/Firebase project configured for this app. Swap the body of
/// [_report] for `Sentry.captureException` / `FirebaseCrashlytics.instance
/// .recordError` once one exists; every crash already flows through here.
void initErrorLogging() {
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    _report('Flutter error', details.exception, details.stack);
    previousOnError?.call(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _report('Uncaught async error', error, stack);
    return true;
  };
}

void _report(String label, Object error, StackTrace? stack) {
  debugPrint('[$label] $error');
  if (stack != null) debugPrint(stack.toString());
}
