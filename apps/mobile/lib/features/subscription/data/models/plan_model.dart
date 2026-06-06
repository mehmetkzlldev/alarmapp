import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:alarmy/features/subscription/domain/entities/plan_entity.dart';

part 'plan_model.freezed.dart';
part 'plan_model.g.dart';

/// Wire model for an item in `GET /subscriptions/plans`.
///
/// The backend supplies marketing metadata (title, description, features,
/// ordering, "most popular" flag, trial length). The authoritative *price text*
/// comes from the store at runtime, so [priceLabel] here is only a fallback used
/// when the store product can't be loaded.
@freezed
class PlanModel with _$PlanModel {
  const PlanModel._();

  const factory PlanModel({
    required String productId,
    required String title,
    @Default('') String description,
    /// One of: `free`, `monthly`, `yearly`.
    @Default('monthly') String period,
    /// Fallback price label if the store product is unavailable.
    @JsonKey(name: 'priceLabel') String? fallbackPriceLabel,
    @Default(false) bool isMostPopular,
    int? trialDays,
    @Default(<String>[]) List<String> features,
  }) = _PlanModel;

  factory PlanModel.fromJson(Map<String, dynamic> json) =>
      _$PlanModelFromJson(json);

  BillingPeriod get _period => switch (period) {
        'free' => BillingPeriod.free,
        'yearly' => BillingPeriod.yearly,
        _ => BillingPeriod.monthly,
      };

  /// Maps to the domain entity. [storePriceLabel], [rawPrice] and
  /// [currencyCode] are injected from the matched store `ProductDetails` when
  /// available; otherwise the backend fallback label is used.
  PlanEntity toEntity({
    String? storePriceLabel,
    double? rawPrice,
    String? currencyCode,
  }) {
    return PlanEntity(
      productId: productId,
      title: title,
      description: description,
      period: _period,
      priceLabel: storePriceLabel ?? fallbackPriceLabel ?? '',
      rawPrice: rawPrice,
      currencyCode: currencyCode,
      isFree: _period == BillingPeriod.free,
      isMostPopular: isMostPopular,
      trialDays: trialDays,
      features: features,
    );
  }
}
