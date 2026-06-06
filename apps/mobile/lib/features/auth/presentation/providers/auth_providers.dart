import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/refresh.dart';
import '../../domain/usecases/register.dart';

/// Dependency-injection wiring for the auth feature, expressed as Riverpod
/// providers. Other features can read [authRepositoryProvider] /
/// [dioProvider] to share the same configured instances.

/// Platform secure storage (Keychain / EncryptedSharedPreferences).
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

/// The app-wide [Dio] instance, pre-configured with the versioned base URL and
/// an auth interceptor that:
///  1. attaches the current access token to every request, and
///  2. on a 401, transparently refreshes the token pair once and retries.
///
/// Exposed at feature level so other data sources reuse the same client (and
/// therefore the same auth handling).
final Provider<Dio> dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      sendTimeout: AppConstants.sendTimeout,
      contentType: Headers.jsonContentType,
    ),
  );

  final storage = ref.read(secureStorageProvider);

  dio.interceptors.add(
    _AuthInterceptor(
      dio: dio,
      storage: storage,
      // Lazily resolve the repository to perform refresh; avoids a provider
      // cycle (repository depends on dio, interceptor needs refresh).
      refresh: () => ref.read(authRepositoryProvider).refreshSession(),
    ),
  );

  if (AppConstants.enableNetworkLogs) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  return dio;
});

// --- Data sources ----------------------------------------------------------

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl(ref.read(secureStorageProvider));
});

final Provider<AuthRemoteDataSource> authRemoteDataSourceProvider =
    Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.read(dioProvider));
});

// --- Repository ------------------------------------------------------------

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.read(authRemoteDataSourceProvider),
    local: ref.read(authLocalDataSourceProvider),
  );
});

// --- Use cases -------------------------------------------------------------

final loginUseCaseProvider =
    Provider<Login>((ref) => Login(ref.read(authRepositoryProvider)));

final registerUseCaseProvider =
    Provider<Register>((ref) => Register(ref.read(authRepositoryProvider)));

final logoutUseCaseProvider =
    Provider<Logout>((ref) => Logout(ref.read(authRepositoryProvider)));

final getCurrentUserUseCaseProvider = Provider<GetCurrentUser>(
    (ref) => GetCurrentUser(ref.read(authRepositoryProvider)));

final refreshUseCaseProvider =
    Provider<Refresh>((ref) => Refresh(ref.read(authRepositoryProvider)));

/// Dio interceptor that attaches the bearer token and performs a single
/// refresh-and-retry on 401 responses.
class _AuthInterceptor extends QueuedInterceptor {
  _AuthInterceptor({
    required Dio dio,
    required FlutterSecureStorage storage,
    required Future<dynamic> Function() refresh,
  })  : _dio = dio,
        _storage = storage,
        _refresh = refresh;

  final Dio _dio;
  final FlutterSecureStorage _storage;

  /// Returns Either<Failure, AuthTokensEntity>; treated opaquely here — we only
  /// care whether a fresh access token landed in storage afterwards.
  final Future<dynamic> Function() _refresh;

  /// Paths that must never carry an access token nor trigger a refresh loop.
  static const _authBypassPaths = {'/auth/login', '/auth/register', '/auth/refresh'};

  bool get _isRetrying => _retrying;
  bool _retrying = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_authBypassPaths.any((p) => options.path.endsWith(p))) {
      final token = await _storage.read(key: StorageKeys.accessToken);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isBypass =
        _authBypassPaths.any((p) => err.requestOptions.path.endsWith(p));

    if (!isUnauthorized || isBypass || _isRetrying) {
      return handler.next(err);
    }

    _retrying = true;
    try {
      // Attempt a single refresh. The repository persists the new tokens.
      await _refresh();
      final newToken = await _storage.read(key: StorageKeys.accessToken);
      if (newToken == null || newToken.isEmpty) {
        // Refresh failed -> propagate the original 401 so the UI logs out.
        return handler.next(err);
      }

      // Replay the original request with the new token.
      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer $newToken';
      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } catch (_) {
      return handler.next(err);
    } finally {
      _retrying = false;
    }
  }
}
