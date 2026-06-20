sealed class AppException implements Exception {
  const AppException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  const NetworkException(super.message, {super.statusCode});
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Session expired. Please sign in again.']);
}

final class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'You do not have permission to do this.']);
}

final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'The requested resource was not found.']);
}

final class ValidationException extends AppException {
  const ValidationException(super.message, {this.fieldErrors = const {}});
  final Map<String, String> fieldErrors;
}

final class ServerException extends AppException {
  const ServerException([super.message = 'Something went wrong. Please try again.']);
}

final class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Request timed out. Check your connection.']);
}

final class NoInternetException extends AppException {
  const NoInternetException([super.message = 'No internet connection.']);
}

final class CacheException extends AppException {
  const CacheException([super.message = 'Failed to read stored data.']);
}
