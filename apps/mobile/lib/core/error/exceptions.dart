/// Exceptions are thrown by data sources (remote + local) and caught by
/// repository implementations, which convert them into [Failure]s.

/// Thrown when the backend responds with a non-2xx status.
///
/// Carries the optional fields from the backend error envelope
/// `{ statusCode, message, error, path, timestamp }`.
class ServerException implements Exception {
  ServerException({required this.message, this.statusCode, this.error, this.path});

  final String message;
  final int? statusCode;

  /// Short error code from the envelope, e.g. "Unauthorized".
  final String? error;

  /// Request path the backend reported.
  final String? path;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Thrown when there is no connectivity or a timeout occurs.
class NetworkException implements Exception {
  NetworkException([this.message = 'Network unavailable']);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown for a 401 that could NOT be recovered via token refresh.
///
/// The [RefreshInterceptor] only lets this surface after a refresh attempt has
/// failed; callers should treat it as "session expired, force re-login".
class UnauthorizedException implements Exception {
  UnauthorizedException([this.message = 'Session expired. Please sign in again.']);

  final String message;

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Thrown by the local data source on cache read/write errors.
class CacheException implements Exception {
  CacheException([this.message = 'Cache failure']);

  final String message;

  @override
  String toString() => 'CacheException: $message';
}

/// Thrown when the user must upgrade (HTTP 402 / PremiumGuard rejection).
class PremiumRequiredException implements Exception {
  PremiumRequiredException([this.message = 'Premium subscription required']);

  final String message;

  @override
  String toString() => 'PremiumRequiredException: $message';
}
