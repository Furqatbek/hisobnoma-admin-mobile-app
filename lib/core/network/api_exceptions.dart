/// Typed API exceptions mapped from HTTP error responses
class ApiException implements Exception {
  final String code;
  final String message;
  final List<String>? details;
  final int? statusCode;

  const ApiException({
    required this.code,
    required this.message,
    this.details,
    this.statusCode,
  });

  @override
  String toString() => 'ApiException($code): $message';
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({String message = 'Invalid or expired token'})
    : super(code: 'UNAUTHORIZED', message: message, statusCode: 401);
}

class ForbiddenException extends ApiException {
  const ForbiddenException({String message = 'Insufficient permissions'})
    : super(code: 'ACCESS_DENIED', message: message, statusCode: 403);
}

class NotFoundException extends ApiException {
  const NotFoundException({String message = 'Resource not found'})
    : super(code: 'NOT_FOUND', message: message, statusCode: 404);
}

class ValidationException extends ApiException {
  const ValidationException({
    String message = 'Invalid request parameters',
    List<String>? details,
  }) : super(
         code: 'VALIDATION_ERROR',
         message: message,
         details: details,
         statusCode: 400,
       );
}

class RateLimitException extends ApiException {
  final DateTime? resetAt;

  const RateLimitException({this.resetAt})
    : super(
        code: 'RATE_LIMITED',
        message: 'Too many requests',
        statusCode: 429,
      );
}

class NetworkException extends ApiException {
  const NetworkException({String message = 'Network connection error'})
    : super(code: 'NETWORK_ERROR', message: message);
}
