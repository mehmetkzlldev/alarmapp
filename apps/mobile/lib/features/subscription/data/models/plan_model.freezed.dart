// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PlanModel _$PlanModelFromJson(Map<String, dynamic> json) {
  return _PlanModel.fromJson(json);
}

/// @nodoc
mixin _$PlanModel {
  String get productId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;

  /// One of: `free`, `monthly`, `yearly`.
  String get period => throw _privateConstructorUsedError;

  /// Fallback price label if the store product is unavailable.
  @JsonKey(name: 'priceLabel')
  String? get fallbackPriceLabel => throw _privateConstructorUsedError;
  bool get isMostPopular => throw _privateConstructorUsedError;
  int? get trialDays => throw _privateConstructorUsedError;
  List<String> get features => throw _privateConstructorUsedError;

  /// Serializes this PlanModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlanModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlanModelCopyWith<PlanModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlanModelCopyWith<$Res> {
  factory $PlanModelCopyWith(PlanModel value, $Res Function(PlanModel) then) =
      _$PlanModelCopyWithImpl<$Res, PlanModel>;
  @useResult
  $Res call(
      {String productId,
      String title,
      String description,
      String period,
      @JsonKey(name: 'priceLabel') String? fallbackPriceLabel,
      bool isMostPopular,
      int? trialDays,
      List<String> features});
}

/// @nodoc
class _$PlanModelCopyWithImpl<$Res, $Val extends PlanModel>
    implements $PlanModelCopyWith<$Res> {
  _$PlanModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlanModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productId = null,
    Object? title = null,
    Object? description = null,
    Object? period = null,
    Object? fallbackPriceLabel = freezed,
    Object? isMostPopular = null,
    Object? trialDays = freezed,
    Object? features = null,
  }) {
    return _then(_value.copyWith(
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as String,
      fallbackPriceLabel: freezed == fallbackPriceLabel
          ? _value.fallbackPriceLabel
          : fallbackPriceLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      isMostPopular: null == isMostPopular
          ? _value.isMostPopular
          : isMostPopular // ignore: cast_nullable_to_non_nullable
              as bool,
      trialDays: freezed == trialDays
          ? _value.trialDays
          : trialDays // ignore: cast_nullable_to_non_nullable
              as int?,
      features: null == features
          ? _value.features
          : features // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlanModelImplCopyWith<$Res>
    implements $PlanModelCopyWith<$Res> {
  factory _$$PlanModelImplCopyWith(
          _$PlanModelImpl value, $Res Function(_$PlanModelImpl) then) =
      __$$PlanModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String productId,
      String title,
      String description,
      String period,
      @JsonKey(name: 'priceLabel') String? fallbackPriceLabel,
      bool isMostPopular,
      int? trialDays,
      List<String> features});
}

/// @nodoc
class __$$PlanModelImplCopyWithImpl<$Res>
    extends _$PlanModelCopyWithImpl<$Res, _$PlanModelImpl>
    implements _$$PlanModelImplCopyWith<$Res> {
  __$$PlanModelImplCopyWithImpl(
      _$PlanModelImpl _value, $Res Function(_$PlanModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlanModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productId = null,
    Object? title = null,
    Object? description = null,
    Object? period = null,
    Object? fallbackPriceLabel = freezed,
    Object? isMostPopular = null,
    Object? trialDays = freezed,
    Object? features = null,
  }) {
    return _then(_$PlanModelImpl(
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as String,
      fallbackPriceLabel: freezed == fallbackPriceLabel
          ? _value.fallbackPriceLabel
          : fallbackPriceLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      isMostPopular: null == isMostPopular
          ? _value.isMostPopular
          : isMostPopular // ignore: cast_nullable_to_non_nullable
              as bool,
      trialDays: freezed == trialDays
          ? _value.trialDays
          : trialDays // ignore: cast_nullable_to_non_nullable
              as int?,
      features: null == features
          ? _value._features
          : features // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlanModelImpl extends _PlanModel {
  const _$PlanModelImpl(
      {required this.productId,
      required this.title,
      this.description = '',
      this.period = 'monthly',
      @JsonKey(name: 'priceLabel') this.fallbackPriceLabel,
      this.isMostPopular = false,
      this.trialDays,
      final List<String> features = const <String>[]})
      : _features = features,
        super._();

  factory _$PlanModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlanModelImplFromJson(json);

  @override
  final String productId;
  @override
  final String title;
  @override
  @JsonKey()
  final String description;

  /// One of: `free`, `monthly`, `yearly`.
  @override
  @JsonKey()
  final String period;

  /// Fallback price label if the store product is unavailable.
  @override
  @JsonKey(name: 'priceLabel')
  final String? fallbackPriceLabel;
  @override
  @JsonKey()
  final bool isMostPopular;
  @override
  final int? trialDays;
  final List<String> _features;
  @override
  @JsonKey()
  List<String> get features {
    if (_features is EqualUnmodifiableListView) return _features;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_features);
  }

  @override
  String toString() {
    return 'PlanModel(productId: $productId, title: $title, description: $description, period: $period, fallbackPriceLabel: $fallbackPriceLabel, isMostPopular: $isMostPopular, trialDays: $trialDays, features: $features)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlanModelImpl &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.period, period) || other.period == period) &&
            (identical(other.fallbackPriceLabel, fallbackPriceLabel) ||
                other.fallbackPriceLabel == fallbackPriceLabel) &&
            (identical(other.isMostPopular, isMostPopular) ||
                other.isMostPopular == isMostPopular) &&
            (identical(other.trialDays, trialDays) ||
                other.trialDays == trialDays) &&
            const DeepCollectionEquality().equals(other._features, _features));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      productId,
      title,
      description,
      period,
      fallbackPriceLabel,
      isMostPopular,
      trialDays,
      const DeepCollectionEquality().hash(_features));

  /// Create a copy of PlanModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlanModelImplCopyWith<_$PlanModelImpl> get copyWith =>
      __$$PlanModelImplCopyWithImpl<_$PlanModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlanModelImplToJson(
      this,
    );
  }
}

abstract class _PlanModel extends PlanModel {
  const factory _PlanModel(
      {required final String productId,
      required final String title,
      final String description,
      final String period,
      @JsonKey(name: 'priceLabel') final String? fallbackPriceLabel,
      final bool isMostPopular,
      final int? trialDays,
      final List<String> features}) = _$PlanModelImpl;
  const _PlanModel._() : super._();

  factory _PlanModel.fromJson(Map<String, dynamic> json) =
      _$PlanModelImpl.fromJson;

  @override
  String get productId;
  @override
  String get title;
  @override
  String get description;

  /// One of: `free`, `monthly`, `yearly`.
  @override
  String get period;

  /// Fallback price label if the store product is unavailable.
  @override
  @JsonKey(name: 'priceLabel')
  String? get fallbackPriceLabel;
  @override
  bool get isMostPopular;
  @override
  int? get trialDays;
  @override
  List<String> get features;

  /// Create a copy of PlanModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlanModelImplCopyWith<_$PlanModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
