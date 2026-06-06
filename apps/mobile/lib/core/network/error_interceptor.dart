import 'package:dio/dio.dart';

/// Normalizes the backend error envelope so downstream code always sees a
/// predictable shape.
///
/// The backend returns errors as
/// `{ statusCode, message, error, path, timestamp }` where `message` may be a
/// string OR an array of validation strings (class-validator). This interceptor
/// flattens that into a single human-readable `message` on
/// `err.error` metadata, leaving the actual exception → [Failure] translation
/// to [DioClient._guard] (which the data layer calls through). Keeping this as a
/// dedicated interceptor means logging/Crashlytics can hook a single place.
///
/// Note: this interceptor does NOT swallow errors — it enriches and forwards
/// them so the [RefreshInterceptor] (registered before it) still gets a chance
/// to recover 401s.
class ErrorInterceptor extends Interceptor {
  ErrorInterceptor({this.onErrorSink});

  /// Optional sink for observability (e.g. Crashlytics non-fatal recording).
  /// Named `onErrorSink` to avoid clashing with [Interceptor.onError].
  final void Function(DioException error, String normalizedMessage)? onErrorSink;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final message = _normalizeMessage(err);
    // Surface a clean message via the standard `message` field.
    final enriched = err.copyWith(message: message);
    onErrorSink?.call(enriched, message);
    handler.next(enriched);
  }

  String _normalizeMessage(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The connection timed out. Check your network and try again.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Please check your connection.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badCertificate:
        return 'A secure connection could not be established.';
      case DioExceptionType.badResponse:
        return _extractEnvelopeMessage(err.response?.data) ??
            'Request failed (${err.response?.statusCode}).';
      case DioExceptionType.unknown:
        return err.message ?? 'An unexpected error occurred.';
    }
  }

  /// Pulls `message` from the backend error envelope, handling both the string
  /// and the validation-array forms.
  String? _extractEnvelopeMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
      if (msg is List && msg.isNotEmpty) {
        return msg.map((e) => e.toString()).join('\n');
      }
      final error = data['error'];
      if (error is String && error.isNotEmpty) return error;
    }
    return null;
  }
}
