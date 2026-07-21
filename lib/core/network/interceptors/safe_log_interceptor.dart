import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// A logging interceptor that logs request/response metadata WITHOUT ever
/// emitting credentials or other sensitive values to the device log.
///
/// Dio's built-in [LogInterceptor] dumps full headers and bodies — including
/// the `Authorization` bearer token and login PINs — which are then readable
/// via Xcode/logcat on a physical device. This interceptor redacts those
/// fields so logging is safe even against a production backend.
class SafeLogInterceptor extends Interceptor {
  static const _redacted = '***REDACTED***';

  /// Header names (lower-cased) whose values must never be logged.
  static const _sensitiveHeaders = {'authorization', 'cookie', 'set-cookie'};

  /// Body/query keys (lower-cased) whose values must never be logged.
  static const _sensitiveKeys = {
    'pin',
    'password',
    'accesstoken',
    'refreshtoken',
    'access_token',
    'refresh_token',
    'token',
  };

  void _log(String message) => developer.log(message, name: 'API');

  Map<String, dynamic> _redactHeaders(Map<String, dynamic> headers) {
    return headers.map(
      (k, v) => MapEntry(
        k,
        _sensitiveHeaders.contains(k.toLowerCase()) ? _redacted : v,
      ),
    );
  }

  Object? _redactData(Object? data) {
    if (data is Map) {
      return data.map(
        (k, v) => MapEntry(
          k,
          _sensitiveKeys.contains(k.toString().toLowerCase())
              ? _redacted
              : _redactData(v),
        ),
      );
    }
    if (data is List) return data.map(_redactData).toList();
    return data;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log('--> ${options.method} ${options.uri}');
    _log('headers: ${_redactHeaders(options.headers)}');
    if (options.data != null) _log('body: ${_redactData(options.data)}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log('<-- ${response.statusCode} ${response.requestOptions.uri}');
    if (response.data != null) _log('body: ${_redactData(response.data)}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(
      '<-- ERROR ${err.response?.statusCode} '
      '${err.requestOptions.uri} (${err.type})',
    );
    if (err.response?.data != null) {
      _log('error body: ${_redactData(err.response?.data)}');
    }
    handler.next(err);
  }
}
