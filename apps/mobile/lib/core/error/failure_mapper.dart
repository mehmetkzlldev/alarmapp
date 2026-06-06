import 'package:alarmy/core/error/exceptions.dart';
import 'package:alarmy/core/error/failures.dart';

/// Translates low-level [Exception]s thrown by data sources into
/// presentation-safe [Failure]s.
///
/// Centralizing this keeps every repository's `catch` blocks identical and
/// guarantees consistent mapping (e.g. every 402 becomes a
/// [PremiumRequiredFailure] everywhere).
Failure mapExceptionToFailure(Object error) {
  return switch (error) {
    UnauthorizedException(:final message) => UnauthorizedFailure(message: message),
    PremiumRequiredException(:final message) =>
      PremiumRequiredFailure(message: message),
    ServerException(:final message, :final statusCode) =>
      ServerFailure(message: message, statusCode: statusCode),
    NetworkException(:final message) => NetworkFailure(message: message),
    CacheException(:final message) => CacheFailure(message: message),
    _ => const ServerFailure(message: 'Something went wrong. Please try again.'),
  };
}
