import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/platform/alarm_scheduler.dart';
import '../../domain/entities/alarm_entity.dart';
import '../../domain/entities/alarm_mission_entity.dart';
import '../../domain/repositories/alarm_repository.dart';
import '../datasources/alarm_local_datasource.dart';
import '../datasources/alarm_remote_datasource.dart';
import '../models/alarm_mission_model.dart';
import '../models/alarm_model.dart';

/// Coordinates the three concerns behind [AlarmRepository]:
///   1. the REST API (source of truth),
///   2. the offline cache (resilience + scheduler feed), and
///   3. the native [AlarmScheduler] (so alarms actually ring).
///
/// Strategy:
/// - Reads are network-first with a cache fallback when offline.
/// - Mutations go to the network first; on success we update the cache AND the
///   native scheduler so OS state, cache, and server never drift.
class AlarmRepositoryImpl implements AlarmRepository {
  AlarmRepositoryImpl({
    required AlarmRemoteDataSource remote,
    required AlarmLocalDataSource local,
    required AlarmScheduler scheduler,
  })  : _remote = remote,
        _local = local,
        _scheduler = scheduler;

  final AlarmRemoteDataSource _remote;
  final AlarmLocalDataSource _local;
  final AlarmScheduler _scheduler;

  @override
  Future<Either<Failure, List<AlarmEntity>>> getAlarms() async {
    try {
      final models = await _remote.getAlarms();
      // Refresh the cache so offline + the boot rescheduler see the latest set.
      await _local.cacheAlarms(models);
      // Reconcile native triggers with the freshly fetched truth.
      await _rescheduleAll(models);
      return Right(models.map((m) => m.toEntity()).toList());
    } on NetworkException {
      // Offline: serve the cache so the list (and alarms) keep working.
      return _fromCacheList();
    } on PremiumRequiredException catch (e) {
      return Left(PremiumRequiredFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, AlarmEntity>> getAlarm(String id) async {
    try {
      final model = await _remote.getAlarm(id);
      await _local.upsertAlarm(model);
      return Right(model.toEntity());
    } on NetworkException {
      final cached = await _safeCachedAlarm(id);
      if (cached != null) return Right(cached.toEntity());
      return const Left(NetworkFailure());
    } on PremiumRequiredException catch (e) {
      return Left(PremiumRequiredFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, AlarmEntity>> createAlarm(AlarmEntity alarm) async {
    try {
      final created = await _remote.createAlarm(AlarmModel.fromEntity(alarm));
      await _local.upsertAlarm(created);
      // Arm the OS trigger immediately so the alarm fires even if the user goes
      // offline right after creating it. Scheduler is no-op when inactive.
      await _scheduler.schedule(created.toSchedule());
      return Right(created.toEntity());
    } on NetworkException {
      return const Left(NetworkFailure(
        message: 'Cannot create an alarm while offline.',
      ));
    } on PremiumRequiredException catch (e) {
      // Hit the free-alarm limit / premium gate.
      return Left(PremiumRequiredFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, AlarmEntity>> updateAlarm(AlarmEntity alarm) async {
    try {
      final updated = await _remote.updateAlarm(
        alarm.id,
        AlarmModel.fromEntity(alarm),
      );
      await _local.upsertAlarm(updated);
      // Re-arm (schedule() cancels internally when the alarm is now inactive).
      await _scheduler.schedule(updated.toSchedule());
      return Right(updated.toEntity());
    } on NetworkException {
      return const Left(NetworkFailure(
        message: 'Cannot update an alarm while offline.',
      ));
    } on PremiumRequiredException catch (e) {
      return Left(PremiumRequiredFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAlarm(String id) async {
    try {
      await _remote.deleteAlarm(id);
      await _local.removeAlarm(id);
      await _scheduler.cancel(id);
      return const Right(unit);
    } on NetworkException {
      return const Left(NetworkFailure(
        message: 'Cannot delete an alarm while offline.',
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, AlarmEntity>> toggleAlarm(String id) async {
    try {
      final toggled = await _remote.toggleAlarm(id);
      await _local.upsertAlarm(toggled);
      // schedule() arms when active and cancels when inactive — both handled.
      await _scheduler.schedule(toggled.toSchedule());
      return Right(toggled.toEntity());
    } on NetworkException {
      return const Left(NetworkFailure(
        message: 'Cannot change an alarm while offline.',
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<AlarmMissionEntity>>> getMissions(
    String alarmId,
  ) async {
    try {
      final missions = await _remote.getMissions(alarmId);
      return Right(missions.map((m) => m.toEntity()).toList());
    } on NetworkException {
      // Fall back to the missions embedded in the cached alarm.
      final cached = await _safeCachedAlarm(alarmId);
      if (cached != null) {
        return Right(cached.missions.map((m) => m.toEntity()).toList());
      }
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, AlarmMissionEntity>> addMission(
    String alarmId,
    AlarmMissionEntity mission,
  ) async {
    try {
      final created = await _remote.addMission(
        alarmId,
        AlarmMissionModel.fromEntity(mission),
      );
      // Keep the cached alarm's mission list in sync.
      await _refreshCachedAlarm(alarmId);
      return Right(created.toEntity());
    } on NetworkException {
      return const Left(NetworkFailure(
        message: 'Cannot add a mission while offline.',
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteMission(
    String alarmId,
    String missionId,
  ) async {
    try {
      await _remote.deleteMission(alarmId, missionId);
      await _refreshCachedAlarm(alarmId);
      return const Right(unit);
    } on NetworkException {
      return const Left(NetworkFailure(
        message: 'Cannot remove a mission while offline.',
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  // --- Helpers --------------------------------------------------------------

  /// Reads the cache and maps it to entities, translating cache errors.
  Future<Either<Failure, List<AlarmEntity>>> _fromCacheList() async {
    try {
      final cached = await _local.getCachedAlarms();
      return Right(cached.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  /// Best-effort cache read that never throws (used in fallbacks).
  Future<AlarmModel?> _safeCachedAlarm(String id) async {
    try {
      return await _local.getCachedAlarm(id);
    } on CacheException {
      return null;
    }
  }

  /// Pulls the latest alarm (with missions) from the server and re-caches it.
  /// Failures here are swallowed — keeping the cache in sync is best-effort.
  Future<void> _refreshCachedAlarm(String alarmId) async {
    try {
      final fresh = await _remote.getAlarm(alarmId);
      await _local.upsertAlarm(fresh);
    } catch (_) {
      // Non-fatal: the next getAlarms() will reconcile.
    }
  }

  /// Re-arms every active alarm and cancels inactive ones via the native bridge.
  Future<void> _rescheduleAll(List<AlarmModel> models) async {
    for (final m in models) {
      // schedule() cancels internally for inactive alarms, so a single call
      // per alarm keeps OS state fully reconciled.
      await _scheduler.schedule(m.toSchedule());
    }
  }
}
