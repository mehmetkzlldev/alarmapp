/// Hand-written data-layer models for the missions feature.
///
/// These map the camelCase JSON of the API contract to the pure domain
/// entities. They are intentionally NOT Freezed/codegen so the feature compiles
/// without running build_runner; the mapping is small and explicit.
library;

import '../../domain/entities/ai_mission.dart';
import '../../domain/entities/math_problem.dart';
import '../../domain/entities/mission_history.dart';
import '../../domain/entities/mission_type.dart';
import '../../domain/entities/object_detection_result.dart';

/// `GET /missions/types` element.
class MissionTypeModel {
  const MissionTypeModel._();

  static MissionType fromJson(Map<String, dynamic> json) {
    return MissionType(
      kind: MissionKind.fromWire(json['missionType'] as String?),
      displayName: json['displayName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      premiumOnly: json['premiumOnly'] as bool? ?? false,
      supportedTargets: (json['supportedTargets'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
    );
  }
}

/// `POST /missions/math/generate` response.
class MathProblemModel {
  const MathProblemModel._();

  static MathProblem fromJson(Map<String, dynamic> json) {
    return MathProblem(
      problemId: json['problemId'] as String,
      expression: json['expression'] as String,
      operandCount: (json['operandCount'] as num?)?.toInt() ?? 2,
    );
  }
}

/// `POST /object-detection/upload-url` response.
class UploadTargetModel {
  const UploadTargetModel._();

  static UploadTarget fromJson(Map<String, dynamic> json) {
    return UploadTarget(
      uploadUrl: json['uploadUrl'] as String,
      s3Key: json['s3Key'] as String,
    );
  }
}

/// `POST /object-detection/verify` response.
class ObjectDetectionResultModel {
  const ObjectDetectionResultModel._();

  static ObjectDetectionResult fromJson(Map<String, dynamic> json) {
    return ObjectDetectionResult(
      isMatch: json['isMatch'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      detectedObjects: (json['detectedObjects'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      reasoning: json['reasoning'] as String? ?? '',
    );
  }
}

/// `GET /ai-missions/today` response.
class AiMissionModel {
  const AiMissionModel._();

  static AiMission fromJson(Map<String, dynamic> json) {
    return AiMission(
      id: json['id'] as String,
      missionType: MissionKind.fromWire(json['missionType'] as String?),
      difficulty: MissionDifficulty.fromWire(json['difficulty'] as String?),
      instruction: json['instruction'] as String? ?? '',
      targetObject: json['targetObject'] as String?,
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }
}

/// `POST /missions/history` request/response.
class MissionHistoryModel {
  const MissionHistoryModel._();

  /// Builds the request body from [RecordHistoryParams]. Only sets the optional
  /// keys that are present so the backend treats omitted ones as unset.
  static Map<String, dynamic> toRequestJson(RecordHistoryParams params) {
    return {
      if (params.alarmId != null) 'alarmId': params.alarmId,
      if (params.alarmMissionId != null) 'alarmMissionId': params.alarmMissionId,
      'missionType': params.missionType.wireValue,
      'status': params.status.wireValue,
      if (params.durationSec != null) 'durationSec': params.durationSec,
      if (params.difficulty != null) 'difficulty': params.difficulty!.wireValue,
      if (params.metadata != null) 'metadata': params.metadata,
    };
  }

  static MissionHistory fromJson(Map<String, dynamic> json) {
    return MissionHistory(
      id: json['id'] as String,
      missionType: MissionKind.fromWire(json['missionType'] as String?),
      status: MissionStatus.fromWire(json['status'] as String?),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      durationSec: (json['durationSec'] as num?)?.toInt(),
    );
  }
}
