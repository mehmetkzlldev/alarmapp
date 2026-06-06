import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/object_detection_result.dart';
import '../repositories/missions_repository.dart';

/// Full object-detection verification flow, orchestrated as a single use case:
///
///   1. `POST /object-detection/upload-url` -> presigned PUT URL + s3Key
///   2. PUT the image bytes directly to S3 (private bucket, short-TTL URL)
///   3. `POST /object-detection/verify` -> AI match result
///
/// Bundling these keeps the presentation layer simple: it hands over the
/// captured bytes + target object and receives a single [ObjectDetectionResult].
class VerifyObject implements UseCase<ObjectDetectionResult, VerifyObjectParams> {
  const VerifyObject(this._repository);

  final MissionsRepository _repository;

  @override
  Future<Either<Failure, ObjectDetectionResult>> call(
    VerifyObjectParams params,
  ) {
    // Send the captured photo inline as base64 to the backend (Gemini). This
    // replaces the older 3-step S3 upload flow, so detection works without any
    // object-storage credentials configured.
    final imageBase64 = base64Encode(params.bytes);
    return _repository.verifyObjectDirect(
      imageBase64: imageBase64,
      targetObject: params.targetObject,
    );
  }
}

class VerifyObjectParams extends Equatable {
  const VerifyObjectParams({
    required this.bytes,
    required this.targetObject,
    this.contentType = 'image/jpeg',
  });

  /// The captured image bytes (JPEG by default).
  final List<int> bytes;

  /// One of the supported targets (toothbrush, sink, coffee mug, keys, shoes,
  /// laptop).
  final String targetObject;

  final String contentType;

  @override
  List<Object?> get props => [bytes, targetObject, contentType];
}
