import 'dart:async';
import 'package:dio/dio.dart';

/// Retries failed requests due to network errors with exponential backoff
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration initialDelay;

  RetryInterceptor({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

      if (retryCount < maxRetries) {
        final delay = initialDelay * (1 << retryCount); // exponential backoff
        await Future<void>.delayed(delay);

        err.requestOptions.extra['retryCount'] = retryCount + 1;

        try {
          final response = await Dio().fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          // Fall through to next retry or final error
          if (e is DioException) {
            return super.onError(e, handler);
          }
        }
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode == 429); // Rate limited
  }
}
