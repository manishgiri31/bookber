import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/models/bookber_models.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final DioClient _dio;

  Future<ApiResult<AuthResponse>> login(String identifier, String password) async {
    return ApiResult.guard(() async {
      final response = await _dio.post(
        '/auth/login',
        body: {'identifier': identifier, 'password': password},
      );
      return AuthResponse.fromJson(response as Map<String, dynamic>);
    });
  }

  Future<ApiResult<AuthResponse>> register(RegisterRequest req) async {
    return ApiResult.guard(() async {
      final response = await _dio.post('/auth/register', body: req.toJson());
      return AuthResponse.fromJson(response as Map<String, dynamic>);
    });
  }

  Future<ApiResult<UserProfile>> getMe() async {
    return ApiResult.guard(() async {
      final response = await _dio.get('/auth/me');
      final data = response as Map<String, dynamic>;
      final userData = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : data;
      return UserProfile.fromJson(userData);
    });
  }

  Future<ApiResult<AuthResponse>> refresh(String refreshToken) async {
    return ApiResult.guard(() async {
      final response = await _dio.post(
        '/auth/refresh',
        body: {'refreshToken': refreshToken},
      );
      return AuthResponse.fromJson(response as Map<String, dynamic>);
    });
  }

  Future<ApiResult<void>> logout() async {
    return ApiResult.guard(() async {
      await _dio.post('/auth/logout');
    });
  }

  Future<ApiResult<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return ApiResult.guard(() async {
      await _dio.patch('/auth/change-password', body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    });
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioClientProvider)),
);
