import 'package:dio/dio.dart';

import 'package:alarmy/core/constants/api_constants.dart';
import 'package:alarmy/core/constants/app_constants.dart';
import 'package:alarmy/core/network/auth_interceptor.dart';
import 'package:alarmy/core/network/dio_client.dart';
import 'package:alarmy/core/network/error_interceptor.dart';
import 'package:alarmy/core/network/refresh_interceptor.dart';
import 'package:alarmy/core/storage/token_store.dart';

/// Builds the app's single configured [Dio] instance and wraps it in a
/// [DioClient].
///
/// Interceptor ORDER matters — Dio runs request interceptors top-to-bottom and
/// error/response interceptors in the same registration order:
///   1. [AuthInterceptor]    — stamps the Bearer access token on requests.
///   2. [RefreshInterceptor] — on 401, refreshes + replays once.
///   3. [ErrorInterceptor]   — normalizes the error envelope (after refresh has
///      had its chance to recover).
///   4. [LogInterceptor]     — dev-only verbose logging (guarded by a flag).
///
/// The base URL comes from [ApiConstants] which reads `--dart-define API_BASE_URL`.
class ApiClientFactory {
  ApiClientFactory(this._tokenStore);

  final TokenStore _tokenStore;

  DioClient create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.basePath,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        // camelCase JSON everywhere per the API contract.
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Treat only 2xx as success; everything else flows through onError so
        // the refresh/error interceptors can act on it.
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(_tokenStore),
      RefreshInterceptor(dio: dio, tokenStore: _tokenStore),
      ErrorInterceptor(),
      if (AppConstants.enableNetworkLogs)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          // Never log Authorization headers in any build.
          requestHeader: false,
          logPrint: (Object o) {
            // ignore: avoid_print
            assert(() {
              // Only prints in debug; stripped in release.
              // ignore: avoid_print
              print(o);
              return true;
            }());
          },
        ),
    ]);

    return DioClient(dio);
  }
}
