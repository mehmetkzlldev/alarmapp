import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/platform/alarm_scheduler.dart';
import '../../domain/entities/alarm_entity.dart';
import 'alarm_mission_model.dart';

part 'alarm_model.freezed.dart';
part 'alarm_model.g.dart';

/// Data-layer DTO for an alarm.
///
/// Serializes VERBATIM to the API `Alarm` shape (`GET/POST /alarms`). Defaults
/// mirror the backend so a partially-specified create body still round-trips.
/// This model doubles as the offline-cache record (plain JSON), enabling the
/// app to feed the native scheduler while offline.
@freezed
class AlarmModel with _$AlarmModel {
  const AlarmModel._();

  /// The backend returns `time` as "HH:mm:ss"; the app + native scheduler expect
  /// "HH:mm". Normalize so every consumer sees a clean 24h "HH:mm".
  String get timeHHmm {
    final p = time.split(':');
    if (p.length < 2) return time;
    return '${p[0].padLeft(2, '0')}:${p[1].padLeft(2, '0')}';
  }

  const factory AlarmModel({
    @Default('') String id,
    @Default('Alarm') String label,
    required String time, // "HH:mm" 24h local
    @Default(<int>[]) List<int> repeatDays, // 0=Sun .. 6=Sat
    @Default(true) bool isActive,
    @Default('default') String sound,
    @Default(true) bool vibration,
    @Default(1.0) double volume, // 0.0 .. 1.0
    @Default(true) bool snoozeEnabled,
    @Default(5) int snoozeIntervalMin,
    @Default(3) int snoozeLimit,
    @Default(<AlarmMissionModel>[]) List<AlarmMissionModel> missions,
  }) = _AlarmModel;

  factory AlarmModel.fromJson(Map<String, dynamic> json) =>
      _$AlarmModelFromJson(json);

  /// Request body for `POST /alarms`. Missions are sent inline using their
  /// create shape; server-managed fields (`id`) are omitted.
  Map<String, dynamic> toCreateJson() => <String, dynamic>{
        'label': label,
        'time': time,
        'repeatDays': repeatDays,
        'isActive': isActive,
        'sound': sound,
        'vibration': vibration,
        'volume': volume,
        'snoozeEnabled': snoozeEnabled,
        'snoozeIntervalMin': snoozeIntervalMin,
        'snoozeLimit': snoozeLimit,
        'missions': missions.map((m) => m.toCreateJson()).toList(),
      };

  /// Request body for `PATCH /alarms/:id`. Only the mutable scalar fields are
  /// included; missions are managed through the dedicated missions endpoints.
  Map<String, dynamic> toUpdateJson() => <String, dynamic>{
        'label': label,
        'time': time,
        'repeatDays': repeatDays,
        'isActive': isActive,
        'sound': sound,
        'vibration': vibration,
        'volume': volume,
        'snoozeEnabled': snoozeEnabled,
        'snoozeIntervalMin': snoozeIntervalMin,
        'snoozeLimit': snoozeLimit,
      };

  AlarmEntity toEntity() => AlarmEntity(
        id: id,
        label: label,
        time: timeHHmm,
        repeatDays: List<int>.from(repeatDays),
        isActive: isActive,
        sound: sound,
        vibration: vibration,
        volume: volume,
        snoozeEnabled: snoozeEnabled,
        snoozeIntervalMin: snoozeIntervalMin,
        snoozeLimit: snoozeLimit,
        missions: missions.map((m) => m.toEntity()).toList(),
      );

  factory AlarmModel.fromEntity(AlarmEntity e) => AlarmModel(
        id: e.id,
        label: e.label,
        time: e.time,
        repeatDays: List<int>.from(e.repeatDays),
        isActive: e.isActive,
        sound: e.sound,
        vibration: e.vibration,
        volume: e.volume,
        snoozeEnabled: e.snoozeEnabled,
        snoozeIntervalMin: e.snoozeIntervalMin,
        snoozeLimit: e.snoozeLimit,
        missions: e.missions.map(AlarmMissionModel.fromEntity).toList(),
      );

  /// Maps to the native scheduler DTO (`core/platform/alarm_scheduler.dart`).
  /// Missions are NOT passed to the native side — mission enforcement happens in
  /// the Flutter ring screen; the native side only handles waking the device.
  AlarmSchedule toSchedule() => AlarmSchedule(
        id: id,
        label: label,
        time: timeHHmm,
        repeatDays: List<int>.from(repeatDays),
        isActive: isActive,
        sound: sound,
        vibration: vibration,
        volume: volume,
        snoozeEnabled: snoozeEnabled,
        snoozeIntervalMin: snoozeIntervalMin,
        snoozeLimit: snoozeLimit,
      );
}
