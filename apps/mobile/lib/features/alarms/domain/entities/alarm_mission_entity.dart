import 'package:equatable/equatable.dart';

// Reuse the canonical, wire-aligned enums owned by the missions feature so the
// whole app speaks one vocabulary for mission kinds/difficulty.
import '../../../missions/domain/entities/mission_type.dart';

export '../../../missions/domain/entities/mission_type.dart'
    show MissionKind, MissionDifficulty;

/// Pure domain entity for a mission attached to an alarm.
///
/// This is the alarms-feature view of the shared `AlarmMission` shape returned
/// by `GET/POST /alarms/:id/missions`. It is framework- and JSON-agnostic; the
/// `data` layer's `AlarmMissionModel` handles (de)serialization and maps to/from
/// this entity.
///
/// A user must complete every mission attached to an alarm (in [orderIndex]
/// order) before the alarm can be dismissed.
class AlarmMissionEntity extends Equatable {
  const AlarmMissionEntity({
    required this.id,
    required this.missionType,
    required this.difficulty,
    required this.orderIndex,
    this.config = const {},
  });

  /// Server id. Empty for missions composed locally on the create screen that
  /// have not yet been persisted (they are sent inline with `POST /alarms`).
  final String id;

  /// The mission kind. `null` when the server advertised a type this client
  /// build does not understand (forward compatibility) — such missions are
  /// filtered out of the create UI and treated as auto-pass at ring time.
  final MissionKind? missionType;

  final MissionDifficulty difficulty;

  /// Order the missions must be completed in to dismiss the alarm.
  final int orderIndex;

  /// Opaque, per-type configuration blob. For object-detection this carries
  /// `{ "targetObject": "toothbrush" }`; for shake `{ "shakeCount": 30 }`.
  final Map<String, dynamic> config;

  /// Object-detection target (one of the supported targets), if configured.
  String? get targetObject => config['targetObject'] as String?;

  AlarmMissionEntity copyWith({
    String? id,
    MissionKind? missionType,
    MissionDifficulty? difficulty,
    int? orderIndex,
    Map<String, dynamic>? config,
  }) {
    return AlarmMissionEntity(
      id: id ?? this.id,
      missionType: missionType ?? this.missionType,
      difficulty: difficulty ?? this.difficulty,
      orderIndex: orderIndex ?? this.orderIndex,
      config: config ?? this.config,
    );
  }

  @override
  List<Object?> get props => [id, missionType, difficulty, orderIndex, config];
}
