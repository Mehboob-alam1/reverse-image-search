import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Result of optional Firebase init (Analytics + FCM). Safe if config is missing.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool ready = false;

  static Future<bool> ensureInitialized() async {
    if (ready) return true;
    if (kIsWeb) return false;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      ready = true;
      return true;
    } on Object catch (e, st) {
      debugPrint('Firebase init skipped: $e');
      debugPrint('$st');
      ready = false;
      return false;
    }
  }
}
