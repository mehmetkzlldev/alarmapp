import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/ai_mission.dart';
import '../entities/math_problem.dart';
import '../entities/mission_history.dart';
import '../entities/mission_type.dart';
import '../entities/object_detection_result.dart';

/// Contract for mission-related data access, owned by the domain layer.
///
/// Coordinates the remote API (math problem generation/verification, object
/// detection upload+verify, AI missions, and history). Every method returns
/// `Either<Failure, T>` so callers never see raw exceptions.
abstract class MissionsRepository {
  /// `GET /missions/types` — the catalog of mission types the user can pick.
  Future<Either<Failure, List<MissionType>>> getMissionTypes();

  /// `POST /missions/math/generate` — server generates a problem and caches the
  /// answer in Redis. The answer is never returned to the client.
  Future<Either<Failure, MathProblem>> generateMathProblem(
    MissionDifficulty difficulty,
  );

  /// `POST /missions/math/verify` — checks the user's answer against the
  /// server-cached solution. Returns whether it was correct.
  Future<Either<Failure, bool>> verifyMathAnswer({
    required String problemId,
    required int answer,
  });

  /// `POST /object-detection/upload-url` — request a short-TTL presigned PUT
  /// URL for uploading a captured image to the private S3 bucket.
  Future<Either<Failure, UploadTarget>> requestUploadUrl(String contentType);

  /// Uploads the image bytes directly to S3 via the presigned [uploadUrl].
  /// Returns the [s3Key] on success so it can be passed to verification.
  Future<Either<Failure, Unit>> uploadImage({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
  });

  /// `POST /object-detection/verify` — asks the backend (Gemini) whether the
  /// uploaded image contains [targetObject].
  Future<Either<Failure, ObjectDetectionResult>> verifyObject({
    required String s3Key,
    required String targetObject,
  });

  /// `POST /object-detection/verify-image` — sends the captured photo inline as
  /// base64 (no S3 round-trip) and asks the backend (Gemini) whether it
  /// contains [targetObject].
  Future<Either<Failure, ObjectDetectionResult>> verifyObjectDirect({
    required String imageBase64,
    required String targetObject,
  });

  /// `GET /ai-missions/today` — the daily AI mission. PREMIUM-GATED: a
  /// [PremiumRequiredFailure] is returned for free users.
  Future<Either<Failure, AiMission>> getTodayAiMission();

  /// `POST /ai-missions/:id/complete` — mark the daily AI mission complete.
  Future<Either<Failure, Unit>> completeAiMission({
    required String id,
    String? imageS3Key,
  });

  /// `POST /missions/history` — record the outcome of a mission attempt.
  Future<Either<Failure, MissionHistory>> recordHistory(
    RecordHistoryParams params,
  );
}
