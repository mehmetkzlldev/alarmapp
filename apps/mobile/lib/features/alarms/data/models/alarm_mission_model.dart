import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../missions/domain/entities/mission_type.dart';
import '../../domain/entities/alarm_mission_entity.dart';

part 'alarm_mission_model.freezed.dart';
part 'alarm_mission_model.g.dart';

/// Data-layer DTO for an alarm mission.
///
/// Serializes VERBATIM to the API contract shape used by
/// `GET/POST /alarms/:id/missions`:
/// `{ missionType, difficulty, orderIndex, config }` (plus `id`/`alarmId` on
/// reads). `missionType` and `difficulty` are wire strings (`"object_detection"`,
/// `"medium"`, ...) handled via [MissionKind.wireValue] / [MissionDifficulty].
///
/// The same model is reused as the offline-cache row (it is plain JSON), so the
/// cached alarms can rebuild missions for the native scheduler when offline.
@freezed
class AlarmMissionModel with _$AlarmMissionModel {
  const AlarmMissionModel._();

  const factory AlarmMissionModel({
    @Default('') String id,
    @Default('') String alarmId,
    // Stored as the raw wire string so unknown/forward-compat values survive a
    // cache round-trip; converted to the typed [MissionKind] in [toEntity].
    required String missionType,
    @Default('medium') String difficulty,
    @Default(0) int orderIndex,
    @Default(<String, dynamic>{}) Map<String, dynamic> config,
  }) = _AlarmMissionModel;

  factory AlarmMissionModel.fromJson(Map<String, dynamic> json) =>
      _$AlarmMissionModelFromJson(json);

  /// Body shape for `POST /alarms/:id/missions` and for inline missions in the
  /// `POST /alarms` payload. Excludes server-managed `id`/`alarmId`.
  Map<String, dynamic> toCreateJson() => <String, dynamic>{
        'missionType': missionType,
        'difficulty': difficulty,
        'orderIndex': orderIndex,
        'config': config,
      };

  AlarmMissionEntity toEntity() => AlarmMissionEntity(
        id: id,
        missionType: MissionKind.fromWire(missionType),
        difficulty: MissionDifficulty.fromWire(difficulty),
        orderIndex: orderIndex,
        config: config,
      );

  factory AlarmMissionModel.fromEntity(AlarmMissionEntity e) =>
      AlarmMissionModel(
        id: e.id,
        // A `null` kind cannot be persisted/sent; default to math so we never
        // emit an invalid wire value. UI prevents null-kind missions from being
        // added in the first place.
        missionType: e.missionType?.wireValue ?? MissionKind.math.wireValue,
        difficulty: e.difficulty.wireValue,
        orderIndex: e.orderIndex,
        config: e.config,
      );
}
