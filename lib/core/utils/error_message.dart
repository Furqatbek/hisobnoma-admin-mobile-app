import 'package:dio/dio.dart';
import 'package:hisobnoma/core/network/api_exceptions.dart';

/// Extracts a user-friendly message from any error, so screens never surface
/// raw `DioException [bad response]: null` / stack-trace-ish text.
///
/// Pure (no Flutter imports) so it can be used from cubits and unit-tested in
/// isolation.
String extractErrorMessage(Object error) {
  if (error is DioException) {
    // Prefer the typed ApiException that ErrorInterceptor attaches.
    final dioError = error.error;
    if (dioError is ApiException) return dioError.message;

    // Otherwise, a message field in the response body (backend error shape).
    final data = error.response?.data;
    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }

    // Fall back to a generic, human-readable line — never Dio's toString().
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }

  if (error is ApiException) return error.message;

  final str = error.toString();
  if (str.startsWith('Exception: ')) return str.substring(11);
  return str;
}
