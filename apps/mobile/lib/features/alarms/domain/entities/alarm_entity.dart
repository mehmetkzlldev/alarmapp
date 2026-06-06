import 'package:equatable/equatable.dart';

import 'alarm_mission_entity.dart';

/// Pure domain entity representing a single alarm.
///
/// Mirrors the `Alarm` resource from the API contract (`GET/POST /alarms`) but
/// is intentionally free of JSON / persistence concerns. The `data` layer's
/// `AlarmModel` maps the wire/cache representation to and from this entity.
///
/// Times are stored as a 24-hour `"HH:mm"` local wall-clock string to match the
/// backend `time` field exactly and to feed the native scheduler verbatim.
class AlarmEntity extends Equatable {
  const AlarmEntity({
    required this.id,
    required this.label,
    required this.time,
    required this.repeatDays,
    required this.isActive,
    required this.sound,
    required this.vibration,
    required this.volume,
    required this.snoozeEnabled,
    required this.snoozeIntervalMin,
    required this.snoozeLimit,
    required this.missions,
  });

  /// Server id (UUID). Empty string for an alarm being composed locally that has
  /// not yet been created on the backend.
  final String id;

  /// User-facing label, e.g. "Wake up".
  final String label;

  /// Local time-of-day in 24h `"HH:mm"` format (e.g. `"06:30"`).
  final String time;

  /// Days the alarm repeats: 0 = Sunday ... 6 = Saturday.
  /// An empty list means a one-shot alarm that fires at the next occurrence of
  /// [time] and then deactivates.
  final List<int> repeatDays;

  /// Whether the alarm is currently enabled.
  final bool isActive;

  /// Sound asset key/filename the native player loops while ringing.
  final String sound;

  /// Whether the device vibrates while the alarm rings.
  final bool vibration;

  /// Ring volume in the range 0.0..1.0.
  final double volume;

  /// Whether the snooze action is offered on the ring screen.
  final bool snoozeEnabled;

  /// Minutes added when the user snoozes.
  final int snoozeIntervalMin;

  /// Maximum number of snoozes before the action is disabled.
  final int snoozeLimit;

  /// Missions that must be completed (in order) to dismiss the alarm.
  final List<AlarmMissionEntity> missions;

  /// True if the alarm has no repeat days (fires once).
  bool get isOneShot => repeatDays.isEmpty;

  /// Parses [time] into (hour, minute). Returns `(0, 0)` if malformed so callers
  /// never crash on bad cached data.
  ({int hour, int minute}) get hourMinute {
    // Backend sends "HH:mm:ss"; the create screen builds "HH:mm". Accept both
    // (>=2 parts) and take the first two — otherwise a valid 14:31:00 read as 00:00.
    final parts = time.split(':');
    if (parts.length < 2) return (hour: 0, minute: 0);
    return (
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  AlarmEntity copyWith({
    String? id,
    String? label,
    String? time,
    List<int>? repeatDays,
    bool? isActive,
    String? sound,
    bool? vibration,
    double? volume,
    bool? snoozeEnabled,
    int? snoozeIntervalMin,
    int? snoozeLimit,
    List<AlarmMissionEntity>? missions,
  }) {
    return AlarmEntity(
      id: id ?? this.id,
      label: label ?? this.label,
      time: time ?? this.time,
      repeatDays: repeatDays ?? this.repeatDays,
      isActive: isActive ?? this.isActive,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      volume: volume ?? this.volume,
      snoozeEnabled: snoozeEnabled ?? this.snoozeEnabled,
      snoozeIntervalMin: snoozeIntervalMin ?? this.snoozeIntervalMin,
      snoozeLimit: snoozeLimit ?? this.snoozeLimit,
      missions: missions ?? this.missions,
    );
  }

  @override
  List<Object?> get props => [
        id,
        label,
        time,
        repeatDays,
        isActive,
        sound,
        vibration,
        volume,
        snoozeEnabled,
        snoozeIntervalMin,
        snoozeLimit,
        missions,
      ];
}
