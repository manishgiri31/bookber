import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/bookber_models.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';

class QueueRepository {
  QueueRepository(this._dio);

  final DioClient _dio;

  Future<ApiResult<Map<String, dynamic>>> getQueueStatus(String shopId) async {
    return ApiResult.guard(() async {
      final response = await _dio.get('/api/queue/shop/$shopId/status');
      return response is Map<String, dynamic> ? response : <String, dynamic>{};
    });
  }

  Future<ApiResult<QueueEntry>> joinQueue(String shopId, List<String> serviceIds) async {
    return ApiResult.guard(() async {
      final response = await _dio.post(
        '/api/queue/join',
        body: {'shopId': shopId, 'serviceIds': serviceIds},
      );
      final json = response is Map<String, dynamic>
          ? (response['entry'] as Map<String, dynamic>?) ?? response
          : <String, dynamic>{};
      return QueueEntry.fromJson(json);
    });
  }

  Future<ApiResult<void>> leaveQueue(String queueEntryId) async {
    return ApiResult.guard(() async {
      await _dio.delete('/api/queue/$queueEntryId');
    });
  }

  Future<ApiResult<void>> checkIn(String queueEntryId) async {
    return ApiResult.guard(() async {
      await _dio.patch('/api/queue/$queueEntryId/checkin');
    });
  }

  Future<ApiResult<QueueStateModel>> fetchQueue(String shopId) async {
    return ApiResult.guard(() async {
      final response = await _dio.get('/api/queue/shop/$shopId/status');
      final json = response is Map<String, dynamic> ? response : <String, dynamic>{};
      return QueueStateModel(
        bookingId: json['myEntryId']?.toString() ?? json['bookingId']?.toString() ?? '',
        position: _asInt(json['myPosition'], fallback: -1),
        etaMinutes: _asInt(json['estimatedWaitMinutes']),
        status: json['status']?.toString() ?? 'WAITING',
        chairLabel: json['chairLabel']?.toString() ?? '',
      );
    });
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    return value is int ? value : int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

final queueRepositoryProvider = Provider<QueueRepository>((ref) {
  return QueueRepository(ref.read(dioClientProvider));
});
