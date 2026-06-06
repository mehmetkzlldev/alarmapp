// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'validate_purchase_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ValidatePurchaseRequest _$ValidatePurchaseRequestFromJson(
    Map<String, dynamic> json) {
  return _ValidatePurchaseRequest.fromJson(json);
}

/// @nodoc
mixin _$ValidatePurchaseRequest {
  String get store => throw _privateConstructorUsedError;
  String get productId => throw _privateConstructorUsedError;
  String get receipt => throw _privateConstructorUsedError;

  /// Serializes this ValidatePurchaseRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ValidatePurchaseRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ValidatePurchaseRequestCopyWith<ValidatePurchaseRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ValidatePurchaseRequestCopyWith<$Res> {
  factory $ValidatePurchaseRequestCopyWith(ValidatePurchaseRequest value,
          $Res Function(ValidatePurchaseRequest) then) =
      _$ValidatePurchaseRequestCopyWithImpl<$Res, ValidatePurchaseRequest>;
  @useResult
  $Res call({String store, String productId, String receipt});
}

/// @nodoc
class _$ValidatePurchaseRequestCopyWithImpl<$Res,
        $Val extends ValidatePurchaseRequest>
    implements $ValidatePurchaseRequestCopyWith<$Res> {
  _$ValidatePurchaseRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ValidatePurchaseRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? store = null,
    Object? productId = null,
    Object? receipt = null,
  }) {
    return _then(_value.copyWith(
      store: null == store
          ? _value.store
          : store // ignore: cast_nullable_to_non_nullable
              as String,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      receipt: null == receipt
          ? _value.receipt
          : receipt // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ValidatePurchaseRequestImplCopyWith<$Res>
    implements $ValidatePurchaseRequestCopyWith<$Res> {
  factory _$$ValidatePurchaseRequestImplCopyWith(
          _$ValidatePurchaseRequestImpl value,
          $Res Function(_$ValidatePurchaseRequestImpl) then) =
      __$$ValidatePurchaseRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String store, String productId, String receipt});
}

/// @nodoc
class __$$ValidatePurchaseRequestImplCopyWithImpl<$Res>
    extends _$ValidatePurchaseRequestCopyWithImpl<$Res,
        _$ValidatePurchaseRequestImpl>
    implements _$$ValidatePurchaseRequestImplCopyWith<$Res> {
  __$$ValidatePurchaseRequestImplCopyWithImpl(
      _$ValidatePurchaseRequestImpl _value,
      $Res Function(_$ValidatePurchaseRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of ValidatePurchaseRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? store = null,
    Object? productId = null,
    Object? receipt = null,
  }) {
    return _then(_$ValidatePurchaseRequestImpl(
      store: null == store
          ? _value.store
          : store // ignore: cast_nullable_to_non_nullable
              as String,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      receipt: null == receipt
          ? _value.receipt
          : receipt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ValidatePurchaseRequestImpl implements _ValidatePurchaseRequest {
  const _$ValidatePurchaseRequestImpl(
      {required this.store, required this.productId, required this.receipt});

  factory _$ValidatePurchaseRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$ValidatePurchaseRequestImplFromJson(json);

  @override
  final String store;
  @override
  final String productId;
  @override
  final String receipt;

  @override
  String toString() {
    return 'ValidatePurchaseRequest(store: $store, productId: $productId, receipt: $receipt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ValidatePurchaseRequestImpl &&
            (identical(other.store, store) || other.store == store) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.receipt, receipt) || other.receipt == receipt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, store, productId, receipt);

  /// Create a copy of ValidatePurchaseRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ValidatePurchaseRequestImplCopyWith<_$ValidatePurchaseRequestImpl>
      get copyWith => __$$ValidatePurchaseRequestImplCopyWithImpl<
          _$ValidatePurchaseRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ValidatePurchaseRequestImplToJson(
      this,
    );
  }
}

abstract class _ValidatePurchaseRequest implements ValidatePurchaseRequest {
  const factory _ValidatePurchaseRequest(
      {required final String store,
      required final String productId,
      required final String receipt}) = _$ValidatePurchaseRequestImpl;

  factory _ValidatePurchaseRequest.fromJson(Map<String, dynamic> json) =
      _$ValidatePurchaseRequestImpl.fromJson;

  @override
  String get store;
  @override
  String get productId;
  @override
  String get receipt;

  /// Create a copy of ValidatePurchaseRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ValidatePurchaseRequestImplCopyWith<_$ValidatePurchaseRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}
