import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:alarmy/core/network/network_providers.dart';
import 'package:alarmy/core/usecase/usecase.dart';
import 'package:alarmy/features/subscription/data/datasources/iap_datasource.dart';
import 'package:alarmy/features/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:alarmy/features/subscription/data/repositories/subscription_repository_impl.dart';
import 'package:alarmy/features/subscription/domain/billing_failures.dart';
import 'package:alarmy/features/subscription/domain/entities/plan_entity.dart';
import 'package:alarmy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:alarmy/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:alarmy/features/subscription/domain/usecases/buy_plan.dart';
import 'package:alarmy/features/subscription/domain/usecases/get_my_subscription.dart';
import 'package:alarmy/features/subscription/domain/usecases/get_plans.dart';
import 'package:alarmy/features/subscription/domain/usecases/restore_purchases.dart';

// ---------------------------------------------------------------------------
// Dependency wiring (plain providers).
//
// These are intentionally hand-wired (not get_it) so the subscription feature
// is self-contained and testable in isolation via provider overrides. They
// still reuse the app's single configured DioClient via [dioClientProvider].
// ---------------------------------------------------------------------------

/// The platform in-app-purchase singleton.
final inAppPurchaseProvider = Provider<InAppPurchase>((ref) {
  return InAppPurchase.instance;
});

/// Backend (Dio) data source.
final subscriptionRemoteDataSourceProvider =
    Provider<SubscriptionRemoteDataSource>((ref) {
  return SubscriptionRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

/// Store (in_app_purchase) data source. Disposed with the provider container so
/// the purchase-stream subscription is cleaned up.
final iapDataSourceProvider = Provider<IapDataSource>((ref) {
  final ds = IapDataSourceImpl(
    inAppPurchase: ref.watch(inAppPurchaseProvider),
    remote: ref.watch(subscriptionRemoteDataSourceProvider),
  );
  ref.onDispose(ds.dispose);
  return ds;
});

/// Repository combining the two data sources.
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepositoryImpl(
    remote: ref.watch(subscriptionRemoteDataSourceProvider),
    iap: ref.watch(iapDataSourceProvider),
  );
});

// Use-case providers.
final getMySubscriptionProvider = Provider<GetMySubscription>(
  (ref) => GetMySubscription(ref.watch(subscriptionRepositoryProvider)),
);
final getPlansProvider = Provider<GetPlans>(
  (ref) => GetPlans(ref.watch(subscriptionRepositoryProvider)),
);
final buyPlanProvider = Provider<BuyPlan>(
  (ref) => BuyPlan(ref.watch(subscriptionRepositoryProvider)),
);
final restorePurchasesProvider = Provider<RestorePurchases>(
  (ref) => RestorePurchases(ref.watch(subscriptionRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// View state for the subscription / paywall surface.
class SubscriptionState {
  const SubscriptionState({
    required this.subscription,
    this.plans = const <PlanEntity>[],
    this.isPurchasing = false,
    this.isRestoring = false,
    this.lastError,
    this.lastMessage,
  });

  /// The current entitlement (source of truth for [isPremium]).
  final SubscriptionEntity subscription;

  /// Plans shown on the paywall (free + premium tiers).
  final List<PlanEntity> plans;

  /// A purchase flow is in progress (buy button shows a spinner).
  final bool isPurchasing;

  /// A restore flow is in progress.
  final bool isRestoring;

  /// Transient, user-presentable error (e.g. billing failure) for a snackbar.
  final String? lastError;

  /// Transient success message (e.g. "Welcome to Premium!").
  final String? lastMessage;

  bool get isPremium => subscription.isPremium;

  SubscriptionState copyWith({
    SubscriptionEntity? subscription,
    List<PlanEntity>? plans,
    bool? isPurchasing,
    bool? isRestoring,
    String? lastError,
    String? lastMessage,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return SubscriptionState(
      subscription: subscription ?? this.subscription,
      plans: plans ?? this.plans,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      isRestoring: isRestoring ?? this.isRestoring,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastMessage: clearMessage ? null : (lastMessage ?? this.lastMessage),
    );
  }
}

// ---------------------------------------------------------------------------
// AsyncNotifier
// ---------------------------------------------------------------------------

/// Owns subscription state: loads the current entitlement + plans, drives the
/// purchase and restore flows, and exposes a derived [isPremium] flag.
class SubscriptionNotifier extends AsyncNotifier<SubscriptionState> {
  @override
  Future<SubscriptionState> build() async {
    // Initial load: fetch the current subscription and plans concurrently.
    final getSub = ref.watch(getMySubscriptionProvider);
    final getPlans = ref.watch(getPlansProvider);

    final subResult = await getSub(const NoParams());
    final plansResult = await getPlans(const NoParams());

    final subscription = subResult.fold(
      // If we can't read the subscription (e.g. offline), assume free; the UI
      // simply shows the paywall. The backend remains the source of truth.
      (_) => SubscriptionEntity.free(),
      (sub) => sub,
    );
    final plans = plansResult.fold(
      (_) => const <PlanEntity>[],
      (list) => list,
    );

    return SubscriptionState(subscription: subscription, plans: plans);
  }

  /// Re-fetches subscription + plans (e.g. on app resume or pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncLoading<SubscriptionState>().copyWithPrevious(state);
    state = await AsyncValue.guard(build);
  }

  SubscriptionState get _current =>
      state.valueOrNull ??
      SubscriptionState(subscription: SubscriptionEntity.free());

  /// Launches the native purchase flow for [plan] and applies the
  /// server-validated result on success.
  Future<void> buy(PlanEntity plan) async {
    if (_current.isPurchasing) return; // Guard against double taps.
    state = AsyncData(
      _current.copyWith(isPurchasing: true, clearError: true, clearMessage: true),
    );

    final result = await ref.read(buyPlanProvider).call(BuyPlanParams(plan));

    result.fold(
      (failure) {
        // A user cancellation is silent (no scary error banner).
        final isCancel = failure is PurchaseCancelledFailure;
        state = AsyncData(
          _current.copyWith(
            isPurchasing: false,
            lastError: isCancel ? null : failure.message,
            clearError: isCancel,
          ),
        );
      },
      (subscription) {
        state = AsyncData(
          _current.copyWith(
            subscription: subscription,
            isPurchasing: false,
            lastMessage: 'You are now Premium. Enjoy!',
            clearError: true,
          ),
        );
      },
    );
  }

  /// Restores previously-purchased entitlements.
  Future<void> restore() async {
    if (_current.isRestoring) return;
    state = AsyncData(
      _current.copyWith(isRestoring: true, clearError: true, clearMessage: true),
    );

    final result =
        await ref.read(restorePurchasesProvider).call(const NoParams());

    result.fold(
      (failure) {
        state = AsyncData(
          _current.copyWith(isRestoring: false, lastError: failure.message),
        );
      },
      (subscription) {
        final restored = subscription.isPremium;
        state = AsyncData(
          _current.copyWith(
            subscription: subscription,
            isRestoring: false,
            lastMessage: restored
                ? 'Your Premium subscription has been restored.'
                : 'No previous purchases were found.',
            clearError: true,
          ),
        );
      },
    );
  }

  /// Clears any transient error/message after the UI has shown it.
  void clearTransient() {
    state = AsyncData(
      _current.copyWith(clearError: true, clearMessage: true),
    );
  }
}

/// The single source of subscription state for the app.
final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionState>(
  SubscriptionNotifier.new,
);

// ---------------------------------------------------------------------------
// Derived gating providers
// ---------------------------------------------------------------------------

/// App-wide premium flag used to gate features (AI missions, statistics,
/// unlimited alarms). Defaults to `false` while loading or on error so premium
/// surfaces stay locked until we have a positive, server-backed signal.
///
/// Usage:
/// ```dart
/// final premium = ref.watch(isPremiumProvider);
/// if (!premium) context.go(Routes.paywall);
/// ```
final isPremiumProvider = Provider<bool>((ref) {
  final asyncState = ref.watch(subscriptionProvider);
  return asyncState.valueOrNull?.isPremium ?? false;
});

/// The list of plans for the paywall, sourced from the loaded state.
final plansProvider = Provider<List<PlanEntity>>((ref) {
  return ref.watch(subscriptionProvider).valueOrNull?.plans ??
      const <PlanEntity>[];
});
