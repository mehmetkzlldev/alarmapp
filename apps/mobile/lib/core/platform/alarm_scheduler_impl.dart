// alarm_scheduler_impl.dart
//
// Concrete [AlarmScheduler] backed by MethodChannel 'app/alarm'. The native
// handlers (AlarmSchedulerPlugin.kt on Android, AppDelegate + AlarmManager.swift
// on iOS) implement the matching method names below.
//
// Channel method names are part of the cross-platform contract — keep them in
// sync with the native `when (call.method)` / `switch call.method` blocks.
//
// IMPORTANT: scheduling is a *side effect* of saving an alarm; it must NEVER
// make the data operation fail. On the web there is no native side at all, and
// on a device the call can fail (e.g. a revoked exact-alarm permission). Every
// native call therefore goes through [_invoke], which no-ops on the web and
// swallows platform errors so the alarm is still saved to the backend + cache.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import 'alarm_scheduler.dart';

class AlarmSchedulerImpl implements AlarmScheduler {
  AlarmSchedulerImpl([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel('app/alarm');

  final MethodChannel _channel;

  // --- Channel method names (shared contract) --------------------------------
  static const String _mSchedule = 'schedule';
  static const String _mCancel = 'cancel';
  static const String _mSnooze = 'snooze';
  static const String _mStop = 'stop';
  static const String _mCanScheduleExact = 'canScheduleExactAlarms';
  static const String _mRequestExact = 'requestExactAlarmPermission';
  static const String _mRequestBattery = 'requestIgnoreBatteryOptimizations';

  /// Invokes a native method without ever throwing. Returns `null` on the web
  /// (no native scheduler) or when the platform call fails.
  Future<T?> _invoke<T>(String method, [dynamic args]) async {
    if (kIsWeb) return null;
    try {
      return await _channel.invokeMethod<T>(method, args);
    } catch (_) {
      // MissingPluginException / PlatformException — scheduling is best-effort.
      return null;
    }
  }

  @override
  Future<void> schedule(AlarmSchedule schedule) async {
    // Inactive alarms must not leave a dangling OS trigger. Cancel instead.
    if (!schedule.isActive) {
      await cancel(schedule.id);
      return;
    }
    await _invoke<void>(_mSchedule, schedule.toMap());
  }

  @override
  Future<void> cancel(String id) async {
    await _invoke<void>(_mCancel, <String, dynamic>{'id': id});
  }

  @override
  Future<void> snooze(String id, {required int delayMinutes}) async {
    await _invoke<void>(_mSnooze, <String, dynamic>{
      'id': id,
      'delayMinutes': delayMinutes,
    });
  }

  /// Stops a currently-ringing alarm (sound + vibration + foreground service).
  /// Called by the ring controller once all missions report success.
  Future<void> stop(String id) async {
    await _invoke<void>(_mStop, <String, dynamic>{'id': id});
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    if (kIsWeb) return true;
    final bool? ok = await _invoke<bool>(_mCanScheduleExact);
    return ok ?? true; // Default permissive (iOS / pre-Android-12 / web).
  }

  @override
  Future<void> requestExactAlarmPermission() async {
    await _invoke<void>(_mRequestExact);
  }

  @override
  Future<void> requestIgnoreBatteryOptimizations() async {
    await _invoke<void>(_mRequestBattery);
  }
}
