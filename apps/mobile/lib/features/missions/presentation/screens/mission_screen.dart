import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarmy/l10n/app_localizations.dart';
import '../../../alarms/domain/entities/alarm_mission_entity.dart';
import '../../domain/entities/mission_type.dart';
import '../providers/mission_provider.dart';
import '../widgets/math_mission.dart';
import '../widgets/object_detection_mission.dart';
import '../widgets/shake_mission.dart';

/// Full-screen flow the user must clear to dismiss a ringing alarm.
///
/// Responsibilities:
///  * Build the [MissionSequenceController] from the alarm's missions.
///  * Wire its [onMissionComplete] to [onAllMissionsComplete] (provided by the
///    alarm-ring layer, which stops the sound and closes the screen).
///  * Render the widget for the *current* mission and show overall progress.
///
/// The screen is intentionally un-dismissable (no back button, ignores the
/// system back gesture) until every mission passes — that is the whole point of
/// an Alarmy-style alarm. It forces a dark, high-contrast theme on its subtree
/// so every mission widget reads as urgent regardless of the app theme.
class MissionScreen extends ConsumerStatefulWidget {
  const MissionScreen({
    super.key,
    required this.alarmId,
    required this.missions,
    required this.onAllMissionsComplete,
    this.alarmLabel,
  });

  /// The alarm whose missions are being run. May be null for ad-hoc/preview.
  final String? alarmId;

  /// Missions configured on the alarm (any order; the controller sorts them).
  final List<AlarmMissionEntity> missions;

  /// Called once every mission is cleared. The alarm-ring controller assigns
  /// this to stop the alarm and pop the route.
  final VoidCallback onAllMissionsComplete;

  /// Optional label shown in the header (e.g. "Wake up!").
  final String? alarmLabel;

  @override
  ConsumerState<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends ConsumerState<MissionScreen> {
  late final MissionSequenceArgs _args;

  @override
  void initState() {
    super.initState();
    _args = MissionSequenceArgs(
      alarmId: widget.alarmId,
      missions: widget.missions,
    );

    // Wire the completion callback onto the controller after first frame so the
    // notifier exists. We also handle the degenerate "no missions" case where
    // the controller starts already-successful.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller =
          ref.read(missionSequenceControllerProvider(_args).notifier);
      controller.onMissionComplete = widget.onAllMissionsComplete;

      final state = ref.read(missionSequenceControllerProvider(_args));
      if (state.status == MissionSequenceStatus.success) {
        widget.onAllMissionsComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(missionSequenceControllerProvider(_args));
    final controller =
        ref.read(missionSequenceControllerProvider(_args).notifier);

    // Force a dark, high-contrast theme so mission widgets are legible and
    // intense on the dark ring background.
    final theme = ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF5A3C),
        brightness: Brightness.dark,
      ),
    );

    return Theme(
      data: theme,
      child: PopScope(
        // Block back navigation: the alarm cannot be escaped until missions pass.
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A0E12), Color(0xFF0B0B12)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _Header(
                    label:
                        widget.alarmLabel ?? AppLocalizations.of(context).ringWakeUpExclaim,
                    step: state.stepNumber,
                    total: state.totalSteps,
                    progress: state.progress,
                    kind: state.currentMission?.missionType,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _buildBody(state, controller, theme),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    MissionSequenceState state,
    MissionSequenceController controller,
    ThemeData theme,
  ) {
    if (state.status == MissionSequenceStatus.success) {
      return const _SuccessView(key: ValueKey('success'));
    }

    final mission = state.currentMission;
    if (mission == null) {
      return const SizedBox.shrink();
    }

    final missionWidget = _missionWidgetFor(mission, controller);

    return Stack(
      key: ValueKey('mission_${mission.id}_${state.currentIndex}'),
      children: [
        Positioned.fill(child: missionWidget),
        if (state.status == MissionSequenceStatus.failed &&
            state.errorMessage != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _FailureBanner(
              message: state.errorMessage!,
              onDismiss: controller.retry,
            ),
          ),
      ],
    );
  }

  /// Routes the current mission to the appropriate widget based on its kind.
  Widget _missionWidgetFor(
    AlarmMissionEntity mission,
    MissionSequenceController controller,
  ) {
    switch (mission.missionType) {
      case MissionKind.math:
        return MathMission(
          key: ValueKey('math_${mission.id}'),
          mission: mission,
          onSolved: () => controller.completeCurrent(),
          onFailed: (msg) => controller.failCurrent(message: msg),
        );
      case MissionKind.shake:
        return ShakeMission(
          key: ValueKey('shake_${mission.id}'),
          mission: mission,
          onCompleted: () => controller.completeCurrent(),
        );
      case MissionKind.objectDetection:
        return ObjectDetectionMission(
          key: ValueKey('object_${mission.id}'),
          mission: mission,
          onVerified: () => controller.completeCurrent(),
          onFailed: (msg) => controller.failCurrent(message: msg),
        );
      case null:
        // Unknown mission type (forward-compat): auto-complete so the user is
        // never trapped behind something this build cannot render.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => controller.completeCurrent(),
        );
        return const Center(child: CircularProgressIndicator());
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.label,
    required this.step,
    required this.total,
    required this.progress,
    required this.kind,
  });

  final String label;
  final int step;
  final int total;
  final double progress;
  final MissionKind? kind;

  String _kindLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (kind) {
      MissionKind.shake => l10n.missionKindShake,
      MissionKind.math => l10n.missionKindMath,
      MissionKind.objectDetection => l10n.missionKindCamera,
      null => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alarm, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (total > 1)
            Text(
              l10n.missionStepOfTotal(step, total, _kindLabel(context)),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 110, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            l10n.missionAlarmDismissed,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(l10n.missionHaveAGreatDay, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Material(
      color: theme.colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onErrorContainer),
              ),
            ),
            TextButton(onPressed: onDismiss, child: Text(l10n.missionRetry)),
          ],
        ),
      ),
    );
  }
}
