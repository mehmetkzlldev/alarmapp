import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:alarmy/features/subscription/domain/entities/subscription_entity.dart';

part 'subscription_model.freezed.dart';
part 'subscription_model.g.dart';

/// Wire model for `GET /subscriptions/me` and the response of
/// `POST /subscriptions/validate`.
///
/// JSON is camelCase per the API contract. We keep the raw `status`/`store` as
/// strings here and translate them into typed enums when mapping to the domain
/// [SubscriptionEntity], so unrecognized server values never crash parsing.
@freezed
class SubscriptionModel with _$SubscriptionModel {
  const SubscriptionModel._();

  const factory SubscriptionModel({
    required String status,
    String? store,
    String? productId,
    DateTime? currentPeriodEnd,
    @Default(false) bool cancelAtPeriodEnd,
    @Default(false) bool isInTrial,
  }) = _SubscriptionModel;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);

  /// Maps the wire model into the pure domain entity.
  SubscriptionEntity toEntity() {
    return SubscriptionEntity(
      status: SubscriptionStatus.fromWire(status),
      store: SubscriptionStore.fromWire(store),
      productId: productId,
      currentPeriodEnd: currentPeriodEnd?.toUtc(),
      cancelAtPeriodEnd: cancelAtPeriodEnd,
      isInTrial: isInTrial,
    );
  }
}
