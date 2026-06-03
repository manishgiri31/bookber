import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  factory ApiException.fromDioException(dynamic error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      if (error.error is ApiException) {
        return error.error as ApiException;
      }

      if (error.type == DioExceptionType.connectionError) {
        return ApiException('No internet connection', code: 'NO_INTERNET');
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return ApiException('Request timeout', code: 'TIMEOUT');
      }

      final statusCode = error.response?.statusCode;
      final data = _normalizeResponseData(error.response?.data);
      final message = _extractMessage(data) ?? error.message ?? 'Request failed';
      final code = _extractCode(data);

      if (statusCode == 401) {
        return ApiException('Session expired', code: 'SESSION_EXPIRED', statusCode: statusCode);
      }

      if (statusCode != null && statusCode >= 500) {
        return ApiException(message, code: code ?? 'SERVER_ERROR', statusCode: statusCode);
      }

      if (statusCode != null && statusCode >= 400) {
        return ApiException(message, code: code, statusCode: statusCode);
      }

      return ApiException(message, code: code, statusCode: statusCode);
    }

    return ApiException(error.toString(), code: 'UNKNOWN_ERROR');
  }

  static Map<String, dynamic>? _normalizeResponseData(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  static String? _extractMessage(Map<String, dynamic>? data) {
    if (data == null) return null;
    if (data['message'] is String) {
      return data['message'] as String;
    }
    if (data['error'] is Map<String, dynamic>) {
      return (data['error'] as Map<String, dynamic>)['message']?.toString();
    }
    return null;
  }

  static String? _extractCode(Map<String, dynamic>? data) {
    if (data == null) return null;
    if (data['code'] is String) {
      return data['code'] as String;
    }
    if (data['error'] is Map<String, dynamic>) {
      return (data['error'] as Map<String, dynamic>)['code']?.toString();
    }
    return null;
  }

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
