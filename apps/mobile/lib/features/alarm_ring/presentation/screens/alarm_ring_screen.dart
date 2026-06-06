// alarm_ring_screen.dart
//
// Full-screen alarm ring UI. Shown over the lock screen by the native
// AlarmActivity (Android) / surfaced by a critical notification (iOS).
//
// Contract this screen MUST uphold:
//   * Keep the device awake while ringing (wakelock + native FLAG_KEEP_SCREEN_ON).
//   * NEVER pop on its own — the system back gesture is blocked (PopScope).
//   * Only dismiss after the embedded MissionScreen reports ALL missions passed.
//   * Snooze is only offered while snoozeEnabled && remaining snoozes > 0.
//
// Audio/vibration live in the native foreground service / AVAudioPlayer; this
// screen does not play sound. It loads the alarm, embeds the existing
// MissionScreen, and on completion asks AlarmRingController to stop native
// ringing and then leaves the route.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:alarmy/l10n/app_localizations.dart';
import 'package:alarmy/core/audio/alarm_sound.dart';
import 'package:alarmy/core/platform/alarm_ring_controller.dart';
import 'package:alarmy/features/alarms/domain/entities/alarm_entity.dart';
import 'package:alarmy/features/alarms/presentation/providers/alarms_provider.dart';
import 'package:alarmy/features/missions/presentation/screens/mission_screen.dart';

class AlarmRingScreen extends ConsumerStatefulWidget {
  const AlarmRingScreen({super.key, required this.alarmId});

  /// Server alarm id forwarded by the native ring trigger via the route path.
  final String alarmId;

  @override
  ConsumerState<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends ConsumerState<AlarmRingScreen> {
  AlarmEntity? _alarm;
  bool _loading = true;
  String? _error;

  /// Once true, the mission flow is shown. Until then we show the ring face.
  bool _missionsStarted = false;

  final ValueNotifier<DateTime> _clock = ValueNotifier<DateTime>(DateTime.now());

  @override
  void initState() {
    super.initState();
    // Keep the screen on for the whole ring/mission session.
    WakelockPlus.enable();
    // Immersive so it is hard to escape the alarm by accident.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _tick();
    _load();
  }

  void _tick() {
    if (!mounted) return;
    _clock.value = DateTime.now();
    Future<void>.delayed(const Duration(seconds: 1), _tick);
  }

  Future<void> _load() async {
    final result =
        await ref.read(alarmRepositoryProvider).getAlarm(widget.alarmId);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    result.fold(
      (failure) => setState(() {
        _error = l10n.ringCouldNotLoadAlarm;
        _loading = false;
      }),
      (alarm) => setState(() {
        _alarm = alarm;
        _loading = false;
      }),
    );
  }

  /// Starts the mission flow: silences the native ring tone and switches to the
  /// intense in-app soundtrack, then reveals the missions.
  Future<void> _startMissions(AlarmEntity alarm) async {
    await ref.read(alarmRingControllerProvider).silenceNative(alarm.id);
    await AlarmSound.instance.start();
    if (mounted) setState(() => _missionsStarted = true);
  }

  /// Successful completion path: stop all audio + report, then leave.
  Future<void> _onAllMissionsComplete() async {
    await AlarmSound.instance.stop();
    await ref
        .read(alarmRingControllerProvider)
        .onMissionsCompleted(widget.alarmId);
    await _releaseAndExit();
  }

  Future<void> _onSnoozePressed() async {
    final alarm = _alarm;
    if (alarm == null) return;
    final applied = await ref.read(alarmRingControllerProvider).onSnooze(
          alarmId: alarm.id,
          snoozeIntervalMin: alarm.snoozeIntervalMin,
          snoozeLimit: alarm.snoozeLimit,
        );
    if (applied) {
      await _releaseAndExit();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).ringSnoozeLimitReached)),
      );
    }
  }

  Future<void> _releaseAndExit() async {
    await AlarmSound.instance.stop();
    await WakelockPlus.disable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      // Cold-started straight onto the ring route — go to the dashboard.
      context.go('/dashboard');
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    // Safety net if we exit without going through _releaseAndExit.
    AlarmSound.instance.stop();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // PopScope blocks the system back gesture/button so the alarm cannot be
    // dismissed without finishing the missions.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B12),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _missionsStarted && _alarm != null
                  ? _buildMissionFlow(_alarm!)
                  : _buildRingFace(),
        ),
      ),
    );
  }

  /// Embeds the existing MissionScreen, wiring its completion callback to our
  /// dismissal routine.
  Widget _buildMissionFlow(AlarmEntity alarm) {
    return MissionScreen(
      alarmId: alarm.id,
      alarmLabel: alarm.label.isEmpty
          ? AppLocalizations.of(context).ringWakeUp
          : alarm.label,
      missions: alarm.missions,
      onAllMissionsComplete: _onAllMissionsComplete,
    );
  }

  Widget _buildRingFace() {
    final l10n = AppLocalizations.of(context);
    final alarm = _alarm;
    final controller = ref.read(alarmRingControllerProvider);
    final snoozeEnabled = alarm?.snoozeEnabled ?? false;
    final snoozeAllowed = alarm != null &&
        alarm.snoozeEnabled &&
        controller.canSnooze(alarm.id, alarm.snoozeLimit);
    final snoozeRemaining = alarm == null
        ? 0
        : (alarm.snoozeLimit - controller.snoozeCountFor(alarm.id))
            .clamp(0, 9999);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: <Widget>[
          const Spacer(),
          ValueListenableBuilder<DateTime>(
            valueListenable: _clock,
            builder: (_, now, __) {
              final hh = now.hour.toString().padLeft(2, '0');
              final mm = now.minute.toString().padLeft(2, '0');
              return Text(
                '$hh:$mm',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            alarm?.label.isNotEmpty == true ? alarm!.label : l10n.ringAlarm,
            style: const TextStyle(fontSize: 20, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: Colors.orangeAccent),
              textAlign: TextAlign.center,
            )
          else
            Text(
              l10n.ringCompleteMissionToStop,
              style: const TextStyle(color: Colors.white60, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          const Spacer(),
          // Primary action: start the mission flow. Disabled if the alarm could
          // not be loaded (the user can still snooze/stop, below).
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: alarm == null ? null : () => _startMissions(alarm),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: Text(
                l10n.ringStartMission,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (snoozeEnabled)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: snoozeAllowed ? _onSnoozePressed : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.white24),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  snoozeAllowed
                      ? l10n.ringSnoozeWithDetails(
                          alarm!.snoozeIntervalMin, snoozeRemaining)
                      : l10n.ringSnoozeLimitReached,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
