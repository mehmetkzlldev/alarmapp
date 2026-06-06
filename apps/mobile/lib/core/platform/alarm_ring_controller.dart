// alarm_ring_controller.dart
//
// The Dart-side brain that reacts to a native 'alarm_fired' event:
//   1. Navigates (GoRouter) to the full-screen ring route.
//   2. The ring screen loads the alarm (+ missions) and runs the MissionScreen.
//   3. Dismissal is blocked until every mission reports success.
//   4. On success: stops native audio/vibration (scheduler.stop) and reports the
//      alarm dismissed event. Mission history is recorded by the existing
//      MissionSequenceController, so this controller does NOT duplicate it.
//   5. On snooze (within snoozeLimit): stops audio and re-arms via the scheduler.
//
// Audio + vibration are owned by the NATIVE foreground service (Android) /
// AVAudioPlayer (iOS) so they keep sounding even if the Flutter engine is
// killed. This controller only *commands* native to stop them — it never plays
// sound itself, keeping a single source of truth for the ringing media.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:alarmy/core/platform/alarm_event_channel.dart';
import 'package:alarmy/core/platform/alarm_scheduler.dart';
import 'package:alarmy/core/platform/alarm_scheduler_impl.dart';
import 'package:alarmy/core/router/app_router.dart';
import 'package:alarmy/core/router/route_names.dart';

/// Optional backend reporter for `POST /alarms/:id/events`. The default
/// implementation is a no-op so the alarm engine never *blocks* on telemetry and
/// the app builds even before the events endpoint is wired in the data layer.
/// Provide a real implementation via [alarmEventReporterProvider] to enable it.
abstract class AlarmEventReporter {
  /// status: 'fired' | 'dismissed' | 'snoozed'.
  Future<void> report(String alarmId, String status,
      {Map<String, dynamic>? metadata});
}

class _NoopAlarmEventReporter implements AlarmEventReporter {
  const _NoopAlarmEventReporter();
  @override
  Future<void> report(String alarmId, String status,
          {Map<String, dynamic>? metadata}) async {}
}

/// Override in app bootstrap with a real reporter (posts to `/alarms/:id/events`).
final alarmEventReporterProvider = Provider<AlarmEventReporter>(
  (ref) => const _NoopAlarmEventReporter(),
);

/// Singleton event-channel provider so the controller and any debug UI share one
/// broadcast subscription.
final alarmEventChannelProvider = Provider<AlarmEventChannel>(
  (ref) => AlarmEventChannel(),
);

/// The controller itself. Created eagerly at app start (see [alarmRingBootstrap]).
final alarmRingControllerProvider = Provider<AlarmRingController>((ref) {
  final controller = AlarmRingController(
    ref: ref,
    eventChannel: ref.watch(alarmEventChannelProvider),
    scheduler: AlarmSchedulerImpl(),
    reporter: ref.watch(alarmEventReporterProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

/// Watch this once from a top-level widget (or read it in bootstrap) to start
/// listening for native alarm-fired events.
final alarmRingBootstrapProvider = Provider<void>((ref) {
  ref.watch(alarmRingControllerProvider).start();
});

class AlarmRingController {
  AlarmRingController({
    required Ref ref,
    required AlarmEventChannel eventChannel,
    required AlarmScheduler scheduler,
    required AlarmEventReporter reporter,
  })  : _ref = ref,
        _eventChannel = eventChannel,
        _scheduler = scheduler,
        _reporter = reporter;

  final Ref _ref;
  final AlarmEventChannel _eventChannel;
  final AlarmScheduler _scheduler;
  final AlarmEventReporter _reporter;

  StreamSubscription<AlarmEvent>? _sub;

  /// Lightweight nav channel: the Android AlarmActivity pushes the ring route
  /// directly here on cold launch (belt-and-suspenders alongside the
  /// EventChannel replay). Must match AlarmActivity.NAV_CHANNEL on Kotlin.
  static const MethodChannel _navChannel = MethodChannel('app/alarm/nav');

  /// Per-alarm snooze usage for the current ringing session so the ring screen
  /// can disable the snooze button once the limit is reached.
  final Map<String, int> _snoozeCounts = <String, int>{};

  /// Guards against double-navigation if native re-emits the fired event.
  String? _activeRingingAlarmId;

  GoRouter get _router => _ref.read(routerProvider);

  /// Begin listening for native alarm-fired events. Idempotent.
  void start() {
    _sub ??= _eventChannel.fired.listen(
      _onAlarmFired,
      onError: (Object e) => debugPrint('AlarmRingController stream error: $e'),
    );
    // Handle the direct route push from the native AlarmActivity.
    _navChannel.setMethodCallHandler(_onNavCall);
  }

  Future<dynamic> _onNavCall(MethodCall call) async {
    if (call.method == 'navigate') {
      final args = (call.arguments as Map?) ?? const {};
      final alarmId = (args['id'] ?? '') as String;
      if (alarmId.isNotEmpty && _activeRingingAlarmId != alarmId) {
        _activeRingingAlarmId = alarmId;
        _router.go(Routes.alarmRingFor(alarmId));
      }
    }
    return null;
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _navChannel.setMethodCallHandler(null);
  }

  void _onAlarmFired(AlarmEvent event) {
    final String alarmId = event.alarmId;
    if (alarmId.isEmpty) return;
    if (_activeRingingAlarmId == alarmId) return; // De-dupe re-fires.
    _activeRingingAlarmId = alarmId;

    // Fire-and-forget telemetry; UX must never block on the network.
    unawaited(_reporter
        .report(alarmId, 'fired')
        .catchError((Object e) => debugPrint('report(fired) failed: $e')));

    // Navigate to the full-screen ring route, carrying the alarm id.
    _router.go(Routes.alarmRingFor(alarmId));
  }

  /// Silences the native ring tone WITHOUT ending the ringing session — used
  /// when the mission flow starts so an intense in-app soundtrack can take over.
  Future<void> silenceNative(String alarmId) async {
    if (_scheduler is AlarmSchedulerImpl) {
      await (_scheduler as AlarmSchedulerImpl).stop(alarmId);
    }
  }

  /// Called by the ring screen once the mission flow reports success.
  /// Stops native ringing and reports the dismissal. Mission history is handled
  /// by MissionSequenceController, so it is intentionally not recorded here.
  Future<void> onMissionsCompleted(String alarmId) async {
    // Stop the native foreground service / audio.
    if (_scheduler is AlarmSchedulerImpl) {
      await (_scheduler as AlarmSchedulerImpl).stop(alarmId);
    }
    unawaited(_reporter
        .report(alarmId, 'dismissed')
        .catchError((Object e) => debugPrint('report(dismissed) failed: $e')));

    _snoozeCounts.remove(alarmId);
    _activeRingingAlarmId = null;
  }

  int snoozeCountFor(String alarmId) => _snoozeCounts[alarmId] ?? 0;

  bool canSnooze(String alarmId, int snoozeLimit) =>
      snoozeCountFor(alarmId) < snoozeLimit;

  /// Applies a snooze if under [snoozeLimit]; returns false if the limit is hit.
  Future<bool> onSnooze({
    required String alarmId,
    required int snoozeIntervalMin,
    required int snoozeLimit,
  }) async {
    if (!canSnooze(alarmId, snoozeLimit)) return false;
    _snoozeCounts[alarmId] = snoozeCountFor(alarmId) + 1;

    await _scheduler.snooze(alarmId, delayMinutes: snoozeIntervalMin);

    unawaited(_reporter.report(
      alarmId,
      'snoozed',
      metadata: <String, dynamic>{'snoozeCount': _snoozeCounts[alarmId]},
    ).catchError((Object e) => debugPrint('report(snoozed) failed: $e')));

    // Allow the snoozed re-fire to navigate again.
    _activeRingingAlarmId = null;
    return true;
  }
}
