/// Network / base-URL configuration — the single source of truth.
///
/// The base URL is provided at build time via
/// `--dart-define=API_BASE_URL=...`. Defaults to the local Docker backend so
/// `flutter run` works out of the box during development.
///
/// NEVER put secrets here — the client only ever knows the public backend base
/// URL; all privileged keys (e.g. Gemini) stay server-side.
class ApiConstants {
  ApiConstants._();

  /// Fully-qualified API root, e.g. `https://api.example.com/api/v1`.
  ///
  /// Web / desktop dev: the backend is reachable at `localhost:3000`.
  /// Android emulator: pass `--dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1`.
  static const String basePath = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  /// Max time to establish a connection. Generous so a cold-starting cloud
  /// backend (a free-tier host waking from idle) doesn't time out on first hit.
  static const Duration connectTimeout = Duration(seconds: 60);

  /// Max time to receive a response (covers cold starts + Gemini vision calls).
  static const Duration receiveTimeout = Duration(seconds: 60);

  // --- Auth endpoint paths (relative to [basePath]) ------------------------
  /// Token rotation endpoint used by the refresh interceptor.
  static const String refresh = '/auth/refresh';
}
