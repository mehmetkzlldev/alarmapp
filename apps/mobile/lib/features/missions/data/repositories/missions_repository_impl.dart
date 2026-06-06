import 'package:dartz/dartz.dart';

import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/ai_mission.dart';
import '../../domain/entities/math_problem.dart';
import '../../domain/entities/mission_history.dart';
import '../../domain/entities/mission_type.dart';
import '../../domain/entities/object_detection_result.dart';
import '../../domain/repositories/missions_repository.dart';
import '../datasources/missions_remote_datasource.dart';

/// Concrete [MissionsRepository] backed by the remote API.
///
/// Wraps every data-source call in a try/catch that funnels exceptions through
/// [mapExceptionToFailure], so the presentation layer only ever sees [Failure]s.
class MissionsRepositoryImpl implements MissionsRepository {
  MissionsRepositoryImpl(this._remote);

  final MissionsRemoteDataSource _remote;

  /// Shared guard: runs [action], returns `Right(value)` on success, or
  /// `Left(Failure)` for any thrown exception.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<MissionType>>> getMissionTypes() =>
      _guard(_remote.getMissionTypes);

  @override
  Future<Either<Failure, MathProblem>> generateMathProblem(
    MissionDifficulty difficulty,
  ) =>
      _guard(() => _remote.generateMathProblem(difficulty));

  @override
  Future<Either<Failure, bool>> verifyMathAnswer({
    required String problemId,
    required int answer,
  }) =>
      _guard(() => _remote.verifyMathAnswer(problemId: problemId, answer: answer));

  @override
  Future<Either<Failure, UploadTarget>> requestUploadUrl(String contentType) =>
      _guard(() => _remote.requestUploadUrl(contentType));

  @override
  Future<Either<Failure, Unit>> uploadImage({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
  }) =>
      _guard(() async {
        await _remote.uploadImage(
          uploadUrl: uploadUrl,
          bytes: bytes,
          contentType: contentType,
        );
        return unit;
      });

  @override
  Future<Either<Failure, ObjectDetectionResult>> verifyObject({
    required String s3Key,
    required String targetObject,
  }) =>
      _guard(() => _remote.verifyObject(s3Key: s3Key, targetObject: targetObject));

  @override
  Future<Either<Failure, ObjectDetectionResult>> verifyObjectDirect({
    required String imageBase64,
    required String targetObject,
  }) =>
      _guard(() => _remote.verifyObjectDirect(
            imageBase64: imageBase64,
            targetObject: targetObject,
          ));

  @override
  Future<Either<Failure, AiMission>> getTodayAiMission() =>
      _guard(_remote.getTodayAiMission);

  @override
  Future<Either<Failure, Unit>> completeAiMission({
    required String id,
    String? imageS3Key,
  }) =>
      _guard(() async {
        await _remote.completeAiMission(id: id, imageS3Key: imageS3Key);
        return unit;
      });

  @override
  Future<Either<Failure, MissionHistory>> recordHistory(
    RecordHistoryParams params,
  ) =>
      _guard(() => _remote.recordHistory(params));
}
