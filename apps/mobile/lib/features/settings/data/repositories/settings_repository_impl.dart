import 'package:dartz/dartz.dart';

import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../datasources/settings_remote_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({
    required SettingsRemoteDataSource remote,
    required SettingsLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final SettingsRemoteDataSource _remote;
  final SettingsLocalDataSource _local;

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? displayName,
    String? timezone,
    String? locale,
  }) async {
    try {
      final user = await _remote.updateProfile(
        displayName: displayName,
        timezone: timezone,
        locale: locale,
      );
      return Right(user);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<NotificationPreferences> getNotificationPreferences() {
    return _local.readNotificationPreferences();
  }

  @override
  Future<void> saveNotificationPreferences(NotificationPreferences prefs) {
    return _local.writeNotificationPreferences(prefs);
  }
}
