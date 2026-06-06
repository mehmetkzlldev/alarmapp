import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/ai_mission.dart';
import '../../domain/entities/math_problem.dart';
import '../../domain/entities/mission_history.dart';
import '../../domain/entities/mission_type.dart';
import '../../domain/entities/object_detection_result.dart';
import '../models/mission_models.dart';

/// Remote data source for the missions feature.
///
/// Talks to our API via [DioClient] (which normalizes errors into domain
/// [Exception]s) and uploads images directly to S3 via a *separate* bare [Dio]
/// — the presigned URL already encodes auth, so we must NOT attach our
/// `Authorization` header to that request.
abstract class MissionsRemoteDataSource {
  Future<List<MissionType>> getMissionTypes();
  Future<MathProblem> generateMathProblem(MissionDifficulty difficulty);
  Future<bool> verifyMathAnswer({required String problemId, required int answer});
  Future<UploadTarget> requestUploadUrl(String contentType);
  Future<void> uploadImage({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
  });
  Future<ObjectDetectionResult> verifyObject({
    required String s3Key,
    required String targetObject,
  });
  Future<ObjectDetectionResult> verifyObjectDirect({
    required String imageBase64,
    required String targetObject,
  });
  Future<AiMission> getTodayAiMission();
  Future<void> completeAiMission({required String id, String? imageS3Key});
  Future<MissionHistory> recordHistory(RecordHistoryParams params);
}

class MissionsRemoteDataSourceImpl implements MissionsRemoteDataSource {
  MissionsRemoteDataSourceImpl({
    required DioClient client,
    required Dio uploadDio,
  })  : _client = client,
        _uploadDio = uploadDio;

  /// Authenticated API client (adds bearer token, normalizes errors).
  final DioClient _client;

  /// Bare Dio used ONLY for presigned S3 PUTs (no Authorization header).
  final Dio _uploadDio;

  @override
  Future<List<MissionType>> getMissionTypes() async {
    final res = await _client.get<List<dynamic>>(ApiEndpoints.missionTypes);
    final data = res.data ?? const [];
    return data
        .map((e) => MissionTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MathProblem> generateMathProblem(MissionDifficulty difficulty) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.mathGenerate,
      data: {'difficulty': difficulty.wireValue},
    );
    return MathProblemModel.fromJson(res.data!);
  }

  @override
  Future<bool> verifyMathAnswer({
    required String problemId,
    required int answer,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.mathVerify,
      data: {'problemId': problemId, 'answer': answer},
    );
    return (res.data?['correct'] as bool?) ?? false;
  }

  @override
  Future<UploadTarget> requestUploadUrl(String contentType) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.objectDetectionUploadUrl,
      data: {'contentType': contentType},
    );
    return UploadTargetModel.fromJson(res.data!);
  }

  @override
  Future<void> uploadImage({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
  }) async {
    try {
      // Direct PUT to the presigned S3 URL. Content-Type MUST match what was
      // signed in the presign request, or S3 returns SignatureDoesNotMatch.
      final response = await _uploadDio.put<void>(
        uploadUrl,
        data: Stream<List<int>>.fromIterable([bytes]),
        options: Options(
          headers: {
            Headers.contentTypeHeader: contentType,
            Headers.contentLengthHeader: bytes.length,
          },
          // S3 returns 200 with an empty body on success.
          validateStatus: (status) => status != null && status >= 200 && status < 300,
        ),
      );
      // Defensive: any non-2xx slips through as a thrown DioException already.
      if (response.statusCode == null) {
        throw ServerException(message: 'Upload failed: empty response from S3');
      }
    } on DioException catch (e) {
      // S3 errors are XML, not our JSON envelope — surface a clear message.
      throw ServerException(
        message: 'Failed to upload image to storage.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<ObjectDetectionResult> verifyObject({
    required String s3Key,
    required String targetObject,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.objectDetectionVerify,
      data: {'s3Key': s3Key, 'targetObject': targetObject},
    );
    return ObjectDetectionResultModel.fromJson(res.data!);
  }

  @override
  Future<ObjectDetectionResult> verifyObjectDirect({
    required String imageBase64,
    required String targetObject,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.objectDetectionVerifyImage,
      data: {'imageBase64': imageBase64, 'targetObject': targetObject},
    );
    return ObjectDetectionResultModel.fromJson(res.data!);
  }

  @override
  Future<AiMission> getTodayAiMission() async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.aiMissionToday,
    );
    return AiMissionModel.fromJson(res.data!);
  }

  @override
  Future<void> completeAiMission({required String id, String? imageS3Key}) async {
    await _client.post<Map<String, dynamic>>(
      ApiEndpoints.aiMissionComplete(id),
      data: {if (imageS3Key != null) 'imageS3Key': imageS3Key},
    );
  }

  @override
  Future<MissionHistory> recordHistory(RecordHistoryParams params) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.missionHistory,
      data: MissionHistoryModel.toRequestJson(params),
    );
    return MissionHistoryModel.fromJson(res.data!);
  }
}
