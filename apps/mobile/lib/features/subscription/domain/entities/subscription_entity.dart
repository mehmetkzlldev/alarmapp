import 'package:equatable/equatable.dart';

/// Lifecycle states a subscription can be in. Mirrors the backend's
/// `Subscription.status` values. Unknown server values map to [unknown] for
/// forward compatibility.
enum SubscriptionStatus {
  /// Currently entitled to premium features.
  active('active'),

  /// In a free trial that still grants premium access.
  trialing('trialing'),

  /// Payment failed but still within the grace/retry window.
  pastDue('past_due'),

  /// Cancelled and no longer entitled.
  canceled('canceled'),

  /// Lapsed / expired.
  expired('expired'),

  /// No subscription on record (free user).
  none('none'),

  /// Server sent a status this build does not understand.
  unknown('unknown');

  const SubscriptionStatus(this.wireValue);

  /// Exact string used on the wire.
  final String wireValue;

  static SubscriptionStatus fromWire(String? value) {
    for (final s in SubscriptionStatus.values) {
      if (s.wireValue == value) return s;
    }
    return SubscriptionStatus.unknown;
  }
}

/// The store that fulfilled the purchase. Matches the `store` discriminator in
/// `POST /subscriptions/validate`.
enum SubscriptionStore {
  appStore('app_store'),
  playStore('play_store'),
  unknown('unknown');

  const SubscriptionStore(this.wireValue);

  final String wireValue;

  static SubscriptionStore fromWire(String? value) {
    for (final s in SubscriptionStore.values) {
      if (s.wireValue == value) return s;
    }
    return SubscriptionStore.unknown;
  }
}

/// Pure domain representation of the current user's subscription.
///
/// Framework-agnostic (no JSON / Freezed). The data layer maps
/// `SubscriptionModel` -> `SubscriptionEntity` at the repository boundary.
///
/// The single most important derived value is [isPremium]: the app uses it to
/// gate premium features. It is computed from server-provided fields only — the
/// client never fabricates entitlement.
class SubscriptionEntity extends Equatable {
  const SubscriptionEntity({
    required this.status,
    required this.store,
    this.productId,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
    this.isInTrial = false,
  });

  /// A free user with no subscription on record.
  factory SubscriptionEntity.free() =>
      const SubscriptionEntity(
        status: SubscriptionStatus.none,
        store: SubscriptionStore.unknown,
      );

  final SubscriptionStatus status;
  final SubscriptionStore store;

  /// The active store product id (e.g. `premium_monthly`), when subscribed.
  final String? productId;

  /// When the current paid period ends (renewal or expiry boundary, UTC).
  final DateTime? currentPeriodEnd;

  /// True if the user has cancelled but retains access until [currentPeriodEnd].
  final bool cancelAtPeriodEnd;

  /// True while inside a free trial.
  final bool isInTrial;

  /// Whether the user is entitled to premium features right now.
  ///
  /// Entitlement holds for [SubscriptionStatus.active],
  /// [SubscriptionStatus.trialing], and [SubscriptionStatus.pastDue] (grace
  /// period). Additionally, if a known period end exists we ensure it is in the
  /// future as a defensive cross-check against stale cached data.
  bool get isPremium {
    final entitled = status == SubscriptionStatus.active ||
        status == SubscriptionStatus.trialing ||
        status == SubscriptionStatus.pastDue;
    if (!entitled) return false;
    final end = currentPeriodEnd;
    if (end == null) return true;
    return DateTime.now().toUtc().isBefore(end);
  }

  SubscriptionEntity copyWith({
    SubscriptionStatus? status,
    SubscriptionStore? store,
    String? productId,
    DateTime? currentPeriodEnd,
    bool? cancelAtPeriodEnd,
    bool? isInTrial,
  }) {
    return SubscriptionEntity(
      status: status ?? this.status,
      store: store ?? this.store,
      productId: productId ?? this.productId,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
      isInTrial: isInTrial ?? this.isInTrial,
    );
  }

  @override
  List<Object?> get props => [
        status,
        store,
        productId,
        currentPeriodEnd,
        cancelAtPeriodEnd,
        isInTrial,
      ];
}
