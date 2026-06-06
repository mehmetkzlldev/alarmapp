// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubscriptionModelImpl _$$SubscriptionModelImplFromJson(
        Map<String, dynamic> json) =>
    _$SubscriptionModelImpl(
      status: json['status'] as String,
      store: json['store'] as String?,
      productId: json['productId'] as String?,
      currentPeriodEnd: json['currentPeriodEnd'] == null
          ? null
          : DateTime.parse(json['currentPeriodEnd'] as String),
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] as bool? ?? false,
      isInTrial: json['isInTrial'] as bool? ?? false,
    );

Map<String, dynamic> _$$SubscriptionModelImplToJson(
        _$SubscriptionModelImpl instance) =>
    <String, dynamic>{
      'status': instance.status,
      'store': instance.store,
      'productId': instance.productId,
      'currentPeriodEnd': instance.currentPeriodEnd?.toIso8601String(),
      'cancelAtPeriodEnd': instance.cancelAtPeriodEnd,
      'isInTrial': instance.isInTrial,
    };
