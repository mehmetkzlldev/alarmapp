import 'package:alarmy/core/error/failures.dart';

/// Subscription-specific [Failure]s.
///
/// These live in the feature (rather than core/error/failures.dart) because
/// they are only meaningful to the billing flow and keep the shared failure set
/// lean. They still extend the shared [Failure] base so they flow through the
/// same `Either<Failure, T>` plumbing as everything else.

/// A store/billing error originating from Google Play or the App Store, or from
/// server-side receipt validation.
class BillingFailure extends Failure {
  const BillingFailure({
    required super.message,
    this.code,
  });

  /// Optional platform error code (e.g. StoreKit/BillingClient code).
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

/// The user dismissed the native purchase dialog. Treated as a quiet no-op by
/// the UI rather than a hard error.
class PurchaseCancelledFailure extends Failure {
  const PurchaseCancelledFailure({
    super.message = 'Purchase cancelled.',
  });
}
