import 'package:equatable/equatable.dart';

import 'mission_type.dart';

/// Terminal status of a single mission attempt. Mirrors the backend's
/// `MissionHistory.status` values.
enum MissionStatus {
  completed,
  failed,
  skipped,
  abandoned;

  String get wireValue => name;

  static MissionStatus fromWire(String? value) =>
      MissionStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => MissionStatus.completed,
      );
}

/// Parameters for recording a mission attempt via `POST /missions/history`.
///
/// Kept as a pure value object (no JSON) so the use case stays serialization-
/// agnostic; the data layer builds the request body.
class RecordHistoryParams extends Equatable {
  const RecordHistoryParams({
    required this.missionType,
    required this.status,
    this.alarmId,
    this.alarmMissionId,
    this.durationSec,
    this.difficulty,
    this.metadata,
  });

  final MissionKind missionType;
  final MissionStatus status;
  final String? alarmId;
  final String? alarmMissionId;
  final int? durationSec;
  final MissionDifficulty? difficulty;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        missionType,
        status,
        alarmId,
        alarmMissionId,
        durationSec,
        difficulty,
        metadata,
      ];
}

/// Persisted mission history record returned by the server.
class MissionHistory extends Equatable {
  const MissionHistory({
    required this.id,
    required this.missionType,
    required this.status,
    required this.createdAt,
    this.durationSec,
  });

  final String id;
  final MissionKind? missionType;
  final MissionStatus status;
  final DateTime createdAt;
  final int? durationSec;

  @override
  List<Object?> get props =>
      [id, missionType, status, createdAt, durationSec];
}
