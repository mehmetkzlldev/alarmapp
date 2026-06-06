// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SubscriptionModel _$SubscriptionModelFromJson(Map<String, dynamic> json) {
  return _SubscriptionModel.fromJson(json);
}

/// @nodoc
mixin _$SubscriptionModel {
  String get status => throw _privateConstructorUsedError;
  String? get store => throw _privateConstructorUsedError;
  String? get productId => throw _privateConstructorUsedError;
  DateTime? get currentPeriodEnd => throw _privateConstructorUsedError;
  bool get cancelAtPeriodEnd => throw _privateConstructorUsedError;
  bool get isInTrial => throw _privateConstructorUsedError;

  /// Serializes this SubscriptionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SubscriptionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubscriptionModelCopyWith<SubscriptionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubscriptionModelCopyWith<$Res> {
  factory $SubscriptionModelCopyWith(
          SubscriptionModel value, $Res Function(SubscriptionModel) then) =
      _$SubscriptionModelCopyWithImpl<$Res, SubscriptionModel>;
  @useResult
  $Res call(
      {String status,
      String? store,
      String? productId,
      DateTime? currentPeriodEnd,
      bool cancelAtPeriodEnd,
      bool isInTrial});
}

/// @nodoc
class _$SubscriptionModelCopyWithImpl<$Res, $Val extends SubscriptionModel>
    implements $SubscriptionModelCopyWith<$Res> {
  _$SubscriptionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubscriptionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? store = freezed,
    Object? productId = freezed,
    Object? currentPeriodEnd = freezed,
    Object? cancelAtPeriodEnd = null,
    Object? isInTrial = null,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      store: freezed == store
          ? _value.store
          : store // ignore: cast_nullable_to_non_nullable
              as String?,
      productId: freezed == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String?,
      currentPeriodEnd: freezed == currentPeriodEnd
          ? _value.currentPeriodEnd
          : currentPeriodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cancelAtPeriodEnd: null == cancelAtPeriodEnd
          ? _value.cancelAtPeriodEnd
          : cancelAtPeriodEnd // ignore: cast_nullable_to_non_nullable
              as bool,
      isInTrial: null == isInTrial
          ? _value.isInTrial
          : isInTrial // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SubscriptionModelImplCopyWith<$Res>
    implements $SubscriptionModelCopyWith<$Res> {
  factory _$$SubscriptionModelImplCopyWith(_$SubscriptionModelImpl value,
          $Res Function(_$SubscriptionModelImpl) then) =
      __$$SubscriptionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String status,
      String? store,
      String? productId,
      DateTime? currentPeriodEnd,
      bool cancelAtPeriodEnd,
      bool isInTrial});
}

/// @nodoc
class __$$SubscriptionModelImplCopyWithImpl<$Res>
    extends _$SubscriptionModelCopyWithImpl<$Res, _$SubscriptionModelImpl>
    implements _$$SubscriptionModelImplCopyWith<$Res> {
  __$$SubscriptionModelImplCopyWithImpl(_$SubscriptionModelImpl _value,
      $Res Function(_$SubscriptionModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of SubscriptionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? store = freezed,
    Object? productId = freezed,
    Object? currentPeriodEnd = freezed,
    Object? cancelAtPeriodEnd = null,
    Object? isInTrial = null,
  }) {
    return _then(_$SubscriptionModelImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      store: freezed == store
          ? _value.store
          : store // ignore: cast_nullable_to_non_nullable
              as String?,
      productId: freezed == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String?,
      currentPeriodEnd: freezed == currentPeriodEnd
          ? _value.currentPeriodEnd
          : currentPeriodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cancelAtPeriodEnd: null == cancelAtPeriodEnd
          ? _value.cancelAtPeriodEnd
          : cancelAtPeriodEnd // ignore: cast_nullable_to_non_nullable
              as bool,
      isInTrial: null == isInTrial
          ? _value.isInTrial
          : isInTrial // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SubscriptionModelImpl extends _SubscriptionModel {
  const _$SubscriptionModelImpl(
      {required this.status,
      this.store,
      this.productId,
      this.currentPeriodEnd,
      this.cancelAtPeriodEnd = false,
      this.isInTrial = false})
      : super._();

  factory _$SubscriptionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubscriptionModelImplFromJson(json);

  @override
  final String status;
  @override
  final String? store;
  @override
  final String? productId;
  @override
  final DateTime? currentPeriodEnd;
  @override
  @JsonKey()
  final bool cancelAtPeriodEnd;
  @override
  @JsonKey()
  final bool isInTrial;

  @override
  String toString() {
    return 'SubscriptionModel(status: $status, store: $store, productId: $productId, currentPeriodEnd: $currentPeriodEnd, cancelAtPeriodEnd: $cancelAtPeriodEnd, isInTrial: $isInTrial)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionModelImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.store, store) || other.store == store) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.currentPeriodEnd, currentPeriodEnd) ||
                other.currentPeriodEnd == currentPeriodEnd) &&
            (identical(other.cancelAtPeriodEnd, cancelAtPeriodEnd) ||
                other.cancelAtPeriodEnd == cancelAtPeriodEnd) &&
            (identical(other.isInTrial, isInTrial) ||
                other.isInTrial == isInTrial));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, status, store, productId,
      currentPeriodEnd, cancelAtPeriodEnd, isInTrial);

  /// Create a copy of SubscriptionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionModelImplCopyWith<_$SubscriptionModelImpl> get copyWith =>
      __$$SubscriptionModelImplCopyWithImpl<_$SubscriptionModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SubscriptionModelImplToJson(
      this,
    );
  }
}

abstract class _SubscriptionModel extends SubscriptionModel {
  const factory _SubscriptionModel(
      {required final String status,
      final String? store,
      final String? productId,
      final DateTime? currentPeriodEnd,
      final bool cancelAtPeriodEnd,
      final bool isInTrial}) = _$SubscriptionModelImpl;
  const _SubscriptionModel._() : super._();

  factory _SubscriptionModel.fromJson(Map<String, dynamic> json) =
      _$SubscriptionModelImpl.fromJson;

  @override
  String get status;
  @override
  String? get store;
  @override
  String? get productId;
  @override
  DateTime? get currentPeriodEnd;
  @override
  bool get cancelAtPeriodEnd;
  @override
  bool get isInTrial;

  /// Create a copy of SubscriptionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubscriptionModelImplCopyWith<_$SubscriptionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
