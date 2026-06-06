import 'package:dartz/dartz.dart';

import 'package:alarmy/core/error/failures.dart';
import 'package:alarmy/features/subscription/domain/entities/plan_entity.dart';
import 'package:alarmy/features/subscription/domain/entities/subscription_entity.dart';

/// Abstraction over everything subscription-related: reading the current
/// entitlement, listing plans, driving the native purchase flow, and restoring
/// past purchases.
///
/// The implementation coordinates two data sources:
///   - a *remote* one (Dio) talking to our backend, and
///   - an *IAP* one (`in_app_purchase`) talking to the platform billing client.
///
/// Crucially, a successful native purchase is NOT trusted on its own: the
/// store receipt / purchase token is forwarded to `POST /subscriptions/validate`
/// and the backend's verdict becomes the authoritative [SubscriptionEntity].
abstract interface class SubscriptionRepository {
  /// Fetches the current user's subscription from the backend
  /// (`GET /subscriptions/me`).
  Future<Either<Failure, SubscriptionEntity>> getMySubscription();

  /// Lists purchasable plans, merging backend marketing data with live,
  /// localized store pricing (`GET /subscriptions/plans` + store query).
  Future<Either<Failure, List<PlanEntity>>> getPlans();

  /// Launches the native purchase flow for [plan] and, on success, validates
  /// the receipt server-side. Returns the freshly-validated subscription.
  ///
  /// May complete with a [PurchaseCancelledFailure] if the user backs out — the
  /// UI should treat that as a no-op rather than an error.
  Future<Either<Failure, SubscriptionEntity>> buyPlan(PlanEntity plan);

  /// Restores previously-purchased entitlements (required by App Store review).
  /// Re-validates any restored receipts server-side and returns the resulting
  /// subscription state.
  Future<Either<Failure, SubscriptionEntity>> restorePurchases();
}
