import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:hisobnoma/core/network/api_endpoints.dart';
import 'package:hisobnoma/core/network/interceptors/auth_interceptor.dart';
import 'package:hisobnoma/core/network/interceptors/error_interceptor.dart';
import 'package:hisobnoma/core/network/interceptors/retry_interceptor.dart';

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

    // TLS policy.
    //
    // Release builds (App Store / Play Store) ALWAYS use full certificate
    // validation — no bypass. In debug/profile builds ONLY, we tolerate a bad
    // certificate for the exact API host so local testing is not blocked while
    // the server's certificate chain is being fixed.
    //
    // This is a TRANSITIONAL measure. The real fix is to install the full
    // intermediate certificate chain on the API server (see
    // docs/audit/REMEDIATION_PLAN.md task 1.8). Once the server validates
    // cleanly, delete this entire block. Until then, release builds will
    // (correctly) refuse to connect to a server they cannot verify.
    if (!kReleaseMode) {
      final allowedHost = Uri.tryParse(baseUrl)?.host;
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback =
            (cert, host, port) => allowedHost != null && host == allowedHost;
        return client;
      };
    }

    _dio.interceptors.addAll([
      authInterceptor,
      RetryInterceptor(maxRetries: 3),
      ErrorInterceptor(),
      if (enableLogging)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => developer.log('$obj', name: 'API'),
        ),
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
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
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
