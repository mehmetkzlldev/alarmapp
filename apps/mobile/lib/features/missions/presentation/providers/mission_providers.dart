import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../data/datasources/missions_remote_datasource.dart';
import '../../data/repositories/missions_repository_impl.dart';
import '../../domain/repositories/missions_repository.dart';
import '../../domain/usecases/generate_math.dart';
import '../../domain/usecases/get_today_ai_mission.dart';
import '../../domain/usecases/record_history.dart';
import '../../domain/usecases/verify_math.dart';
import '../../domain/usecases/verify_object.dart';

/// Dependency-injection graph for the missions feature, wired with plain
/// Riverpod providers (no codegen) so it composes with the rest of the app.

/// Bare [Dio] used exclusively for presigned S3 PUT uploads.
///
/// It deliberately does NOT reuse [dioProvider] because that client injects our
/// `Authorization` header — sending it alongside a presigned URL can make S3
/// reject the request with SignatureDoesNotMatch.
final s3UploadDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
});

final missionsRemoteDataSourceProvider =
    Provider<MissionsRemoteDataSource>((ref) {
  return MissionsRemoteDataSourceImpl(
    client: ref.watch(dioClientProvider),
    uploadDio: ref.watch(s3UploadDioProvider),
  );
});

final missionsRepositoryProvider = Provider<MissionsRepository>((ref) {
  return MissionsRepositoryImpl(ref.watch(missionsRemoteDataSourceProvider));
});

// ---- Use cases -------------------------------------------------------------

final generateMathProvider = Provider<GenerateMath>(
  (ref) => GenerateMath(ref.watch(missionsRepositoryProvider)),
);

final verifyMathProvider = Provider<VerifyMath>(
  (ref) => VerifyMath(ref.watch(missionsRepositoryProvider)),
);

final verifyObjectProvider = Provider<VerifyObject>(
  (ref) => VerifyObject(ref.watch(missionsRepositoryProvider)),
);

final getTodayAiMissionProvider = Provider<GetTodayAiMission>(
  (ref) => GetTodayAiMission(ref.watch(missionsRepositoryProvider)),
);

final recordHistoryProvider = Provider<RecordHistory>(
  (ref) => RecordHistory(ref.watch(missionsRepositoryProvider)),
);
