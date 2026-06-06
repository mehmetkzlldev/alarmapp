import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/auth_tokens_entity.dart';

part 'auth_tokens_model.freezed.dart';
part 'auth_tokens_model.g.dart';

/// Token pair model, matching `{ accessToken, refreshToken }` returned by
/// `/auth/register`, `/auth/login`, and `/auth/refresh`.
@freezed
class AuthTokensModel with _$AuthTokensModel {
  const AuthTokensModel._();

  const factory AuthTokensModel({
    required String accessToken,
    required String refreshToken,
  }) = _AuthTokensModel;

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensModelFromJson(json);

  AuthTokensEntity toEntity() => AuthTokensEntity(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
}
