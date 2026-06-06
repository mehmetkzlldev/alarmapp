import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/auth_response_model.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';

/// Remote data source for all auth + current-user network calls.
///
/// Endpoints and payload shapes are VERBATIM from the API contract. Paths are
/// relative; the configured [Dio.options.baseUrl] supplies `…/api/v1`.
abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });

  /// Exchanges a refresh token for a new rotated pair. Uses a *raw* Dio call so
  /// it is never intercepted by the access-token auth interceptor (which would
  /// otherwise try to refresh-on-401 recursively).
  Future<AuthTokensModel> refresh({required String refreshToken});

  Future<void> logout({required String refreshToken});

  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  // --- Endpoint paths (relative to baseUrl `…/api/v1`) ----------------------
  static const String _registerPath = '/auth/register';
  static const String _loginPath = '/auth/login';
  static const String _refreshPath = '/auth/refresh';
  static const String _logoutPath = '/auth/logout';
  static const String _mePath = '/users/me';

  @override
  Future<AuthResponseModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return _guard(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        _registerPath,
        data: {
          'email': email,
          'password': password,
          'displayName': displayName,
        },
      );
      return AuthResponseModel.fromJson(res.data!);
    });
  }

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    return _guard(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        _loginPath,
        data: {'email': email, 'password': password},
      );
      return AuthResponseModel.fromJson(res.data!);
    });
  }

  @override
  Future<AuthTokensModel> refresh({required String refreshToken}) async {
    return _guard(() async {
      // Use a fresh Dio so no auth interceptor attaches a (possibly expired)
      // access token or triggers a recursive refresh on 401.
      final rawDio = Dio(
        BaseOptions(
          baseUrl: AppConstants.apiUrl,
          connectTimeout: AppConstants.connectTimeout,
          receiveTimeout: AppConstants.receiveTimeout,
          contentType: Headers.jsonContentType,
        ),
      );
      final res = await rawDio.post<Map<String, dynamic>>(
        _refreshPath,
        data: {'refreshToken': refreshToken},
      );
      return AuthTokensModel.fromJson(res.data!);
    });
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    return _guard(() async {
      await _dio.post<void>(
        _logoutPath,
        data: {'refreshToken': refreshToken},
      );
    });
  }

  @override
  Future<UserModel> getCurrentUser() async {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>(_mePath);
      return UserModel.fromJson(res.data!);
    });
  }

  /// Runs [op], translating Dio/network errors into typed [Exception]s that the
  /// repository converts to `Failure`s. Keeps every method body terse.
  Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      // Serialization or any unexpected error.
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  /// Maps a [DioException] to the app's typed exceptions, honoring the backend
  /// error envelope `{ statusCode, message, error, path, timestamp }`.
  Exception _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException(e.message ?? 'Network timeout');
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        if (e.error is Exception && e.response == null) {
          return NetworkException(e.message ?? 'Network error');
        }
        break;
      case DioExceptionType.badResponse:
        break;
    }

    final status = e.response?.statusCode;
    final message = _extractMessage(e.response?.data) ??
        e.message ??
        'Request failed';

    // 402 (Payment Required) / 403 from PremiumGuard -> premium upsell.
    if (status == 402) {
      return PremiumRequiredException(message);
    }
    return ServerException(message: message, statusCode: status);
  }

  /// Pulls a human-readable message out of the standard error envelope.
  /// `message` may be a string or a list of validation strings.
  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is String) return msg;
      if (msg is List && msg.isNotEmpty) return msg.join('\n');
      final err = data['error'];
      if (err is String) return err;
    }
    return null;
  }
}
