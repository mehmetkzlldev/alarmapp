import 'package:equatable/equatable.dart';

import 'auth_tokens_entity.dart';
import 'user_entity.dart';

/// The full result of a successful register/login: the authenticated user plus
/// the freshly minted token pair.
///
/// Mirrors the `{ user, accessToken, refreshToken }` response shape of
/// `POST /auth/register` and `POST /auth/login`.
class AuthSessionEntity extends Equatable {
  const AuthSessionEntity({
    required this.user,
    required this.tokens,
  });

  final UserEntity user;
  final AuthTokensEntity tokens;

  @override
  List<Object?> get props => [user, tokens];
}
