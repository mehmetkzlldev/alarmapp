// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validate_purchase_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ValidatePurchaseRequestImpl _$$ValidatePurchaseRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$ValidatePurchaseRequestImpl(
      store: json['store'] as String,
      productId: json['productId'] as String,
      receipt: json['receipt'] as String,
    );

Map<String, dynamic> _$$ValidatePurchaseRequestImplToJson(
        _$ValidatePurchaseRequestImpl instance) =>
    <String, dynamic>{
      'store': instance.store,
      'productId': instance.productId,
      'receipt': instance.receipt,
    };
