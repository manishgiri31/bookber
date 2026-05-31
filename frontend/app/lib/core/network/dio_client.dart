import 'package:dio/dio.dart';

import '../storage/app_storage.dart';
import 'api_exception.dart';

class DioClient {
  DioClient({
    required String baseUrl,
    required AppStorage storage,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = storage.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          String? message;
          final data = error.response?.data;
          if (data is Map<String, dynamic>) {
            final errorMap = data['error'];
            if (errorMap is Map<String, dynamic>) {
              message = errorMap['message']?.toString();
            } else {
              message = data['message']?.toString();
            }
          }
          message ??= error.message;
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: ApiException(message ?? 'Request failed', statusCode: error.response?.statusCode),
              response: error.response,
              type: error.type,
            ),
          );
        },
      ),
    );
  }

  final Dio dio;
}
