import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/notification_preferences.dart';

/// Contract for settings-related data access.
///
/// Profile updates hit `PATCH /users/me`; notification preferences are stored
/// locally on the device (no server endpoint in the contract).
abstract class SettingsRepository {
  /// `PATCH /users/me` — update an editable subset of the profile. Any
  /// argument left null is omitted from the request (partial update).
  Future<Either<Failure, UserEntity>> updateProfile({
    String? displayName,
    String? timezone,
    String? locale,
  });

  /// Reads locally-persisted notification preferences (defaults if unset).
  Future<NotificationPreferences> getNotificationPreferences();

  /// Persists notification preferences locally.
  Future<void> saveNotificationPreferences(NotificationPreferences prefs);
}
