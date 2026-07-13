import 'package:dio/dio.dart';
import 'package:hisobnoma/core/network/api_endpoints.dart';
import 'package:hisobnoma/core/network/interceptors/auth_interceptor.dart';
import 'package:hisobnoma/core/network/interceptors/error_interceptor.dart';
import 'package:hisobnoma/core/network/interceptors/retry_interceptor.dart';
import 'package:hisobnoma/core/network/interceptors/safe_log_interceptor.dart';
import 'package:hisobnoma/core/network/tls_policy.dart';

/// Central HTTP client wrapping Dio for all API calls
class ApiClient {
  late final Dio _dio;

  Dio get dio => _dio;

  ApiClient({
    required String baseUrl,
    required AuthInterceptor authInterceptor,
    bool enableLogging = false,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl + ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Shared TLS policy: full validation in release, host-scoped bypass in
    // debug only. See tls_policy.dart. TRANSITIONAL until the server cert
    // chain is fixed (plan task 1.8).
    applyTlsPolicy(_dio, allowedHost: Uri.tryParse(baseUrl)?.host);

    _dio.interceptors.addAll([
      authInterceptor,
      RetryInterceptor(maxRetries: 3),
      ErrorInterceptor(),
      // Credential-redacting logger — never dumps Authorization headers or
      // PINs/tokens to the device log (unlike Dio's raw LogInterceptor).
      if (enableLogging) SafeLogInterceptor(),
    ]);
  }

  // GET
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  // POST
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
    );
  }

  // PUT
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  // DELETE
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }
}
