import 'dart:async';
import 'package:dio/dio.dart';
import 'package:hisobnoma/core/network/tls_policy.dart';

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
          final dio = Dio();
          applyTlsPolicy(dio, allowedHost: err.requestOptions.uri.host);
          final response = await dio.fetch(err.requestOptions);
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
    // NEVER auto-retry non-idempotent requests. A POST/PUT/PATCH/DELETE that
    // times out may already have been processed by the server; re-sending it
    // would create duplicate sales, shifts, or cash operations. Only GET/HEAD
    // are safe to replay by default. A POST may opt in by setting
    // extra['idempotent'] = true — used by quick-sale, which carries a
    // clientRequestId the backend dedups on, so a retry returns the original
    // transaction instead of a duplicate.
    final method = err.requestOptions.method.toUpperCase();
    final isIdempotent = err.requestOptions.extra['idempotent'] == true;
    if (method != 'GET' && method != 'HEAD' && !isIdempotent) return false;

    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode == 429); // Rate limited
  }
}
