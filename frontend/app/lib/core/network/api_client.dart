import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';
import '../errors/exceptions.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  ApiClient({SecureStorage? storage})
      : _storage = storage ?? SecureStorage.instance {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_storage, _dio),
      if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  final SecureStorage _storage;
  late final Dio _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? params,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _send(() => _dio.get<dynamic>(path, queryParameters: params));
    return fromJson != null ? fromJson(response.data) : response.data as T;
  }

  Future<T> post<T>(
    String path, {
    dynamic body,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _send(() => _dio.post<dynamic>(path, data: body));
    return fromJson != null ? fromJson(response.data) : response.data as T;
  }

  Future<T> patch<T>(
    String path, {
    dynamic body,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _send(() => _dio.patch<dynamic>(path, data: body));
    return fromJson != null ? fromJson(response.data) : response.data as T;
  }

  Future<T> delete<T>(
    String path, {
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _send(() => _dio.delete<dynamic>(path));
    return fromJson != null ? fromJson(response.data) : response.data as T;
  }

  Future<Response<dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw _mapDioError(e);
    } on SocketException {
      throw const NoInternetException();
    }
  }

  AppException _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const TimeoutException();
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NoInternetException();
    }
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    final message = _extractMessage(data);
    final code = statusCode ?? 0;

    return switch (code) {
      400 => ValidationException(message ?? 'Invalid request.'),
      401 => const UnauthorizedException(),
      403 => const ForbiddenException(),
      404 => NotFoundException(message ?? 'Not found.'),
      422 => ValidationException(message ?? 'Validation failed.'),
      >= 500 => ServerException(message ?? 'Server error. Please try again.'),
      _ => NetworkException(message ?? 'Network error.', statusCode: statusCode),
    };
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final err = data['error'];
      if (err is Map<String, dynamic>) {
        return err['message']?.toString();
      }
      return (data['message'] ?? err)?.toString();
    }
    return null;
  }

  Future<void> setAuthToken(String token) async {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._storage, this._dio);

  final SecureStorage _storage;
  final Dio _dio;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _storage.refreshToken;
        if (refreshToken == null) {
          _isRefreshing = false;
          handler.next(err);
          return;
        }

        final response = await _dio.post<dynamic>(
          ApiEndpoints.refresh,
          data: {'refreshToken': refreshToken},
        );

        final data = response.data as Map<String, dynamic>;
        final newAccessToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (newAccessToken != null && newRefreshToken != null) {
          await _storage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          _isRefreshing = false;
          final retry = await _dio.fetch<dynamic>(err.requestOptions);
          handler.resolve(retry);
          return;
        }
      } catch (_) {
        await _storage.clearSession();
      }
      _isRefreshing = false;
    }
    handler.next(err);
  }
}
