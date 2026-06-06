import 'package:dio/dio.dart';

import 'package:alarmy/core/storage/token_store.dart';

/// Attaches the `Authorization: Bearer <accessToken>` header to every outgoing
/// request, except auth endpoints that must NOT carry a (possibly stale) token.
///
/// Token *refresh* is deliberately handled by a separate [RefreshInterceptor]
/// so this class has a single responsibility: read the current access token and
/// stamp it on the request.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStore);

  final TokenStore _tokenStore;

  /// Paths that should never receive an Authorization header.
  static const _publicPaths = <String>{
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isPublic = _publicPaths.any(options.path.endsWith);
    if (!isPublic) {
      final token = await _tokenStore.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
