import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisobnoma/core/network/api_exceptions.dart';
import 'package:hisobnoma/core/network/interceptors/error_interceptor.dart';
import 'package:hisobnoma/core/utils/error_message.dart';

/// Replies to every request with a fixed status/body, so the whole Dio
/// pipeline (transformer → interceptors → thrown exception) is exercised.
class _FakeAdapter implements HttpClientAdapter {
  final int status;
  final String body;
  final String contentType;

  _FakeAdapter(this.status, this.body, {this.contentType = 'application/json'});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<DioException> _fail(
  int status,
  String body, {
  String contentType = 'application/json',
}) async {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
    ..httpClientAdapter = _FakeAdapter(status, body, contentType: contentType)
    ..interceptors.add(ErrorInterceptor());
  try {
    await dio.patch('/mobile/inventory/price', data: {'productId': 1});
  } on DioException catch (e) {
    return e;
  }
  fail('expected a DioException for HTTP $status');
}

void main() {
  group('ErrorInterceptor with the Spring ErrorResponse shape', () {
    // The exact body the backend sends for a BusinessException. Note that
    // `error` is a String (reason phrase), which used to crash the parser.
    const priceBelowMin =
        '{"timestamp":"2026-11-10T16:30:00Z","status":400,'
        '"error":"Bad Request",'
        '"message":"Price is below the minimum allowed (2000000)",'
        '"code":"PRICE_BELOW_MIN","path":"/api/v1/mobile/inventory/price"}';

    test('400 keeps the backend message and business code', () async {
      final e = await _fail(400, priceBelowMin);

      expect(e.error, isA<ValidationException>());
      final api = e.error as ValidationException;
      expect(api.code, 'PRICE_BELOW_MIN');
      expect(api.message, 'Price is below the minimum allowed (2000000)');
      expect(e.response?.statusCode, 400);
      expect(
        extractErrorMessage(e),
        'Price is below the minimum allowed (2000000)',
      );
    });

    test('403 surfaces "Access denied" rather than a generic line', () async {
      final e = await _fail(
        403,
        '{"status":403,"error":"Forbidden","message":"Access denied",'
        '"path":"/api/v1/mobile/inventory/price"}',
      );

      expect(e.error, isA<ForbiddenException>());
      expect(extractErrorMessage(e), 'Access denied');
    });

    test('404 surfaces the backend message', () async {
      final e = await _fail(
        404,
        '{"status":404,"error":"Not Found","message":"Product not found",'
        '"code":"NOT_FOUND"}',
      );

      expect(e.error, isA<NotFoundException>());
      expect(extractErrorMessage(e), 'Product not found');
    });

    test('@Valid failures append the field errors', () async {
      final e = await _fail(
        400,
        '{"status":400,"error":"Validation Failed",'
        '"message":"Validation failed",'
        '"validationErrors":[{"field":"sellingPrice",'
        '"message":"Selling price must be greater than zero",'
        '"rejectedValue":0}]}',
      );

      final api = e.error as ValidationException;
      expect(api.details, [
        'sellingPrice: Selling price must be greater than zero',
      ]);
      expect(
        extractErrorMessage(e),
        'Validation failed: sellingPrice: Selling price must be greater than '
        'zero',
      );
    });

    test('500 with a JSON body keeps its message', () async {
      final e = await _fail(
        500,
        '{"status":500,"error":"Internal Server Error",'
        '"message":"An unexpected error occurred"}',
      );

      expect(e.error, isA<ApiException>());
      expect((e.error as ApiException).statusCode, 500);
      expect(extractErrorMessage(e), 'An unexpected error occurred');
    });
  });

  group('ErrorInterceptor with other body shapes', () {
    test('nested {"error": {...}} object still works', () async {
      final e = await _fail(
        400,
        '{"error":{"message":"Bad input","code":"BAD_INPUT",'
        '"details":["qty must be > 0"]}}',
      );

      final api = e.error as ValidationException;
      expect(api.message, 'Bad input: qty must be > 0');
      expect(api.code, 'BAD_INPUT');
      expect(api.details, ['qty must be > 0']);
    });

    test('HTML gateway page falls back to a status-bearing message', () async {
      final e = await _fail(
        502,
        '<html><body><h1>502 Bad Gateway</h1></body></html>',
        contentType: 'text/html',
      );

      expect(e.error, isA<ApiException>());
      expect(
        extractErrorMessage(e),
        'Server error (502). Please try again later.',
      );
    });

    test('empty body never yields the opaque generic line', () async {
      final e = await _fail(409, '');

      expect(extractErrorMessage(e), 'Request failed (409). Please try again.');
    });

    test('401 is left for AuthInterceptor', () async {
      final e = await _fail(401, '{"message":"Invalid or expired token"}');

      expect(e.error, isNot(isA<ApiException>()));
      expect(e.response?.statusCode, 401);
      // The message is still readable through the body.
      expect(extractErrorMessage(e), 'Invalid or expired token');
    });
  });

  group('parseErrorBody', () {
    test('never throws on odd input', () {
      expect(parseErrorBody(null).message, isNull);
      expect(parseErrorBody(42).message, isNull);
      expect(parseErrorBody('{not json').message, isNull);
      expect(parseErrorBody(['a', 'b']).message, isNull);
      expect(parseErrorBody({'error': 123}).message, isNull);
    });

    test('short plain text is used as the message', () {
      expect(
        parseErrorBody('Service unavailable').message,
        'Service unavailable',
      );
    });

    test('reason phrase is the message of last resort', () {
      expect(parseErrorBody({'error': 'Forbidden'}).message, 'Forbidden');
      expect(
        parseErrorBody({'error': 'Forbidden', 'message': 'No access'}).message,
        'No access',
      );
    });
  });

  group('extractErrorMessage fallbacks', () {
    final opts = RequestOptions(path: '/x');

    test('bad response without body reports the status', () {
      final e = DioException(
        requestOptions: opts,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: opts, statusCode: 503),
      );
      expect(extractErrorMessage(e), 'Request failed (503). Please try again.');
    });

    test('unknown error without response stays generic', () {
      final e = DioException(requestOptions: opts, error: StateError('x'));
      expect(extractErrorMessage(e), 'Something went wrong. Please try again.');
    });

    test('timeouts read as a connectivity problem', () {
      final e = DioException(
        requestOptions: opts,
        type: DioExceptionType.receiveTimeout,
      );
      expect(
        extractErrorMessage(e),
        'No internet connection. Please check your network.',
      );
    });
  });
}
