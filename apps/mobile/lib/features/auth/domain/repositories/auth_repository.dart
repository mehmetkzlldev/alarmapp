import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_session_entity.dart';
import '../entities/auth_tokens_entity.dart';
import '../entities/user_entity.dart';

/// Abstract contract for authentication & session management.
///
/// The presentation layer depends only on this interface; the concrete
/// `AuthRepositoryImpl` (in the data layer) wires it to remote + local sources.
/// Every method returns `Either<Failure, T>` so callers handle errors
/// explicitly without try/catch.
abstract class AuthRepository {
  /// Registers a new account and persists the returned tokens locally.
  Future<Either<Failure, AuthSessionEntity>> register({
    required String email,
    required String password,
    required String displayName,
  });

  /// Authenticates with email + password and persists the returned tokens.
  Future<Either<Failure, AuthSessionEntity>> login({
    required String email,
    required String password,
  });

  /// Exchanges the stored refresh token for a new (rotated) token pair.
  ///
  /// Reads the current refresh token from secure storage, calls
  /// `POST /auth/refresh`, and persists the new pair. Returns the new tokens
  /// so callers (e.g. the Dio interceptor) can retry the original request.
  Future<Either<Failure, AuthTokensEntity>> refreshSession();

  /// Revokes the stored refresh token server-side and clears local tokens.
  ///
  /// Local tokens are cleared even if the network call fails, so the user is
  /// always logged out locally.
  Future<Either<Failure, Unit>> logout();

  /// Fetches the current user from `GET /users/me`.
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Returns the locally cached user without a network round-trip, if present.
  /// Used at startup to render UI before `getCurrentUser` resolves.
  Future<Either<Failure, UserEntity?>> getCachedUser();

  /// True when a refresh token is present in secure storage. Used at app
  /// bootstrap to decide whether to attempt session restoration.
  Future<bool> hasValidSession();
}
