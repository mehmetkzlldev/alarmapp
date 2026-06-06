import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../alarms/domain/entities/alarm_mission_entity.dart';
import '../../domain/entities/mission_history.dart';
import '../../domain/entities/mission_type.dart';
import '../../domain/usecases/record_history.dart';
import 'mission_providers.dart';

/// High-level status of the *overall* mission sequence required to dismiss an
/// alarm.
enum MissionSequenceStatus {
  /// At least one mission still has to be completed.
  inProgress,

  /// Every mission in the sequence passed — the alarm may be dismissed.
  success,

  /// The current mission attempt failed (the user can retry).
  failed,
}

/// Immutable state for the mission sequence state machine.
class MissionSequenceState {
  const MissionSequenceState({
    required this.missions,
    required this.currentIndex,
    required this.status,
    this.errorMessage,
  });

  /// The ordered list of missions (already sorted by [orderIndex]).
  final List<AlarmMissionEntity> missions;

  /// Index of the mission currently being attempted.
  final int currentIndex;

  /// Overall sequence status.
  final MissionSequenceStatus status;

  /// Optional message shown after a failed attempt.
  final String? errorMessage;

  /// The mission the user is currently working on, or `null` when the sequence
  /// is empty or already complete.
  AlarmMissionEntity? get currentMission =>
      currentIndex >= 0 && currentIndex < missions.length
          ? missions[currentIndex]
          : null;

  bool get isComplete => status == MissionSequenceStatus.success;

  /// 1-based human-friendly step number, e.g. "Mission 2 of 3".
  int get stepNumber => currentIndex + 1;
  int get totalSteps => missions.length;

  /// Fraction completed (0..1) — used by progress indicators.
  double get progress =>
      missions.isEmpty ? 1.0 : (currentIndex / missions.length).clamp(0.0, 1.0);

  MissionSequenceState copyWith({
    List<AlarmMissionEntity>? missions,
    int? currentIndex,
    MissionSequenceStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MissionSequenceState(
      missions: missions ?? this.missions,
      currentIndex: currentIndex ?? this.currentIndex,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// State-machine controller for the sequence of missions required to dismiss a
/// single alarm.
///
/// Responsibilities:
///  * Order the alarm's missions by [AlarmMissionEntity.orderIndex].
///  * Track which mission is active and whether the last attempt passed/failed.
///  * On each mission success, record history and advance; when the final
///    mission passes, fire [onMissionComplete] so the alarm screen can dismiss.
///
/// Mission *widgets* (math/shake/object-detection) own their internal attempt
/// logic and call [completeCurrent]/[failCurrent] on this controller.
class MissionSequenceController extends StateNotifier<MissionSequenceState> {
  MissionSequenceController({
    required List<AlarmMissionEntity> missions,
    required RecordHistory recordHistory,
    this.alarmId,
  })  : _recordHistory = recordHistory,
        super(
          MissionSequenceState(
            missions: _sortedRenderable(missions),
            currentIndex: 0,
            // An empty (or all auto-pass) sequence is immediately successful so
            // we never trap the user behind a mission we cannot render.
            status: _sortedRenderable(missions).isEmpty
                ? MissionSequenceStatus.success
                : MissionSequenceStatus.inProgress,
          ),
        );

  final RecordHistory _recordHistory;
  final String? alarmId;

  /// Called exactly once when the entire sequence is completed. The alarm
  /// screen assigns this to perform the actual dismissal (stop sound, pop nav).
  void Function()? onMissionComplete;

  /// Tracks when the current mission attempt started, for `durationSec`.
  DateTime _currentStartedAt = DateTime.now();

  /// Sorts missions by order index and drops any the client cannot render
  /// (unknown [missionType]) so unknown server types behave as auto-pass.
  static List<AlarmMissionEntity> _sortedRenderable(
    List<AlarmMissionEntity> missions,
  ) {
    final renderable =
        missions.where((m) => m.missionType != null).toList(growable: false);
    final sorted = [...renderable]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return sorted;
  }

  /// Marks the current mission as passed: records history, then advances to the
  /// next mission or finishes the sequence.
  Future<void> completeCurrent({Map<String, dynamic>? metadata}) async {
    final mission = state.currentMission;
    if (mission == null) {
      // Nothing to complete (empty sequence) — treat as success.
      _finishSequence();
      return;
    }

    await _record(
      mission: mission,
      status: MissionStatus.completed,
      metadata: metadata,
    );

    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.missions.length) {
      _finishSequence();
    } else {
      _currentStartedAt = DateTime.now();
      state = state.copyWith(
        currentIndex: nextIndex,
        status: MissionSequenceStatus.inProgress,
        clearError: true,
      );
    }
  }

  /// Marks the current attempt as failed so the UI can prompt a retry. Does NOT
  /// advance; the same mission must be retried.
  Future<void> failCurrent({
    String message = 'Mission failed. Try again.',
    Map<String, dynamic>? metadata,
  }) async {
    final mission = state.currentMission;
    if (mission != null) {
      await _record(
        mission: mission,
        status: MissionStatus.failed,
        metadata: metadata,
      );
    }
    state = state.copyWith(
      status: MissionSequenceStatus.failed,
      errorMessage: message,
    );
  }

  /// Clears a failure and lets the user retry the current mission.
  void retry() {
    _currentStartedAt = DateTime.now();
    state = state.copyWith(
      status: MissionSequenceStatus.inProgress,
      clearError: true,
    );
  }

  void _finishSequence() {
    state = state.copyWith(
      status: MissionSequenceStatus.success,
      clearError: true,
    );
    onMissionComplete?.call();
  }

  /// Records a history entry, swallowing failures: telemetry must never block
  /// dismissal of an alarm.
  Future<void> _record({
    required AlarmMissionEntity mission,
    required MissionStatus status,
    Map<String, dynamic>? metadata,
  }) async {
    final type = mission.missionType;
    if (type == null) return;
    final durationSec =
        DateTime.now().difference(_currentStartedAt).inSeconds.abs();
    await _recordHistory(
      RecordHistoryParams(
        alarmId: alarmId,
        alarmMissionId: mission.id.isEmpty ? null : mission.id,
        missionType: type,
        status: status,
        durationSec: durationSec,
        difficulty: mission.difficulty,
        metadata: metadata,
      ),
    );
    // Result intentionally ignored — see method doc.
  }
}

/// Family provider keyed by the list of missions. The alarm-ring screen creates
/// it with the alarm's missions and wires [onMissionComplete] to its dismissal
/// routine.
///
/// We key on the alarm id so re-entering the same alarm reuses the controller,
/// while different alarms get isolated state.
final missionSequenceControllerProvider = StateNotifierProvider.family<
    MissionSequenceController,
    MissionSequenceState,
    MissionSequenceArgs>((ref, args) {
  return MissionSequenceController(
    missions: args.missions,
    alarmId: args.alarmId,
    recordHistory: ref.watch(recordHistoryProvider),
  );
});

/// Argument bundle for [missionSequenceControllerProvider]. Equality is based on
/// the alarm id so the family key is stable across rebuilds.
class MissionSequenceArgs {
  const MissionSequenceArgs({required this.alarmId, required this.missions});

  final String? alarmId;
  final List<AlarmMissionEntity> missions;

  @override
  bool operator ==(Object other) =>
      other is MissionSequenceArgs && other.alarmId == alarmId;

  @override
  int get hashCode => alarmId.hashCode;
}
