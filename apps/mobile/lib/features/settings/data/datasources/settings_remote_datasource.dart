import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';

/// Remote source for profile updates (`PATCH /users/me`).
///
/// Reuses the auth feature's [UserModel] for JSON mapping so the User shape is
/// defined in exactly one place.
abstract class SettingsRemoteDataSource {
  Future<UserEntity> updateProfile({
    String? displayName,
    String? timezone,
    String? locale,
  });
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  SettingsRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<UserEntity> updateProfile({
    String? displayName,
    String? timezone,
    String? locale,
  }) async {
    // Build a partial body containing only the provided fields.
    final body = <String, dynamic>{
      if (displayName != null) 'displayName': displayName,
      if (timezone != null) 'timezone': timezone,
      if (locale != null) 'locale': locale,
    };

    final res = await _client.patch<Map<String, dynamic>>(
      ApiEndpoints.usersMe,
      data: body,
    );
    return UserModel.fromJson(res.data!).toEntity();
  }
}
