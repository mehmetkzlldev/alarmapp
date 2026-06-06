import 'dart:async';

import 'package:dio/dio.dart';

import 'package:alarmy/core/constants/api_constants.dart';
import 'package:alarmy/core/storage/token_store.dart';

/// Handles silent access-token renewal on `401 Unauthorized`.
///
/// Flow:
///   1. A request returns 401 (and isn't itself the refresh call).
///   2. We POST `/auth/refresh { refreshToken }` to get a *rotated* token pair.
///   3. We persist the new pair and replay the original request once.
///   4. If refresh fails (or there is no refresh token), we clear the session
///      and let the 401 propagate so the router redirects to /login.
///
/// Concurrency: many requests can 401 simultaneously (e.g. on app resume). A
/// single [Completer] gates them so we refresh exactly once and all waiters
/// replay with the new token. We use a *separate* [Dio] for the refresh call to
/// avoid recursively triggering this interceptor.
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({
    required Dio dio,
    required TokenStore tokenStore,
    Dio? refreshDio,
  })  : _dio = dio,
        _tokenStore = tokenStore,
        _refreshDio = refreshDio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.basePath,
                connectTimeout: ApiConstants.connectTimeout,
                receiveTimeout: ApiConstants.receiveTimeout,
                headers: {'Content-Type': 'application/json'},
              ),
            );

  /// The main client, used to replay the original request after refresh.
  final Dio _dio;
  final TokenStore _tokenStore;

  /// Bare client used ONLY for the refresh call (no interceptors).
  final Dio _refreshDio;

  /// In-flight refresh, shared by all concurrent 401s. Resolves to the new
  /// access token, or `null` if refresh failed.
  Completer<String?>? _inFlight;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final isUnauthorized = response?.statusCode == 401;
    final isRefreshCall = err.requestOptions.path.endsWith('/auth/refresh');

    // Only intervene on a genuine 401 that isn't the refresh endpoint itself,
    // and that we haven't already retried (guard against loops).
    if (!isUnauthorized ||
        isRefreshCall ||
        err.requestOptions.extra['__retried__'] == true) {
      return handler.next(err);
    }

    final newAccessToken = await _refreshToken();
    if (newAccessToken == null) {
      // Refresh failed -> session is dead. Clear and propagate the 401.
      await _tokenStore.clear();
      return handler.next(err);
    }

    try {
      final retried = await _replay(err.requestOptions, newAccessToken);
      return handler.resolve(retried);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  /// Returns a valid access token, refreshing at most once across concurrent
  /// callers. Returns null on failure.
  Future<String?> _refreshToken() {
    // Coalesce concurrent refreshes.
    final existing = _inFlight;
    if (existing != null) return existing.future;

    final completer = Completer<String?>();
    _inFlight = completer;

    _doRefresh().then((token) {
      completer.complete(token);
    }).catchError((Object _) {
      completer.complete(null);
    }).whenComplete(() {
      _inFlight = null;
    });

    return completer.future;
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final res = await _refreshDio.post<Map<String, dynamic>>(
      ApiConstants.refresh,
      data: {'refreshToken': refreshToken},
    );

    final data = res.data;
    if (data == null) return null;

    final newAccess = data['accessToken'] as String?;
    final newRefresh = data['refreshToken'] as String?;
    if (newAccess == null || newRefresh == null) return null;

    // Persist the rotated pair so the old refresh token is discarded.
    await _tokenStore.save(
      AuthTokens(accessToken: newAccess, refreshToken: newRefresh),
    );
    return newAccess;
  }

  /// Replays the original failed request with the fresh access token, marking
  /// it so a second 401 won't loop back into refresh.
  Future<Response<dynamic>> _replay(
    RequestOptions options,
    String accessToken,
  ) {
    final headers = Map<String, dynamic>.from(options.headers)
      ..['Authorization'] = 'Bearer $accessToken';

    return _dio.request<dynamic>(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      cancelToken: options.cancelToken,
      onReceiveProgress: options.onReceiveProgress,
      onSendProgress: options.onSendProgress,
      options: Options(
        method: options.method,
        headers: headers,
        responseType: options.responseType,
        contentType: options.contentType,
        extra: {...options.extra, '__retried__': true},
      ),
    );
  }
}
