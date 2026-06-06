import 'package:equatable/equatable.dart';

/// The store product identifiers offered by the app.
///
/// These strings MUST match, verbatim:
///   - the products configured in Google Play Console & App Store Connect,
///   - the `productId` the backend expects at `POST /subscriptions/validate`,
///   - the ids queried via `in_app_purchase`'s `queryProductDetails`.
class StoreProductIds {
  StoreProductIds._();

  static const String premiumMonthly = 'premium_monthly';
  static const String premiumYearly = 'premium_yearly';

  /// The full set we query from the stores.
  static const Set<String> all = {premiumMonthly, premiumYearly};
}

/// Billing cadence for a plan.
enum BillingPeriod {
  /// No recurring charge — the free tier.
  free,
  monthly,
  yearly;
}

/// A purchasable (or free) plan presented on the paywall.
///
/// Pure domain object. Display price strings come from two places and are
/// reconciled in the data layer:
///   - the backend `GET /subscriptions/plans` (marketing copy, ordering),
///   - the store's localized `ProductDetails.price` (authoritative price text).
class PlanEntity extends Equatable {
  const PlanEntity({
    required this.productId,
    required this.title,
    required this.description,
    required this.period,
    required this.priceLabel,
    this.rawPrice,
    this.currencyCode,
    this.isFree = false,
    this.isMostPopular = false,
    this.trialDays,
    this.features = const <String>[],
  });

  /// The free plan shown for comparison on the paywall.
  factory PlanEntity.free({List<String> features = const <String>[]}) =>
      PlanEntity(
        productId: 'free',
        title: 'Free',
        description: 'Get started with the basics.',
        period: BillingPeriod.free,
        priceLabel: 'Free',
        isFree: true,
        features: features,
      );

  /// Store product id (e.g. `premium_monthly`). `free` for the free plan.
  final String productId;

  final String title;
  final String description;
  final BillingPeriod period;

  /// Localized, human-readable price, e.g. `$4.99` or `$39.99 / year`.
  /// Prefer the store's localized value when available.
  final String priceLabel;

  /// Raw numeric price in [currencyCode] minor-major units (from the store),
  /// used for computing "save X%" comparisons. Null for the free plan.
  final double? rawPrice;

  /// ISO-4217 currency code from the store, e.g. `USD`.
  final String? currencyCode;

  final bool isFree;

  /// Highlight flag for the recommended plan (typically yearly).
  final bool isMostPopular;

  /// Length of the introductory free trial, if any.
  final int? trialDays;

  /// Bullet-point feature list shown under the plan.
  final List<String> features;

  PlanEntity copyWith({
    String? productId,
    String? title,
    String? description,
    BillingPeriod? period,
    String? priceLabel,
    double? rawPrice,
    String? currencyCode,
    bool? isFree,
    bool? isMostPopular,
    int? trialDays,
    List<String>? features,
  }) {
    return PlanEntity(
      productId: productId ?? this.productId,
      title: title ?? this.title,
      description: description ?? this.description,
      period: period ?? this.period,
      priceLabel: priceLabel ?? this.priceLabel,
      rawPrice: rawPrice ?? this.rawPrice,
      currencyCode: currencyCode ?? this.currencyCode,
      isFree: isFree ?? this.isFree,
      isMostPopular: isMostPopular ?? this.isMostPopular,
      trialDays: trialDays ?? this.trialDays,
      features: features ?? this.features,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        title,
        description,
        period,
        priceLabel,
        rawPrice,
        currencyCode,
        isFree,
        isMostPopular,
        trialDays,
        features,
      ];
}
