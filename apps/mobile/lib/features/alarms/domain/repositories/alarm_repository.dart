import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/alarm_entity.dart';
import '../entities/alarm_mission_entity.dart';

/// Contract for alarm data access, owned by the domain layer.
///
/// Implementations coordinate the remote API, the offline cache, and the native
/// alarm scheduler. Every method returns `Either<Failure, T>` so callers never
/// see raw exceptions.
abstract class AlarmRepository {
  /// All of the current user's alarms.
  ///
  /// Returns the freshest data available: on success it refreshes the cache;
  /// when offline it falls back to the cached list (so the UI and the native
  /// scheduler keep working without connectivity).
  Future<Either<Failure, List<AlarmEntity>>> getAlarms();

  /// A single alarm by id.
  Future<Either<Failure, AlarmEntity>> getAlarm(String id);

  /// Creates a new alarm (including any inline missions).
  ///
  /// On success the implementation also persists to the cache and registers the
  /// alarm with the native scheduler so it can fire offline.
  Future<Either<Failure, AlarmEntity>> createAlarm(AlarmEntity alarm);

  /// Applies a partial update to an existing alarm and re-schedules it.
  Future<Either<Failure, AlarmEntity>> updateAlarm(AlarmEntity alarm);

  /// Deletes an alarm and cancels its native triggers.
  Future<Either<Failure, Unit>> deleteAlarm(String id);

  /// Flips the active flag server-side and (re-)arms or cancels the native
  /// trigger accordingly.
  Future<Either<Failure, AlarmEntity>> toggleAlarm(String id);

  /// Missions attached to an alarm.
  Future<Either<Failure, List<AlarmMissionEntity>>> getMissions(String alarmId);

  /// Adds a mission to an existing alarm.
  Future<Either<Failure, AlarmMissionEntity>> addMission(
    String alarmId,
    AlarmMissionEntity mission,
  );

  /// Removes a mission from an alarm.
  Future<Either<Failure, Unit>> deleteMission(
    String alarmId,
    String missionId,
  );
}
