// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlanModelImpl _$$PlanModelImplFromJson(Map<String, dynamic> json) =>
    _$PlanModelImpl(
      productId: json['productId'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      period: json['period'] as String? ?? 'monthly',
      fallbackPriceLabel: json['priceLabel'] as String?,
      isMostPopular: json['isMostPopular'] as bool? ?? false,
      trialDays: (json['trialDays'] as num?)?.toInt(),
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$$PlanModelImplToJson(_$PlanModelImpl instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'title': instance.title,
      'description': instance.description,
      'period': instance.period,
      'priceLabel': instance.fallbackPriceLabel,
      'isMostPopular': instance.isMostPopular,
      'trialDays': instance.trialDays,
      'features': instance.features,
    };
