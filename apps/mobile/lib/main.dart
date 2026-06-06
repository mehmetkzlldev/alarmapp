import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarmy/app.dart';
import 'package:alarmy/bootstrap.dart';
import 'package:alarmy/firebase_options.dart';

/// App entry point.
///
/// Order matters:
///   1. Ensure the Flutter binding before any platform channel use.
///   2. Initialize Firebase (guarded — a placeholder config won't hard-crash
///      dev builds; production must run `flutterfire configure`).
///   3. Route all uncaught Flutter + platform errors to Crashlytics.
///   4. Bootstrap dependency injection (get_it/injectable).
///   5. runApp inside a [ProviderScope] (Riverpod root).
Future<void> main() async {
  // runZonedGuarded captures async errors that escape the Flutter framework.
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await _initFirebase();

    // Initialize DI and collect feature provider overrides (Isar, DioClient
    // seam, etc). Centralized in [bootstrap] so tests can reuse it.
    final result = await bootstrap();

    runApp(
      ProviderScope(
        overrides: result.overrides,
        child: const AlarmyApp(),
      ),
    );
  }, (error, stack) {
    // Last-resort handler for uncaught async errors.
    if (_crashlyticsReady) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } else if (kDebugMode) {
      // ignore: avoid_print
      print('Uncaught (no crashlytics): $error\n$stack');
    }
  });
}

bool _crashlyticsReady = false;

/// Initializes Firebase and wires Crashlytics error collection. Tolerates a
/// placeholder [DefaultFirebaseOptions] in development so the app still boots.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Disable collection in debug to avoid noisy/duplicate reports while
    // developing; always on in release.
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(kReleaseMode);

    // Route Flutter framework errors into Crashlytics.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Route low-level platform-dispatcher errors too.
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    _crashlyticsReady = true;
  } catch (e, st) {
    // Placeholder config / offline first run: don't block app launch.
    _crashlyticsReady = false;
    if (kDebugMode) {
      // ignore: avoid_print
      print(
        'Firebase init skipped (run `flutterfire configure`): $e\n$st',
      );
    }
  }
}
