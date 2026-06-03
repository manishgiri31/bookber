import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/config/app_env.dart';
import '../../app/router/app_router.dart';
import '../storage/app_storage.dart';
import 'api_exception.dart';

class DioClient {
  DioClient({AppStorage? storage})
      : _storage = storage ?? AppStorage(),
        dio = Dio(
          BaseOptions(
            baseUrl: AppEnv.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(
      AuthInterceptor(
        storage: _storage,
        dio: dio,
        baseUrl: AppEnv.baseUrl,
        routerKey: appRouterKey,
      ),
    );
  }

  final AppStorage _storage;
  final Dio dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await dio.get(path, queryParameters: queryParams);
      return response.data;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    try {
      final response = await dio.post(path, data: body);
      return response.data;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<dynamic> patch(String path, {dynamic body}) async {
    try {
      final response = await dio.patch(path, data: body);
      return response.data;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await dio.delete(path);
      return response.data;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required AppStorage storage,
    required Dio dio,
    required String baseUrl,
    required GlobalKey<NavigatorState> routerKey,
  })  : _storage = storage,
        _dio = dio,
        _routerKey = routerKey,
        _refreshDio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

  final AppStorage _storage;
  final Dio _dio;
  final GlobalKey<NavigatorState> _routerKey;
  final Dio _refreshDio;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException error, ErrorInterceptorHandler handler) async {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      await _handle401(error, handler);
      return;
    }

    final apiException = _buildApiException(error);
    handler.reject(
      DioException(
        requestOptions: error.requestOptions,
        response: error.response,
        type: error.type,
        error: apiException,
      ),
    );
  }

  Future<void> _handle401(DioException error, ErrorInterceptorHandler handler) async {
    final requestOptions = error.requestOptions;
    final hasRetried = requestOptions.extra['retry'] == true;
    final refreshToken = await _storage.getRefreshToken();

    if (hasRetried || refreshToken == null) {
      await _clearSessionAndRedirect();
      handler.reject(
        DioException(
          requestOptions: requestOptions,
          response: error.response,
          type: error.type,
          error: ApiException(
            'Session expired',
            code: 'SESSION_EXPIRED',
            statusCode: 401,
          ),
        ),
      );
      return;
    }

    try {
      final refreshResponse = await _refreshDio.post(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final payload = _normalizeResponseData(refreshResponse.data);
      final accessToken = _extractToken(payload, ['accessToken', 'access_token', 'token']);
      final newRefreshToken = _extractToken(payload, ['refreshToken', 'refresh_token']);

      if (accessToken == null || newRefreshToken == null) {
        throw ApiException('Invalid refresh response', code: 'SESSION_EXPIRED', statusCode: 401);
      }

      await _storage.saveTokens(accessToken, newRefreshToken);

      final retryOptions = requestOptions.copyWith(
        headers: {
          ...requestOptions.headers,
          'Authorization': 'Bearer $accessToken',
        },
        extra: {
          ...requestOptions.extra,
          'retry': true,
        },
      );

      final retryResponse = await _dio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } on DioException catch (refreshError) {
      await _clearSessionAndRedirect();
      handler.reject(
        DioException(
          requestOptions: requestOptions,
          response: refreshError.response,
          type: refreshError.type,
          error: ApiException(
            'Session expired',
            code: 'SESSION_EXPIRED',
            statusCode: refreshError.response?.statusCode ?? 401,
          ),
        ),
      );
    } catch (_) {
      await _clearSessionAndRedirect();
      handler.reject(
        DioException(
          requestOptions: requestOptions,
          response: error.response,
          type: error.type,
          error: ApiException(
            'Session expired',
            code: 'SESSION_EXPIRED',
            statusCode: 401,
          ),
        ),
      );
    }
  }

  ApiException _buildApiException(DioException error) {
    if (error.type == DioExceptionType.connectionError) {
      return ApiException('No internet connection', code: 'NO_INTERNET');
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return ApiException('Request timeout', code: 'TIMEOUT');
    }

    final statusCode = error.response?.statusCode;
    final body = _normalizeResponseData(error.response?.data);
    final message = _extractErrorMessage(body) ?? error.message ?? 'Request failed';
    final code = _extractErrorCode(body);

    if (statusCode != null && statusCode >= 500) {
      return ApiException(message, code: code ?? 'SERVER_ERROR', statusCode: statusCode);
    }

    if (statusCode != null && statusCode >= 400) {
      return ApiException(message, code: code, statusCode: statusCode);
    }

    return ApiException(message, code: code, statusCode: statusCode);
  }

  Future<void> _clearSessionAndRedirect() async {
    await _storage.clearTokens();
    _redirectToLogin();
  }

  void _redirectToLogin() {
    final context = _routerKey.currentContext;
    if (context != null) {
      GoRouter.of(context).go('/login');
    }
  }

  Map<String, dynamic>? _normalizeResponseData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    return null;
  }

  String? _extractToken(Map<String, dynamic>? data, List<String> keys) {
    if (data == null) return null;

    for (final key in keys) {
      final value = data[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
      if (value != null) {
        return value.toString();
      }
    }
    return null;
  }

  String? _extractErrorMessage(Map<String, dynamic>? data) {
    if (data == null) return null;
    if (data['message'] is String) {
      return data['message'] as String;
    }
    if (data['error'] is Map<String, dynamic>) {
      return (data['error'] as Map<String, dynamic>)['message']?.toString();
    }
    return null;
  }

  String? _extractErrorCode(Map<String, dynamic>? data) {
    if (data == null) return null;
    if (data['code'] is String) {
      return data['code'] as String;
    }
    if (data['error'] is Map<String, dynamic>) {
      return (data['error'] as Map<String, dynamic>)['code']?.toString();
    }
    return null;
  }
}

final dioClientProvider = Provider<DioClient>((ref) => DioClient());
