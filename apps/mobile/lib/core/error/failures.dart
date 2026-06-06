import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
///
/// Failures are *expected* error states that flow back to the presentation
/// layer (as opposed to exceptions, which are thrown by data sources and
/// translated into Failures inside repository implementations).
abstract class Failure extends Equatable {
  const Failure({required this.message});

  /// Human-readable, presentation-safe message.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// The backend returned a non-2xx response or the request itself failed.
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    this.statusCode,
  });

  /// HTTP status code, when available.
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

/// No network connectivity, or a connection/read timeout.
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Showing cached data.',
  });
}

/// Local persistence (cache) read/write failed.
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Failed to read local data.',
  });
}

/// The user hit a free-tier limit or accessed a premium-gated resource.
class PremiumRequiredFailure extends Failure {
  const PremiumRequiredFailure({
    super.message = 'This feature requires an active subscription.',
  });
}

/// Input validation failed before a request was even attempted.
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

/// Authentication failed irrecoverably (refresh exhausted). The presentation
/// layer should route the user back to /login.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'Session expired. Please sign in again.',
  });
}

/// Failure raised by the native alarm scheduler bridge (platform channel).
class SchedulerFailure extends Failure {
  const SchedulerFailure({
    super.message = 'Failed to schedule the alarm on this device.',
  });
}
