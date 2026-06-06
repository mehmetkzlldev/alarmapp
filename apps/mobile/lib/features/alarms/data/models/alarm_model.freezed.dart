// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alarm_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AlarmModel _$AlarmModelFromJson(Map<String, dynamic> json) {
  return _AlarmModel.fromJson(json);
}

/// @nodoc
mixin _$AlarmModel {
  String get id => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String get time => throw _privateConstructorUsedError; // "HH:mm" 24h local
  List<int> get repeatDays =>
      throw _privateConstructorUsedError; // 0=Sun .. 6=Sat
  bool get isActive => throw _privateConstructorUsedError;
  String get sound => throw _privateConstructorUsedError;
  bool get vibration => throw _privateConstructorUsedError;
  double get volume => throw _privateConstructorUsedError; // 0.0 .. 1.0
  bool get snoozeEnabled => throw _privateConstructorUsedError;
  int get snoozeIntervalMin => throw _privateConstructorUsedError;
  int get snoozeLimit => throw _privateConstructorUsedError;
  List<AlarmMissionModel> get missions => throw _privateConstructorUsedError;

  /// Serializes this AlarmModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AlarmModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AlarmModelCopyWith<AlarmModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlarmModelCopyWith<$Res> {
  factory $AlarmModelCopyWith(
          AlarmModel value, $Res Function(AlarmModel) then) =
      _$AlarmModelCopyWithImpl<$Res, AlarmModel>;
  @useResult
  $Res call(
      {String id,
      String label,
      String time,
      List<int> repeatDays,
      bool isActive,
      String sound,
      bool vibration,
      double volume,
      bool snoozeEnabled,
      int snoozeIntervalMin,
      int snoozeLimit,
      List<AlarmMissionModel> missions});
}

/// @nodoc
class _$AlarmModelCopyWithImpl<$Res, $Val extends AlarmModel>
    implements $AlarmModelCopyWith<$Res> {
  _$AlarmModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AlarmModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? time = null,
    Object? repeatDays = null,
    Object? isActive = null,
    Object? sound = null,
    Object? vibration = null,
    Object? volume = null,
    Object? snoozeEnabled = null,
    Object? snoozeIntervalMin = null,
    Object? snoozeLimit = null,
    Object? missions = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as String,
      repeatDays: null == repeatDays
          ? _value.repeatDays
          : repeatDays // ignore: cast_nullable_to_non_nullable
              as List<int>,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      sound: null == sound
          ? _value.sound
          : sound // ignore: cast_nullable_to_non_nullable
              as String,
      vibration: null == vibration
          ? _value.vibration
          : vibration // ignore: cast_nullable_to_non_nullable
              as bool,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
      snoozeEnabled: null == snoozeEnabled
          ? _value.snoozeEnabled
          : snoozeEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      snoozeIntervalMin: null == snoozeIntervalMin
          ? _value.snoozeIntervalMin
          : snoozeIntervalMin // ignore: cast_nullable_to_non_nullable
              as int,
      snoozeLimit: null == snoozeLimit
          ? _value.snoozeLimit
          : snoozeLimit // ignore: cast_nullable_to_non_nullable
              as int,
      missions: null == missions
          ? _value.missions
          : missions // ignore: cast_nullable_to_non_nullable
              as List<AlarmMissionModel>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AlarmModelImplCopyWith<$Res>
    implements $AlarmModelCopyWith<$Res> {
  factory _$$AlarmModelImplCopyWith(
          _$AlarmModelImpl value, $Res Function(_$AlarmModelImpl) then) =
      __$$AlarmModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String label,
      String time,
      List<int> repeatDays,
      bool isActive,
      String sound,
      bool vibration,
      double volume,
      bool snoozeEnabled,
      int snoozeIntervalMin,
      int snoozeLimit,
      List<AlarmMissionModel> missions});
}

/// @nodoc
class __$$AlarmModelImplCopyWithImpl<$Res>
    extends _$AlarmModelCopyWithImpl<$Res, _$AlarmModelImpl>
    implements _$$AlarmModelImplCopyWith<$Res> {
  __$$AlarmModelImplCopyWithImpl(
      _$AlarmModelImpl _value, $Res Function(_$AlarmModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of AlarmModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? time = null,
    Object? repeatDays = null,
    Object? isActive = null,
    Object? sound = null,
    Object? vibration = null,
    Object? volume = null,
    Object? snoozeEnabled = null,
    Object? snoozeIntervalMin = null,
    Object? snoozeLimit = null,
    Object? missions = null,
  }) {
    return _then(_$AlarmModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as String,
      repeatDays: null == repeatDays
          ? _value._repeatDays
          : repeatDays // ignore: cast_nullable_to_non_nullable
              as List<int>,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      sound: null == sound
          ? _value.sound
          : sound // ignore: cast_nullable_to_non_nullable
              as String,
      vibration: null == vibration
          ? _value.vibration
          : vibration // ignore: cast_nullable_to_non_nullable
              as bool,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
      snoozeEnabled: null == snoozeEnabled
          ? _value.snoozeEnabled
          : snoozeEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      snoozeIntervalMin: null == snoozeIntervalMin
          ? _value.snoozeIntervalMin
          : snoozeIntervalMin // ignore: cast_nullable_to_non_nullable
              as int,
      snoozeLimit: null == snoozeLimit
          ? _value.snoozeLimit
          : snoozeLimit // ignore: cast_nullable_to_non_nullable
              as int,
      missions: null == missions
          ? _value._missions
          : missions // ignore: cast_nullable_to_non_nullable
              as List<AlarmMissionModel>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AlarmModelImpl extends _AlarmModel {
  const _$AlarmModelImpl(
      {this.id = '',
      this.label = 'Alarm',
      required this.time,
      final List<int> repeatDays = const <int>[],
      this.isActive = true,
      this.sound = 'default',
      this.vibration = true,
      this.volume = 1.0,
      this.snoozeEnabled = true,
      this.snoozeIntervalMin = 5,
      this.snoozeLimit = 3,
      final List<AlarmMissionModel> missions = const <AlarmMissionModel>[]})
      : _repeatDays = repeatDays,
        _missions = missions,
        super._();

  factory _$AlarmModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlarmModelImplFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  @JsonKey()
  final String label;
  @override
  final String time;
// "HH:mm" 24h local
  final List<int> _repeatDays;
// "HH:mm" 24h local
  @override
  @JsonKey()
  List<int> get repeatDays {
    if (_repeatDays is EqualUnmodifiableListView) return _repeatDays;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_repeatDays);
  }

// 0=Sun .. 6=Sat
  @override
  @JsonKey()
  final bool isActive;
  @override
  @JsonKey()
  final String sound;
  @override
  @JsonKey()
  final bool vibration;
  @override
  @JsonKey()
  final double volume;
// 0.0 .. 1.0
  @override
  @JsonKey()
  final bool snoozeEnabled;
  @override
  @JsonKey()
  final int snoozeIntervalMin;
  @override
  @JsonKey()
  final int snoozeLimit;
  final List<AlarmMissionModel> _missions;
  @override
  @JsonKey()
  List<AlarmMissionModel> get missions {
    if (_missions is EqualUnmodifiableListView) return _missions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_missions);
  }

  @override
  String toString() {
    return 'AlarmModel(id: $id, label: $label, time: $time, repeatDays: $repeatDays, isActive: $isActive, sound: $sound, vibration: $vibration, volume: $volume, snoozeEnabled: $snoozeEnabled, snoozeIntervalMin: $snoozeIntervalMin, snoozeLimit: $snoozeLimit, missions: $missions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlarmModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.time, time) || other.time == time) &&
            const DeepCollectionEquality()
                .equals(other._repeatDays, _repeatDays) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.sound, sound) || other.sound == sound) &&
            (identical(other.vibration, vibration) ||
                other.vibration == vibration) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.snoozeEnabled, snoozeEnabled) ||
                other.snoozeEnabled == snoozeEnabled) &&
            (identical(other.snoozeIntervalMin, snoozeIntervalMin) ||
                other.snoozeIntervalMin == snoozeIntervalMin) &&
            (identical(other.snoozeLimit, snoozeLimit) ||
                other.snoozeLimit == snoozeLimit) &&
            const DeepCollectionEquality().equals(other._missions, _missions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      label,
      time,
      const DeepCollectionEquality().hash(_repeatDays),
      isActive,
      sound,
      vibration,
      volume,
      snoozeEnabled,
      snoozeIntervalMin,
      snoozeLimit,
      const DeepCollectionEquality().hash(_missions));

  /// Create a copy of AlarmModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AlarmModelImplCopyWith<_$AlarmModelImpl> get copyWith =>
      __$$AlarmModelImplCopyWithImpl<_$AlarmModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AlarmModelImplToJson(
      this,
    );
  }
}

abstract class _AlarmModel extends AlarmModel {
  const factory _AlarmModel(
      {final String id,
      final String label,
      required final String time,
      final List<int> repeatDays,
      final bool isActive,
      final String sound,
      final bool vibration,
      final double volume,
      final bool snoozeEnabled,
      final int snoozeIntervalMin,
      final int snoozeLimit,
      final List<AlarmMissionModel> missions}) = _$AlarmModelImpl;
  const _AlarmModel._() : super._();

  factory _AlarmModel.fromJson(Map<String, dynamic> json) =
      _$AlarmModelImpl.fromJson;

  @override
  String get id;
  @override
  String get label;
  @override
  String get time; // "HH:mm" 24h local
  @override
  List<int> get repeatDays; // 0=Sun .. 6=Sat
  @override
  bool get isActive;
  @override
  String get sound;
  @override
  bool get vibration;
  @override
  double get volume; // 0.0 .. 1.0
  @override
  bool get snoozeEnabled;
  @override
  int get snoozeIntervalMin;
  @override
  int get snoozeLimit;
  @override
  List<AlarmMissionModel> get missions;

  /// Create a copy of AlarmModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AlarmModelImplCopyWith<_$AlarmModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
