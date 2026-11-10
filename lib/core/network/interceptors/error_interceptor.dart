import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hisobnoma/core/network/api_exceptions.dart';

/// Maps Dio errors to typed [ApiException]s.
///
/// The backend's error body (Spring `ErrorResponse`) looks like:
///
/// ```json
/// {"status": 400, "error": "Bad Request", "message": "Price is below …",
///  "code": "PRICE_BELOW_MIN", "path": "/api/v1/mobile/inventory/price",
///  "validationErrors": [{"field": "sellingPrice", "message": "…"}]}
/// ```
///
/// Note that `error` is the HTTP reason phrase (a *string*), not an object.
/// Some gateways answer with `{"error": {"message": …, "details": […]}}`,
/// plain text or an HTML page instead, so parsing is deliberately defensive:
/// nothing in here may throw. An exception escaping an interceptor makes Dio
/// replace the real response with an opaque "unknown" error, and the user
/// then sees "Something went wrong" instead of the backend's message.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_isConnectivityError(err.type)) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const NetworkException(),
          type: err.type,
          message: const NetworkException().message,
        ),
      );
      return;
    }

    final response = err.response;
    final status = response?.statusCode;
    if (response == null || status == null) {
      handler.next(err);
      return;
    }

    final mapped = mapStatusToException(status, parseErrorBody(response.data));
    if (mapped == null) {
      // 401 is handled by AuthInterceptor; 1xx–3xx never reach onError.
      handler.next(err);
      return;
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: mapped,
        response: response,
        type: err.type,
        message: mapped.message,
      ),
    );
  }

  static bool _isConnectivityError(DioExceptionType type) =>
      type == DioExceptionType.connectionTimeout ||
      type == DioExceptionType.receiveTimeout ||
      type == DioExceptionType.sendTimeout ||
      type == DioExceptionType.connectionError;
}

/// Chooses the typed exception for an HTTP [status]. Returns `null` for
/// statuses this layer leaves alone (401 → AuthInterceptor).
ApiException? mapStatusToException(int status, ParsedErrorBody body) {
  switch (status) {
    case 400:
      return ValidationException(
        message: body.message ?? 'Invalid request parameters',
        details: body.details,
        code: body.code ?? 'VALIDATION_ERROR',
      );
    case 401:
      return null;
    case 403:
      return ForbiddenException(
        message: body.message ?? 'Insufficient permissions',
      );
    case 404:
      return NotFoundException(message: body.message ?? 'Resource not found');
    case 429:
      return const RateLimitException();
  }
  if (status >= 500) {
    return ApiException(
      code: body.code ?? 'SERVER_ERROR',
      message:
          body.message ?? 'Server error ($status). Please try again later.',
      details: body.details,
      statusCode: status,
    );
  }
  if (status >= 400) {
    // 405, 409, 422, … — keep whatever the backend said, plus the status.
    return ApiException(
      code: body.code ?? 'REQUEST_FAILED',
      message: body.message ?? 'Request failed ($status). Please try again.',
      details: body.details,
      statusCode: status,
    );
  }
  return null;
}

/// What could be understood from an error response body.
class ParsedErrorBody {
  final String? message;
  final String? code;
  final List<String>? details;

  const ParsedErrorBody({this.message, this.code, this.details});
}

/// Extracts message / code / details from an error body of any shape.
/// Never throws; unknown shapes yield an empty [ParsedErrorBody].
ParsedErrorBody parseErrorBody(Object? data) {
  try {
    if (data is Map) return _parseMap(data);
    if (data is List<int>) {
      return parseErrorBody(utf8.decode(data, allowMalformed: true));
    }
    if (data is String) {
      final text = data.trim();
      if (text.isEmpty) return const ParsedErrorBody();
      if (text.startsWith('{') || text.startsWith('[')) {
        final decoded = jsonDecode(text);
        if (decoded is Map) return _parseMap(decoded);
        return const ParsedErrorBody();
      }
      // An nginx/gateway HTML page carries nothing worth showing.
      if (text.startsWith('<')) return const ParsedErrorBody();
      // Short plain-text bodies are usually the message itself.
      if (text.length <= 200) return ParsedErrorBody(message: text);
    }
  } catch (_) {
    // Fall through: an unparseable body must not mask the HTTP status.
  }
  return const ParsedErrorBody();
}

ParsedErrorBody _parseMap(Map<dynamic, dynamic> data) {
  final nested = data['error'];
  final nestedMap = nested is Map ? nested : null;

  String? message = _string(data['message']) ?? _string(nestedMap?['message']);
  // Spring ProblemDetail (`detail`/`title`) and a bare reason phrase last.
  message ??= _string(data['detail']) ?? _string(data['title']);
  message ??= _string(nested);

  final code =
      _string(data['code']) ??
      _string(data['errorCode']) ??
      _string(nestedMap?['code']);

  final details = <String>[];
  for (final raw in [
    data['details'],
    nestedMap?['details'],
    data['validationErrors'],
    data['errors'],
  ]) {
    if (raw is! List) continue;
    for (final item in raw) {
      if (item is String && item.isNotEmpty) {
        details.add(item);
      } else if (item is Map) {
        final field = _string(item['field']);
        final msg = _string(item['message']) ?? _string(item['defaultMessage']);
        if (msg == null) continue;
        details.add(field == null ? msg : '$field: $msg');
      }
    }
  }

  // "Validation failed" alone tells the user nothing — append the specifics.
  if (details.isNotEmpty) {
    message = message == null
        ? details.join('; ')
        : '$message: ${details.join('; ')}';
  }

  return ParsedErrorBody(
    message: message,
    code: code,
    details: details.isEmpty ? null : details,
  );
}

String? _string(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}
