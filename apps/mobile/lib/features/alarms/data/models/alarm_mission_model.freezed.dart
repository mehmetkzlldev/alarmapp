// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alarm_mission_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AlarmMissionModel _$AlarmMissionModelFromJson(Map<String, dynamic> json) {
  return _AlarmMissionModel.fromJson(json);
}

/// @nodoc
mixin _$AlarmMissionModel {
  String get id => throw _privateConstructorUsedError;
  String get alarmId =>
      throw _privateConstructorUsedError; // Stored as the raw wire string so unknown/forward-compat values survive a
// cache round-trip; converted to the typed [MissionKind] in [toEntity].
  String get missionType => throw _privateConstructorUsedError;
  String get difficulty => throw _privateConstructorUsedError;
  int get orderIndex => throw _privateConstructorUsedError;
  Map<String, dynamic> get config => throw _privateConstructorUsedError;

  /// Serializes this AlarmMissionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AlarmMissionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AlarmMissionModelCopyWith<AlarmMissionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlarmMissionModelCopyWith<$Res> {
  factory $AlarmMissionModelCopyWith(
          AlarmMissionModel value, $Res Function(AlarmMissionModel) then) =
      _$AlarmMissionModelCopyWithImpl<$Res, AlarmMissionModel>;
  @useResult
  $Res call(
      {String id,
      String alarmId,
      String missionType,
      String difficulty,
      int orderIndex,
      Map<String, dynamic> config});
}

/// @nodoc
class _$AlarmMissionModelCopyWithImpl<$Res, $Val extends AlarmMissionModel>
    implements $AlarmMissionModelCopyWith<$Res> {
  _$AlarmMissionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AlarmMissionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? alarmId = null,
    Object? missionType = null,
    Object? difficulty = null,
    Object? orderIndex = null,
    Object? config = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      alarmId: null == alarmId
          ? _value.alarmId
          : alarmId // ignore: cast_nullable_to_non_nullable
              as String,
      missionType: null == missionType
          ? _value.missionType
          : missionType // ignore: cast_nullable_to_non_nullable
              as String,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String,
      orderIndex: null == orderIndex
          ? _value.orderIndex
          : orderIndex // ignore: cast_nullable_to_non_nullable
              as int,
      config: null == config
          ? _value.config
          : config // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AlarmMissionModelImplCopyWith<$Res>
    implements $AlarmMissionModelCopyWith<$Res> {
  factory _$$AlarmMissionModelImplCopyWith(_$AlarmMissionModelImpl value,
          $Res Function(_$AlarmMissionModelImpl) then) =
      __$$AlarmMissionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String alarmId,
      String missionType,
      String difficulty,
      int orderIndex,
      Map<String, dynamic> config});
}

/// @nodoc
class __$$AlarmMissionModelImplCopyWithImpl<$Res>
    extends _$AlarmMissionModelCopyWithImpl<$Res, _$AlarmMissionModelImpl>
    implements _$$AlarmMissionModelImplCopyWith<$Res> {
  __$$AlarmMissionModelImplCopyWithImpl(_$AlarmMissionModelImpl _value,
      $Res Function(_$AlarmMissionModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of AlarmMissionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? alarmId = null,
    Object? missionType = null,
    Object? difficulty = null,
    Object? orderIndex = null,
    Object? config = null,
  }) {
    return _then(_$AlarmMissionModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      alarmId: null == alarmId
          ? _value.alarmId
          : alarmId // ignore: cast_nullable_to_non_nullable
              as String,
      missionType: null == missionType
          ? _value.missionType
          : missionType // ignore: cast_nullable_to_non_nullable
              as String,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String,
      orderIndex: null == orderIndex
          ? _value.orderIndex
          : orderIndex // ignore: cast_nullable_to_non_nullable
              as int,
      config: null == config
          ? _value._config
          : config // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AlarmMissionModelImpl extends _AlarmMissionModel {
  const _$AlarmMissionModelImpl(
      {this.id = '',
      this.alarmId = '',
      required this.missionType,
      this.difficulty = 'medium',
      this.orderIndex = 0,
      final Map<String, dynamic> config = const <String, dynamic>{}})
      : _config = config,
        super._();

  factory _$AlarmMissionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlarmMissionModelImplFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  @JsonKey()
  final String alarmId;
// Stored as the raw wire string so unknown/forward-compat values survive a
// cache round-trip; converted to the typed [MissionKind] in [toEntity].
  @override
  final String missionType;
  @override
  @JsonKey()
  final String difficulty;
  @override
  @JsonKey()
  final int orderIndex;
  final Map<String, dynamic> _config;
  @override
  @JsonKey()
  Map<String, dynamic> get config {
    if (_config is EqualUnmodifiableMapView) return _config;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_config);
  }

  @override
  String toString() {
    return 'AlarmMissionModel(id: $id, alarmId: $alarmId, missionType: $missionType, difficulty: $difficulty, orderIndex: $orderIndex, config: $config)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlarmMissionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.alarmId, alarmId) || other.alarmId == alarmId) &&
            (identical(other.missionType, missionType) ||
                other.missionType == missionType) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex) &&
            const DeepCollectionEquality().equals(other._config, _config));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, alarmId, missionType,
      difficulty, orderIndex, const DeepCollectionEquality().hash(_config));

  /// Create a copy of AlarmMissionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AlarmMissionModelImplCopyWith<_$AlarmMissionModelImpl> get copyWith =>
      __$$AlarmMissionModelImplCopyWithImpl<_$AlarmMissionModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AlarmMissionModelImplToJson(
      this,
    );
  }
}

abstract class _AlarmMissionModel extends AlarmMissionModel {
  const factory _AlarmMissionModel(
      {final String id,
      final String alarmId,
      required final String missionType,
      final String difficulty,
      final int orderIndex,
      final Map<String, dynamic> config}) = _$AlarmMissionModelImpl;
  const _AlarmMissionModel._() : super._();

  factory _AlarmMissionModel.fromJson(Map<String, dynamic> json) =
      _$AlarmMissionModelImpl.fromJson;

  @override
  String get id;
  @override
  String
      get alarmId; // Stored as the raw wire string so unknown/forward-compat values survive a
// cache round-trip; converted to the typed [MissionKind] in [toEntity].
  @override
  String get missionType;
  @override
  String get difficulty;
  @override
  int get orderIndex;
  @override
  Map<String, dynamic> get config;

  /// Create a copy of AlarmMissionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AlarmMissionModelImplCopyWith<_$AlarmMissionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
