import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_session_entity.dart';
import '../../domain/entities/auth_tokens_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';

/// Concrete [AuthRepository]: orchestrates the remote and local data sources,
/// persists tokens on success, and converts thrown exceptions into [Failure]s.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<Either<Failure, AuthSessionEntity>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return _attempt(() async {
      final response = await _remote.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      await _persistSession(response.accessToken, response.refreshToken,
          response.user);
      return response.toEntity();
    });
  }

  @override
  Future<Either<Failure, AuthSessionEntity>> login({
    required String email,
    required String password,
  }) async {
    return _attempt(() async {
      final response = await _remote.login(email: email, password: password);
      await _persistSession(response.accessToken, response.refreshToken,
          response.user);
      return response.toEntity();
    });
  }

  @override
  Future<Either<Failure, AuthTokensEntity>> refreshSession() async {
    return _attempt(() async {
      final stored = await _local.getRefreshToken();
      if (stored == null || stored.isEmpty) {
        // No refresh token -> behaves like an auth failure upstream.
        throw ServerException(
          message: 'No refresh token available',
          statusCode: 401,
        );
      }
      final tokens = await _remote.refresh(refreshToken: stored);
      // Persist the rotated pair immediately so subsequent calls use the new
      // access token and the old refresh token is dropped.
      await _local.cacheTokens(tokens);
      return tokens.toEntity();
    });
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      final refreshToken = await _local.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        // Best-effort server revocation; ignore network errors here because we
        // must clear local credentials regardless.
        try {
          await _remote.logout(refreshToken: refreshToken);
        } catch (_) {
          // Swallow: local logout still proceeds below.
        }
      }
      await _local.clear();
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    return _attempt(() async {
      final model = await _remote.getCurrentUser();
      // Refresh the cache so the next cold start has up-to-date data.
      await _local.cacheUser(model);
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, UserEntity?>> getCachedUser() async {
    try {
      final cached = await _local.getCachedUser();
      return Right(cached?.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<bool> hasValidSession() async {
    final refreshToken = await _local.getRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  // --- Helpers --------------------------------------------------------------

  /// Persists tokens + user after a successful auth call.
  Future<void> _persistSession(
    String accessToken,
    String refreshToken,
    UserModel userModel,
  ) async {
    await _local.cacheTokens(
      AuthTokensModel(accessToken: accessToken, refreshToken: refreshToken),
    );
    // cacheUser keeps userId + full profile in sync for cold-start rendering.
    await _local.cacheUser(userModel);
  }

  /// Runs [op] and maps thrown exceptions to the corresponding [Failure].
  Future<Either<Failure, T>> _attempt<T>(Future<T> Function() op) async {
    try {
      return Right(await op());
    } on PremiumRequiredException catch (e) {
      return Left(PremiumRequiredFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
