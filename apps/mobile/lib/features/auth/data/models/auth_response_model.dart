import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/auth_session_entity.dart';
import '../../domain/entities/auth_tokens_entity.dart';
import 'user_model.dart';

part 'auth_response_model.freezed.dart';
part 'auth_response_model.g.dart';

/// Response model for `POST /auth/register` and `POST /auth/login`.
///
/// Shape: `{ user, accessToken, refreshToken }`. The tokens are flattened at
/// the top level (not nested) to match the contract exactly.
@freezed
class AuthResponseModel with _$AuthResponseModel {
  const AuthResponseModel._();

  const factory AuthResponseModel({
    required UserModel user,
    required String accessToken,
    required String refreshToken,
  }) = _AuthResponseModel;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseModelFromJson(json);

  /// Maps to the domain session aggregate (user + token pair).
  AuthSessionEntity toEntity() => AuthSessionEntity(
        user: user.toEntity(),
        tokens: AuthTokensEntity(
          accessToken: accessToken,
          refreshToken: refreshToken,
        ),
      );
}
