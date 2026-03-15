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
      final errorData = data is Map ? data['error'] as Map? : null;
      final message =
          errorData?['message'] as String? ?? 'Unknown error occurred';
      final details = (errorData?['details'] as List?)?.cast<String>();

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
