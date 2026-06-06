import 'package:equatable/equatable.dart';

/// A pair of dual JWTs returned by the auth endpoints.
///
/// - [accessToken]: short-lived (~15m), sent as `Authorization: Bearer ...`.
/// - [refreshToken]: long-lived (~30d), rotating. Exchanged at `/auth/refresh`
///   for a brand-new pair; the old refresh token is invalidated server-side.
class AuthTokensEntity extends Equatable {
  const AuthTokensEntity({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  @override
  List<Object?> get props => [accessToken, refreshToken];
}
