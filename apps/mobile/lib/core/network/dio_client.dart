import 'package:dio/dio.dart';

import '../error/exceptions.dart';

/// Thin, typed wrapper over [Dio].
///
/// - Injects the API base path (`/api/v1`) and JSON headers.
/// - Translates [DioException]s into the app's domain [Exception]s
///   ([ServerException] / [NetworkException] / [PremiumRequiredException])
///   using the backend error envelope
///   `{ statusCode, message, error, path, timestamp }`.
///
/// Auth token attachment and silent refresh are handled by an interceptor
/// registered in [AuthInterceptor] (core/network/auth_interceptor.dart) so the
/// feature layer never deals with tokens directly.
class DioClient {
  DioClient(this._dio);

  final Dio _dio;

  Dio get raw => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _guard(() => _dio.get<T>(path, queryParameters: queryParameters));
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _guard(
      () => _dio.post<T>(path, data: data, queryParameters: queryParameters),
    );
  }

  Future<Response<T>> patch<T>(String path, {Object? data}) {
    return _guard(() => _dio.patch<T>(path, data: data));
  }

  Future<Response<T>> delete<T>(String path, {Object? data}) {
    return _guard(() => _dio.delete<T>(path, data: data));
  }

  /// Runs a Dio call and normalizes errors. Centralizing this keeps every
  /// data source free of repetitive try/catch translation logic.
  Future<Response<T>> _guard<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          throw NetworkException(e.message ?? 'Network timeout');
        case DioExceptionType.badResponse:
          final status = e.response?.statusCode;
          final message = _extractMessage(e.response?.data) ??
              e.message ??
              'Request failed';
          // 402 Payment Required / PremiumGuard rejection.
          if (status == 402) {
            throw PremiumRequiredException(message);
          }
          throw ServerException(message: message, statusCode: status);
        case DioExceptionType.cancel:
          throw ServerException(message: 'Request cancelled');
        case DioExceptionType.badCertificate:
        case DioExceptionType.unknown:
          throw NetworkException(e.message ?? 'Unexpected network error');
      }
    }
  }

  /// Pulls `message` out of the backend error envelope. `message` may be a
  /// string or a list of validation strings (class-validator style).
  String? _extractMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is String) return msg;
      if (msg is List && msg.isNotEmpty) return msg.first.toString();
    }
    return null;
  }
}
