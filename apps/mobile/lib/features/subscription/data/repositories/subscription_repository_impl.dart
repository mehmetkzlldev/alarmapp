import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:alarmy/core/error/exceptions.dart';
import 'package:alarmy/core/error/failures.dart';
import 'package:alarmy/features/subscription/domain/billing_failures.dart';
import 'package:alarmy/features/subscription/data/datasources/iap_datasource.dart';
import 'package:alarmy/features/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:alarmy/features/subscription/domain/entities/plan_entity.dart';
import 'package:alarmy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:alarmy/features/subscription/domain/repositories/subscription_repository.dart';

/// Default timeout for awaiting a purchase result from the IAP stream. The
/// native dialog itself has no fixed duration, but we cap the wait so a stuck
/// purchase doesn't hang the UI forever; the stream still delivers later and the
/// provider re-fetches `/subscriptions/me` on resume.
const Duration _kPurchaseTimeout = Duration(minutes: 5);

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl({
    required SubscriptionRemoteDataSource remote,
    required IapDataSource iap,
  })  : _remote = remote,
        _iap = iap {
    // Ensure the purchase stream listener is active for the life of the repo.
    _iap.initialize();
  }

  final SubscriptionRemoteDataSource _remote;
  final IapDataSource _iap;

  @override
  Future<Either<Failure, SubscriptionEntity>> getMySubscription() async {
    try {
      final model = await _remote.getMySubscription();
      return Right(model.toEntity());
    } on PremiumRequiredException catch (e) {
      return Left(PremiumRequiredFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PlanEntity>>> getPlans() async {
    try {
      // 1. Marketing catalog from our backend (ordering, copy, "popular").
      final planModels = await _remote.getPlans();

      // 2. Live, localized pricing from the store. If the store is unavailable
      //    (e.g. emulator, no Play Services) we degrade gracefully to backend
      //    fallback labels rather than failing the whole screen.
      Map<String, ProductDetails> products = const {};
      try {
        if (await _iap.isStoreAvailable()) {
          products = await _iap.queryProducts();
        }
      } on Exception {
        products = const {};
      }

      final plans = planModels.map((m) {
        final pd = products[m.productId];
        return m.toEntity(
          storePriceLabel: pd?.price,
          rawPrice: pd?.rawPrice,
          currencyCode: pd?.currencyCode,
        );
      }).toList(growable: false);

      return Right(plans);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity>> buyPlan(PlanEntity plan) async {
    if (plan.isFree) {
      return const Left(
        ValidationFailure(message: 'The free plan cannot be purchased.'),
      );
    }
    try {
      // Listen BEFORE launching the flow so we don't miss a fast result.
      final resultFuture = _firstResultFor(plan.productId);
      await _iap.buy(plan.productId);
      final result = await resultFuture.timeout(_kPurchaseTimeout);

      switch (result) {
        case IapPurchaseSuccess(:final subscription):
          return Right(subscription.toEntity());
        case IapPurchaseCanceled():
          return const Left(PurchaseCancelledFailure());
        case IapPurchaseError(:final message):
          return Left(BillingFailure(message: message));
      }
    } on TimeoutException {
      // The purchase may still complete later; the stream listener will pick it
      // up and the provider re-syncs on next `/subscriptions/me`.
      return const Left(
        BillingFailure(
          message:
              'The purchase is taking longer than expected. It will be applied automatically once it completes.',
        ),
      );
    } on ServerException catch (e) {
      return Left(BillingFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(BillingFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity>> restorePurchases() async {
    try {
      // Kick off the native restore; results stream back as validated items.
      final resultFuture = _firstAnyResult();
      await _iap.restore();
      final result = await resultFuture.timeout(_kPurchaseTimeout);

      switch (result) {
        case IapPurchaseSuccess(:final subscription):
          return Right(subscription.toEntity());
        case IapPurchaseCanceled():
          // Nothing to restore (or user dismissed): fall back to server truth.
          return getMySubscription();
        case IapPurchaseError(:final message):
          return Left(BillingFailure(message: message));
      }
    } on TimeoutException {
      // No restorable purchase produced a validated result — return whatever
      // the backend currently knows (likely free).
      return getMySubscription();
    } on ServerException catch (e) {
      return Left(BillingFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(BillingFailure(message: e.toString()));
    }
  }

  /// Resolves with the first stream result that pertains to [productId] (or any
  /// terminal cancel/error, which are not product-specific).
  Future<IapPurchaseResult> _firstResultFor(String productId) {
    return _iap.validatedPurchaseStream.firstWhere((r) {
      return switch (r) {
        // Match the success only when it's for the product we just bought.
        IapPurchaseSuccess(productId: final pid) => pid == productId,
        IapPurchaseCanceled() => true,
        IapPurchaseError() => true,
      };
    });
  }

  /// Resolves with the first restore-relevant result (any success/cancel/error).
  Future<IapPurchaseResult> _firstAnyResult() {
    return _iap.validatedPurchaseStream.first;
  }
}
