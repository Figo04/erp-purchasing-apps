// Custom API Exception Classes
// Provides detailed error information for different scenarios

// Base API Exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic error;

  ApiException({
    required this.message,
    this.statusCode,
    this.error,
  });

  @override
  String toString() => message;
}

// Network related errors (no internet, timeout, etc)
class NetworkException extends ApiException {
  NetworkException({
    String message = 'Network error occurred',
    dynamic error,
  }) : super(
          message: message,
          statusCode: null,
          error: error,
        );
}

// Authentication/Authorization errors (401, 403)
class UnauthorizedException extends ApiException {
  UnauthorizedException({
    String message = 'Unauthorized access',
    int? statusCode,
    dynamic error,
  }) : super(
          message: message,
          statusCode: statusCode ?? 401,
          error: error,
        );
}

// Validation errors (400)
class ValidationException extends ApiException {
  ValidationException({
    String message = 'Validation failed',
    dynamic error,
  }) : super(
          message: message,
          statusCode: 400,
          error: error,
        );
}

// Not found errors (404)
class NotFoundException extends ApiException {
  NotFoundException({
    String message = 'Resource not found',
    dynamic error,
  }) : super(
          message: message,
          statusCode: 404,
          error: error,
        );
}

// Server errors (500+)
class ServerException extends ApiException {
  ServerException({
    String message = 'Server error occurred',
    int? statusCode,
    dynamic error,
  }) : super(
          message: message,
          statusCode: statusCode ?? 500,
          error: error,
        );
}

// Timeout errors
class TimeoutException extends ApiException {
  TimeoutException({
    String message = 'Request timeout',
    dynamic error,
  }) : super(
          message: message,
          statusCode: 408,
          error: error,
        );
}

// Bad request errors (400)
class BadRequestException extends ApiException {
  BadRequestException({
    String message = 'Bad request',
    dynamic error,
  }) : super(
          message: message,
          statusCode: 400,
          error: error,
        );
}

// Conflict errors (409)
class ConflictException extends ApiException {
  ConflictException({
    String message = 'Resource conflict',
    dynamic error,
  }) : super(
          message: message,
          statusCode: 409,
          error: error,
        );
}

// Generic HTTP exception for other status codes
class HttpException extends ApiException {
  HttpException({
    required String message,
    required int statusCode,
    dynamic error,
  }) : super(
          message: message,
          statusCode: statusCode,
          error: error,
        );
}

// Helper function to create appropriate exception based on status code
ApiException createException({
  required int statusCode,
  required String message,
  dynamic error,
}) {
  switch (statusCode) {
    case 400:
      return BadRequestException(message: message, error: error);
    case 401:
    case 403:
      return UnauthorizedException(
        message: message,
        statusCode: statusCode,
        error: error,
      );
    case 404:
      return NotFoundException(message: message, error: error);
    case 408:
      return TimeoutException(message: message, error: error);
    case 409:
      return ConflictException(message: message, error: error);
    case 422:
      return ValidationException(message: message, error: error);
    case >= 500:
      return ServerException(
        message: message,
        statusCode: statusCode,
        error: error,
      );
    default:
      return HttpException(
        message: message,
        statusCode: statusCode,
        error: error,
      );
  }
}