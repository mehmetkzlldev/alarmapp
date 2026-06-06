// PLACEHOLDER — replace by running the FlutterFire CLI:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// That command generates the real DefaultFirebaseOptions for each platform from
// your Firebase project. This stub keeps the app compiling; `main.dart` guards
// Firebase initialization so a missing/placeholder config degrades gracefully
// in development instead of crashing on launch.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  /// Returns the options for the current platform. Throws until you run
  /// `flutterfire configure`, which overwrites this file with real values.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web is not configured. Run flutterfire configure.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'firebase_options.dart is a placeholder. '
          'Run `flutterfire configure` to generate real options.',
        );
      default:
        throw UnsupportedError(
          'Unsupported platform: $defaultTargetPlatform',
        );
    }
  }
}
