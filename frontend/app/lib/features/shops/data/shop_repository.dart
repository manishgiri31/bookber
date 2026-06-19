import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../domain/shop_models.dart';

class ShopRepository {
  ShopRepository(this._dio);

  final DioClient _dio;

  Future<ApiResult<ShopPage>> searchShops({
    String? query,
    String? city,
    double? latitude,
    double? longitude,
    double? radiusKm,
    bool? isActive,
    int page = 1,
    int limit = 20,
  }) async {
    return ApiResult.guard(() async {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (query != null && query.isNotEmpty) 'query': query,
        if (city != null && city.isNotEmpty) 'city': city,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (radiusKm != null) 'radiusKm': radiusKm,
        if (isActive != null) 'isActive': isActive,
      };
      final response = await _dio.get('/shops', queryParams: params);
      return ShopPage.fromJson(response as Map<String, dynamic>);
    });
  }

  Future<ApiResult<ShopDetail>> getShop(String shopId) async {
    return ApiResult.guard(() async {
      final response = await _dio.get('/shops/$shopId');
      return ShopDetail.fromJson(response as Map<String, dynamic>);
    });
  }

  Future<ApiResult<ShopDetail>> getMyShop() async {
    return ApiResult.guard(() async {
      final response = await _dio.get('/shops/my');
      return ShopDetail.fromJson(response as Map<String, dynamic>);
    });
  }

  Future<ApiResult<List<ShopService>>> getServices(
    String shopId, {
    String? query,
    bool? isActive,
    int page = 1,
    int limit = 50,
  }) async {
    return ApiResult.guard(() async {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (query != null) 'query': query,
        if (isActive != null) 'isActive': isActive,
      };
      final response = await _dio.get('/shops/$shopId/services', queryParams: params);
      final data = response as Map<String, dynamic>;
      final list = data['data'] is List
          ? data['data'] as List
          : response is List
              ? response as List
              : [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(ShopService.fromJson)
          .toList();
    });
  }

  Future<ApiResult<ShopDetail>> createShop(Map<String, dynamic> body) async {
    return ApiResult.guard(() async {
      final response = await _dio.post('/shops', body: body);
      return ShopDetail.fromJson(response as Map<String, dynamic>);
    });
  }

  Future<ApiResult<ShopDetail>> updateShop(
    String shopId,
    Map<String, dynamic> body,
  ) async {
    return ApiResult.guard(() async {
      final response = await _dio.patch('/shops/$shopId', body: body);
      return ShopDetail.fromJson(response as Map<String, dynamic>);
    });
  }

  Future<ApiResult<ShopService>> createService(
    String shopId,
    Map<String, dynamic> body,
  ) async {
    return ApiResult.guard(() async {
      final response = await _dio.post('/shops/$shopId/services', body: body);
      return ShopService.fromJson(response as Map<String, dynamic>);
    });
  }

  Future<ApiResult<ShopService>> updateService(
    String serviceId,
    Map<String, dynamic> body,
  ) async {
    return ApiResult.guard(() async {
      final response = await _dio.patch('/shops/services/$serviceId', body: body);
      return ShopService.fromJson(response as Map<String, dynamic>);
    });
  }

  Future<ApiResult<void>> deleteService(String serviceId) async {
    return ApiResult.guard(() async {
      await _dio.delete('/shops/services/$serviceId');
    });
  }
}

final shopRepositoryProvider = Provider<ShopRepository>(
  (ref) => ShopRepository(ref.watch(dioClientProvider)),
);
