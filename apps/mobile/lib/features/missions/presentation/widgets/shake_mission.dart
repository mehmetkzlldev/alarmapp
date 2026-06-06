import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:alarmy/l10n/app_localizations.dart';
import '../../../alarms/domain/entities/alarm_mission_entity.dart';

/// Default shake DURATION (seconds) per difficulty when the alarm mission config
/// does not specify `shakeSeconds`.
int _defaultShakeSeconds(MissionDifficulty difficulty) {
  switch (difficulty) {
    case MissionDifficulty.easy:
      return 6;
    case MissionDifficulty.medium:
      return 10;
    case MissionDifficulty.hard:
      return 15;
  }
}

/// Shake mission — the user must keep the device shaking for N seconds.
///
/// "Shaking" is detected from the accelerometer (`sensors_plus`) on mobile and,
/// on every platform — and as the SOLE input on the web, which has no
/// accelerometer — by rapidly tapping/dragging the shake pad. The active-shake
/// timer only advances while motion is recent, so the user really has to keep
/// going for the full duration (pausing pauses the meter; it does not drain).
class ShakeMission extends StatefulWidget {
  const ShakeMission({
    super.key,
    required this.mission,
    required this.onCompleted,
  });

  final AlarmMissionEntity mission;

  /// Invoked once the required shake duration is reached.
  final VoidCallback onCompleted;

  @override
  State<ShakeMission> createState() => _ShakeMissionState();
}

class _ShakeMissionState extends State<ShakeMission>
    with SingleTickerProviderStateMixin {
  static const double _shakeThresholdG = 1.9; // ~1.9g spike counts as motion
  static const Duration _recency = Duration(milliseconds: 650);
  static const Duration _tick = Duration(milliseconds: 100);

  StreamSubscription<AccelerometerEvent>? _accel;
  Timer? _ticker;
  late final int _targetMs;
  int _activeMs = 0;
  int _shakeCount = 0;
  DateTime _lastShakeAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _completed = false;

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    final cfg = widget.mission.config['shakeSeconds'];
    final seconds = (cfg is num)
        ? cfg.toInt()
        : _defaultShakeSeconds(widget.mission.difficulty);
    _targetMs = (seconds <= 0 ? 1 : seconds) * 1000;

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      lowerBound: 0.85,
      upperBound: 1.15,
    );

    if (!kIsWeb) {
      try {
        _accel = accelerometerEventStream().listen(_onAccel, onError: (_) {});
      } catch (_) {
        // No sensor available — taps still drive the meter.
      }
    }

    _ticker = Timer.periodic(_tick, _onTick);
  }

  @override
  void dispose() {
    _accel?.cancel();
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _onAccel(AccelerometerEvent e) {
    final g = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z) / 9.81;
    if (g > _shakeThresholdG) _registerShake();
  }

  void _registerShake() {
    if (_completed) return;
    _lastShakeAt = DateTime.now();
    _shakeCount++;
    if (!_pulse.isAnimating) {
      _pulse.forward(from: 0.85).then((_) => _pulse.reverse());
    }
    HapticFeedback.lightImpact(); // no-op on web
  }

  void _onTick(Timer _) {
    if (_completed) return;
    final shakingNow = DateTime.now().difference(_lastShakeAt) < _recency;
    setState(() {
      if (shakingNow) {
        _activeMs = math.min(_activeMs + _tick.inMilliseconds, _targetMs);
      }
    });
    if (_activeMs >= _targetMs) _complete();
  }

  void _complete() {
    if (_completed) return;
    _completed = true;
    _accel?.cancel();
    _ticker?.cancel();
    HapticFeedback.heavyImpact();
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (mounted) widget.onCompleted();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final remaining = ((_targetMs - _activeMs) / 1000).ceil().clamp(0, 9999);
    final progress =
        _targetMs == 0 ? 1.0 : (_activeMs / _targetMs).clamp(0.0, 1.0);
    final shakingNow = DateTime.now().difference(_lastShakeAt) < _recency;
    final accent = _completed
        ? Colors.green
        : (shakingNow ? Colors.amber : Colors.deepOrange);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _registerShake(),
      onPanUpdate: (_) => _registerShake(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _completed ? l10n.missionShakeNice : l10n.missionShakeStart,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              kIsWeb
                  ? l10n.missionTapAsFast
                  : l10n.missionKeepShaking,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.7),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 36),
            ScaleTransition(
              scale: _pulse,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Icon(
                  _completed ? Icons.check_circle : Icons.vibration,
                  size: 96,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              _completed
                  ? l10n.missionShakeDone
                  : l10n.missionShakeRemaining(remaining.toInt()),
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.missionShakeCount(_shakeCount),
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 16,
                backgroundColor: cs.onSurface.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 14),
            if (!_completed)
              Text(
                shakingNow ? l10n.missionKeepGoing : l10n.missionShakeToRun,
                style: TextStyle(
                  color: shakingNow
                      ? Colors.amber
                      : cs.onSurface.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
