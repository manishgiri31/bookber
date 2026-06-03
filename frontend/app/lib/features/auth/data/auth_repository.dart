import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/models/bookber_models.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final DioClient _dio;

  Future<ApiResult<AuthResponse>> login(
    String email,
    String password,
    String role,
  ) async {
    return ApiResult.guard(() async {
      final response = await _dio.post(
        '/api/auth/login',
        body: {
          'email': email,
          'password': password,
          'role': role,
        },
      );
      return AuthResponse.fromJson(response as Map<String, dynamic>);
    });
  }

  Future<ApiResult<AuthResponse>> register(RegisterRequest req) async {
    return ApiResult.guard(() async {
      final response = await _dio.post(
        '/api/auth/register',
        body: req.toJson(),
      );
      return AuthResponse.fromJson(response as Map<String, dynamic>);
    });
  }

  Future<ApiResult<UserProfile>> getMe() async {
    return ApiResult.guard(() async {
      final response = await _dio.get('/api/auth/me');
      return UserProfile.fromJson(response as Map<String, dynamic>);
    });
  }

  Future<ApiResult<void>> logout() async {
    return ApiResult.guard(() async {
      await _dio.post('/api/auth/logout');
    });
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioClientProvider)),
);
