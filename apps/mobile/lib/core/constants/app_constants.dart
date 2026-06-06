import 'package:alarmy/core/constants/api_constants.dart';

/// App-wide business constants and build-time configuration.
///
/// Network/base-URL configuration lives in [ApiConstants] (the single source of
/// truth). This file holds product/business rules and convenience accessors so
/// features don't re-derive them. Never hardcode secrets here — the app only
/// knows the backend base URL; all privileged keys (e.g. Gemini) stay
/// server-side.
class AppConstants {
  AppConstants._();

  /// Fully-qualified API root, e.g. `https://api.example.com/api/v1`.
  /// Delegates to [ApiConstants] so there is exactly one base-URL definition.
  static String get apiUrl => ApiConstants.basePath;

  /// Toggle verbose network logging (off in release builds by default).
  static const bool enableNetworkLogs = bool.fromEnvironment(
    'ENABLE_NETWORK_LOGS',
    defaultValue: false,
  );

  // --- Network timeouts -----------------------------------------------------
  // Mirror [ApiConstants] for connect/receive (single source of truth) and add
  // a send timeout used for uploads (e.g. presigned S3 PUTs).
  static Duration get connectTimeout => ApiConstants.connectTimeout;
  static Duration get receiveTimeout => ApiConstants.receiveTimeout;
  static const Duration sendTimeout = Duration(seconds: 20);

  // --- Business rules (mirrors backend) ------------------------------------
  /// Number of alarms a free (non-premium) user may keep. Beyond this the
  /// backend returns a premium-required error and the app surfaces the paywall.
  static const int freeAlarmLimit = 3;

  /// Object-detection targets the backend can verify. Keep in sync with the
  /// backend's supported list.
  static const List<String> objectDetectionTargets = <String>[
    'toothbrush',
    'sink',
    'coffee mug',
    'keys',
    'shoes',
    'laptop',
  ];
}
