import 'package:equatable/equatable.dart';

/// Pure domain entity for the result of an object-detection verification.
///
/// Mirrors `POST /object-detection/verify` ->
/// `{ isMatch, confidence, detectedObjects, reasoning }`.
class ObjectDetectionResult extends Equatable {
  const ObjectDetectionResult({
    required this.isMatch,
    required this.confidence,
    required this.detectedObjects,
    required this.reasoning,
  });

  /// Whether the target object was detected with sufficient confidence.
  /// ONLY a `true` value dismisses the mission.
  final bool isMatch;

  /// Model confidence in the range 0..1. Surfaced in the UI as a percentage.
  final double confidence;

  /// All objects the model saw in the frame (for transparency / debugging UX).
  final List<String> detectedObjects;

  /// Short natural-language explanation from the model.
  final String reasoning;

  /// Confidence as an integer percentage for display, e.g. 0.87 -> 87.
  int get confidencePercent => (confidence * 100).round().clamp(0, 100);

  @override
  List<Object?> get props => [isMatch, confidence, detectedObjects, reasoning];
}

/// Result of requesting an S3 presigned upload URL.
///
/// Mirrors `POST /object-detection/upload-url` -> `{ uploadUrl, s3Key }`.
class UploadTarget extends Equatable {
  const UploadTarget({required this.uploadUrl, required this.s3Key});

  /// Short-TTL presigned PUT URL. The image bytes are uploaded directly here;
  /// they never transit our own API server.
  final String uploadUrl;

  /// The object key to pass back to `/object-detection/verify`.
  final String s3Key;

  @override
  List<Object?> get props => [uploadUrl, s3Key];
}
