import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarmy/core/di/injection.dart';
import 'package:alarmy/core/di/provider_overrides.dart';

/// Result of app bootstrap: the Riverpod overrides to hand to [ProviderScope].
class BootstrapResult {
  const BootstrapResult({required this.overrides});

  final List<Override> overrides;
}

/// Runs all pre-`runApp` initialization that must complete before the first
/// frame: dependency injection and feature provider overrides (Isar, the
/// configured DioClient seam, etc).
///
/// Firebase is initialized separately in `main.dart` so its error-handler
/// wiring can wrap the entire zone. Keeping bootstrap pure (no Firebase) makes
/// it reusable in integration tests.
Future<BootstrapResult> bootstrap() async {
  await configureDependencies(
    environment: kReleaseMode ? Env.prod : Env.dev,
  );

  final overrides = await buildProviderOverrides();
  return BootstrapResult(overrides: overrides);
}
