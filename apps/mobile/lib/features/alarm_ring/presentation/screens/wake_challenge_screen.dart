import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:alarmy/l10n/app_localizations.dart';
import 'package:alarmy/core/audio/alarm_sound.dart';
import 'package:alarmy/features/alarms/domain/entities/alarm_mission_entity.dart';
import 'package:alarmy/features/missions/presentation/screens/mission_screen.dart';

/// A self-contained, dramatic wake-up experience: a ringing alarm face with a
/// looping sound and a pulsing red screen, followed by the mission chain the
/// user must clear to silence it.
///
/// Used as an in-app **preview/demo** (launched from the dashboard) so the full
/// "shake → math → camera" flow can be experienced without waiting for a real
/// alarm to fire — and it works in the browser, where native alarm scheduling
/// is unavailable.
class WakeChallengeScreen extends ConsumerStatefulWidget {
  const WakeChallengeScreen({super.key, this.missions, this.label});

  /// Missions to run. When null, the demo chain (shake 10s → math → any object)
  /// is used.
  final List<AlarmMissionEntity>? missions;

  /// Header label. Defaults to "WAKE UP!".
  final String? label;

  /// The classic Alarmy-style chain: shake for 10 seconds, then a math problem,
  /// then photograph any object.
  static const List<AlarmMissionEntity> demoChain = [
    AlarmMissionEntity(
      id: '',
      missionType: MissionKind.shake,
      difficulty: MissionDifficulty.medium,
      orderIndex: 0,
      config: {'shakeSeconds': 10},
    ),
    AlarmMissionEntity(
      id: '',
      missionType: MissionKind.math,
      difficulty: MissionDifficulty.medium,
      orderIndex: 1,
    ),
    AlarmMissionEntity(
      id: '',
      missionType: MissionKind.objectDetection,
      difficulty: MissionDifficulty.medium,
      orderIndex: 2,
      config: {'targetObject': 'any'},
    ),
  ];

  @override
  ConsumerState<WakeChallengeScreen> createState() =>
      _WakeChallengeScreenState();
}

class _WakeChallengeScreenState extends ConsumerState<WakeChallengeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final List<AlarmMissionEntity> _missions;
  late final String _previewId;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _missions = widget.missions ?? WakeChallengeScreen.demoChain;
    // Unique id so re-opening the preview always gets a fresh mission sequence.
    _previewId = 'preview-${DateTime.now().microsecondsSinceEpoch}';

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    AlarmSound.instance.start();
    _safeWakelock(true);
  }

  Future<void> _safeWakelock(bool on) async {
    try {
      on ? await WakelockPlus.enable() : await WakelockPlus.disable();
    } catch (_) {
      // Unsupported on this platform (e.g. http web) — ignore.
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pulse.dispose();
    AlarmSound.instance.stop();
    _safeWakelock(false);
    super.dispose();
  }

  Future<void> _exit() async {
    await AlarmSound.instance.stop();
    if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  Future<void> _onAllMissionsComplete() async {
    await AlarmSound.instance.stop();
    // Let the success view show briefly before leaving.
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Block accidental back; the preview offers an explicit exit button.
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B12),
        body: _started ? _buildMissions() : _buildRingFace(),
      ),
    );
  }

  Widget _buildMissions() {
    return MissionScreen(
      alarmId: _previewId,
      alarmLabel: widget.label ?? AppLocalizations.of(context).ringWakeUpLoud,
      missions: _missions,
      onAllMissionsComplete: _onAllMissionsComplete,
    );
  }

  Widget _buildRingFace() {
    final l10n = AppLocalizations.of(context);
    final hh = _now.hour.toString().padLeft(2, '0');
    final mm = _now.minute.toString().padLeft(2, '0');

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value; // 0..1
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.2,
              colors: [
                Color.lerp(const Color(0xFF3A0E12), const Color(0xFF7A1020), t)!,
                const Color(0xFF0B0B12),
              ],
            ),
          ),
          child: child,
        );
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  onPressed: _exit,
                  icon: const Icon(Icons.close, color: Colors.white54),
                  label: Text(l10n.ringExitDemo,
                      style: const TextStyle(color: Colors.white54)),
                ),
              ),
              const Spacer(),
              // Wobbling bell.
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Transform.rotate(
                  angle: (_pulse.value - 0.5) * 0.5,
                  child: const Icon(Icons.notifications_active,
                      size: 96, color: Colors.amber),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.ringWakeUpLoud,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$hh:$mm',
                style: const TextStyle(fontSize: 28, color: Colors.white70),
              ),
              const SizedBox(height: 28),
              _MissionPreviewChips(missions: _missions),
              const SizedBox(height: 12),
              Text(
                l10n.ringCompleteEveryMission,
                style: const TextStyle(color: Colors.white60),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => setState(() => _started = true),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    l10n.ringImAwakeStartMissions,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small row of chips summarising the mission chain on the ring face.
class _MissionPreviewChips extends StatelessWidget {
  const _MissionPreviewChips({required this.missions});

  final List<AlarmMissionEntity> missions;

  IconData _icon(MissionKind? k) => switch (k) {
        MissionKind.shake => Icons.vibration,
        MissionKind.math => Icons.calculate,
        MissionKind.objectDetection => Icons.camera_alt,
        null => Icons.help_outline,
      };

  String _label(BuildContext context, MissionKind? k) {
    final l10n = AppLocalizations.of(context);
    return switch (k) {
      MissionKind.shake => l10n.ringChipShake,
      MissionKind.math => l10n.ringChipMath,
      MissionKind.objectDetection => l10n.ringChipCamera,
      null => l10n.ringChipUnknown,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < missions.length; i++)
          Chip(
            backgroundColor: Colors.white10,
            side: const BorderSide(color: Colors.white24),
            avatar: Icon(_icon(missions[i].missionType),
                size: 18, color: Colors.amber),
            label: Text(
              '${i + 1}. ${_label(context, missions[i].missionType)}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
