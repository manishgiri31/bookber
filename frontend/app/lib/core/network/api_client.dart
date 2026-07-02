import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';
import '../errors/exceptions.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  ApiClient({SecureStorage? storage, this.onSessionExpired})
      : _storage = storage ?? SecureStorage.instance {
    final opts = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    _dio = Dio(opts);

    // Separate Dio instance used exclusively for token refresh.
    // It has NO auth interceptor, preventing the deadlock that occurs when
    // the refresh request itself gets a 401 and re-enters the error handler.
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_storage, _dio, _refreshDio, onSessionExpired),
      if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  final SecureStorage _storage;
  final void Function()? onSessionExpired;
  late final Dio _dio;
  late final Dio _refreshDio;

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
  _AuthInterceptor(this._storage, this._dio, this._refreshDio, this._onSessionExpired);

  final SecureStorage _storage;
  final Dio _dio;
  final Dio _refreshDio;
  final void Function()? _onSessionExpired;

  /// Non-null while a refresh is in flight. Concurrent 401s await this
  /// instead of each kicking off their own refresh or failing immediately.
  Future<String?>? _refreshFuture;

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
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final newAccessToken = await (_refreshFuture ??= _refresh());
    if (newAccessToken == null) {
      handler.next(err);
      return;
    }

    try {
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retry = await _dio.fetch<dynamic>(err.requestOptions);
      handler.resolve(retry);
    } catch (_) {
      handler.next(err);
    }
  }

  /// Performs the token refresh once; concurrent callers share this Future.
  /// Uses _refreshDio (no interceptors) to avoid a deadlock where the refresh
  /// request's own 401 would re-enter onError and await _refreshFuture.
  Future<String?> _refresh() async {
    try {
      final refreshToken = await _storage.refreshToken;
      if (refreshToken == null) return null;

      final response = await _refreshDio.post<dynamic>(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data as Map<String, dynamic>;
      final newAccessToken = data['accessToken'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;

      if (newAccessToken == null || newRefreshToken == null) return null;

      await _storage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
      return newAccessToken;
    } catch (_) {
      await _storage.clearSession();
      _onSessionExpired?.call();
      return null;
    } finally {
      _refreshFuture = null;
    }
  }
}
