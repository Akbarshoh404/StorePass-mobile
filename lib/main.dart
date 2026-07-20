import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app.dart';
import 'config/google_sign_in_config.dart';
import 'firebase_options.dart';
import 'utils/error_logging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initErrorLogging();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await GoogleSignIn.instance.initialize(serverClientId: googleServerClientId);
  } catch (e) {
    // Google sign-in just won't be offered on this run (e.g. no native
    // Firebase config for this platform/target) — everything else still works.
    debugPrint('Firebase/Google Sign-In init skipped: $e');
  }
  runApp(const StorePassApp());
}
