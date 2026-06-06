// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_tokens_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AuthTokensModel _$AuthTokensModelFromJson(Map<String, dynamic> json) {
  return _AuthTokensModel.fromJson(json);
}

/// @nodoc
mixin _$AuthTokensModel {
  String get accessToken => throw _privateConstructorUsedError;
  String get refreshToken => throw _privateConstructorUsedError;

  /// Serializes this AuthTokensModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthTokensModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthTokensModelCopyWith<AuthTokensModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthTokensModelCopyWith<$Res> {
  factory $AuthTokensModelCopyWith(
          AuthTokensModel value, $Res Function(AuthTokensModel) then) =
      _$AuthTokensModelCopyWithImpl<$Res, AuthTokensModel>;
  @useResult
  $Res call({String accessToken, String refreshToken});
}

/// @nodoc
class _$AuthTokensModelCopyWithImpl<$Res, $Val extends AuthTokensModel>
    implements $AuthTokensModelCopyWith<$Res> {
  _$AuthTokensModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthTokensModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = null,
  }) {
    return _then(_value.copyWith(
      accessToken: null == accessToken
          ? _value.accessToken
          : accessToken // ignore: cast_nullable_to_non_nullable
              as String,
      refreshToken: null == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AuthTokensModelImplCopyWith<$Res>
    implements $AuthTokensModelCopyWith<$Res> {
  factory _$$AuthTokensModelImplCopyWith(_$AuthTokensModelImpl value,
          $Res Function(_$AuthTokensModelImpl) then) =
      __$$AuthTokensModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String accessToken, String refreshToken});
}

/// @nodoc
class __$$AuthTokensModelImplCopyWithImpl<$Res>
    extends _$AuthTokensModelCopyWithImpl<$Res, _$AuthTokensModelImpl>
    implements _$$AuthTokensModelImplCopyWith<$Res> {
  __$$AuthTokensModelImplCopyWithImpl(
      _$AuthTokensModelImpl _value, $Res Function(_$AuthTokensModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthTokensModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = null,
  }) {
    return _then(_$AuthTokensModelImpl(
      accessToken: null == accessToken
          ? _value.accessToken
          : accessToken // ignore: cast_nullable_to_non_nullable
              as String,
      refreshToken: null == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthTokensModelImpl extends _AuthTokensModel {
  const _$AuthTokensModelImpl(
      {required this.accessToken, required this.refreshToken})
      : super._();

  factory _$AuthTokensModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthTokensModelImplFromJson(json);

  @override
  final String accessToken;
  @override
  final String refreshToken;

  @override
  String toString() {
    return 'AuthTokensModel(accessToken: $accessToken, refreshToken: $refreshToken)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthTokensModelImpl &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(other.refreshToken, refreshToken) ||
                other.refreshToken == refreshToken));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, accessToken, refreshToken);

  /// Create a copy of AuthTokensModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthTokensModelImplCopyWith<_$AuthTokensModelImpl> get copyWith =>
      __$$AuthTokensModelImplCopyWithImpl<_$AuthTokensModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthTokensModelImplToJson(
      this,
    );
  }
}

abstract class _AuthTokensModel extends AuthTokensModel {
  const factory _AuthTokensModel(
      {required final String accessToken,
      required final String refreshToken}) = _$AuthTokensModelImpl;
  const _AuthTokensModel._() : super._();

  factory _AuthTokensModel.fromJson(Map<String, dynamic> json) =
      _$AuthTokensModelImpl.fromJson;

  @override
  String get accessToken;
  @override
  String get refreshToken;

  /// Create a copy of AuthTokensModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthTokensModelImplCopyWith<_$AuthTokensModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
