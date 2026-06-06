// alarm_scheduler.dart
//
// Abstract contract for the platform alarm engine. The Flutter side never
// fires alarms itself — it only *schedules* them with the OS (AlarmManager on
// Android, UNUserNotificationCenter + background audio on iOS). The actual
// ringing happens in native code so it survives the Flutter engine being
// killed, the screen being locked, and the app being in the background.
//
// All times are wall-clock local time. The native side is responsible for
// converting `time` + `repeatDays` into the next concrete trigger instant and
// for re-arming repeating alarms after each fire (and after reboot).

import 'package:flutter/foundation.dart';

/// Days-of-week bitmask helper. Matches the API contract `repeatDays: number[]`
/// where 0 = Sunday ... 6 = Saturday. We pass the raw list across the channel.
@immutable
class AlarmSchedule {
  /// Server alarm id (UUID string). Used as the native alarm/PendingIntent id.
  final String id;

  /// User-facing label shown on the ring screen / notification.
  final String label;

  /// Local time-of-day, "HH:mm" 24h format (matches API `time`).
  final String time;

  /// Days the alarm repeats. Empty list => one-shot alarm.
  /// 0 = Sunday ... 6 = Saturday.
  final List<int> repeatDays;

  /// Whether the alarm is currently enabled.
  final bool isActive;

  /// Sound asset key / filename the native player should loop.
  final String sound;

  /// Whether to vibrate while ringing.
  final bool vibration;

  /// Ring volume 0.0..1.0.
  final double volume;

  /// Whether the snooze button is available on the ring screen.
  final bool snoozeEnabled;

  /// Minutes to delay when snoozed.
  final int snoozeIntervalMin;

  /// Maximum number of snoozes allowed before the button is disabled.
  final int snoozeLimit;

  const AlarmSchedule({
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
  });

  /// Serialized form sent over the MethodChannel. Keys are stable contract
  /// names shared with the Kotlin/Swift side — do NOT rename without updating
  /// both native plugins.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
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
}

/// Platform alarm scheduler contract. Implemented by [AlarmSchedulerImpl]
/// which talks to native code over MethodChannel 'app/alarm'.
abstract class AlarmScheduler {
  /// Registers (or re-registers) an exact OS alarm for [schedule].
  /// If the alarm already exists it is replaced. No-op if `isActive` is false
  /// (the impl will instead cancel any pending trigger).
  Future<void> schedule(AlarmSchedule schedule);

  /// Cancels the pending OS alarm with the given [id]. Safe to call when
  /// nothing is scheduled.
  Future<void> cancel(String id);

  /// Snoozes a currently-ringing alarm: stops the sound and re-arms a one-shot
  /// trigger [delayMinutes] from now. The native side enforces nothing about
  /// the snooze limit — that policy lives in the ring controller, which only
  /// calls this when the limit has not been reached.
  Future<void> snooze(String id, {required int delayMinutes});

  /// Best-effort: whether the OS will allow exact alarms (Android 12+
  /// SCHEDULE_EXACT_ALARM). Always true on iOS / older Android.
  Future<bool> canScheduleExactAlarms();

  /// Opens the OS settings screen to grant the exact-alarm permission
  /// (Android 12+). No-op elsewhere.
  Future<void> requestExactAlarmPermission();

  /// Opens the battery-optimization exemption prompt (Android). No-op elsewhere.
  Future<void> requestIgnoreBatteryOptimizations();
}
