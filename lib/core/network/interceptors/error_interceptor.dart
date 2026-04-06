import 'package:dio/dio.dart';
import 'package:hisobnoma/core/network/api_exceptions.dart';

/// Maps Dio errors to typed ApiExceptions
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const NetworkException(),
          type: err.type,
        ),
      );
      return;
    }

    if (response != null) {
      final data = response.data;
      // Backend may return error info as:
      // 1. Top-level: {"message": "...", "status": 400, "code": "..."}
      // 2. Nested:    {"error": {"message": "...", "details": [...]}}
      String message = 'Unknown error occurred';
      List<String>? details;
      if (data is Map) {
        final errorData = data['error'] as Map?;
        if (errorData != null) {
          message = errorData['message'] as String? ?? message;
          details = (errorData['details'] as List?)?.cast<String>();
        } else if (data['message'] != null) {
          message = data['message'] as String;
        }
      }

      switch (response.statusCode) {
        case 400:
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: ValidationException(message: message, details: details),
              response: response,
            ),
          );
          return;
        case 401:
          // Let AuthInterceptor handle 401 first
          break;
        case 403:
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: ForbiddenException(message: message),
              response: response,
            ),
          );
          return;
        case 404:
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: NotFoundException(message: message),
              response: response,
            ),
          );
          return;
        case 429:
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: const RateLimitException(),
              response: response,
            ),
          );
          return;
      }
    }

    handler.next(err);
  }
}
