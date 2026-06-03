import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/bookber_models.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';

class BarberDashboardRepository {
  BarberDashboardRepository(this._dioClient);

  final DioClient _dioClient;

  Future<ApiResult<BarberStats>> getStats(String barberId) async {
    return ApiResult.guard(() async {
      final response = await _dioClient.get('/api/barbers/$barberId/stats', queryParams: {'date': 'today'});
      final json = response is Map<String, dynamic> ? response : <String, dynamic>{};
      return BarberStats.fromJson(json);
    });
  }

  Future<ApiResult<List<QueueEntry>>> getMyQueue(String barberId) async {
    return ApiResult.guard(() async {
      final response = await _dioClient.get('/api/barbers/$barberId/queue');
      final items = (response['queue'] as List<dynamic>?) ?? response['entries'] as List<dynamic>? ?? response as List<dynamic>;
      final list = items
          .whereType<Map<String, dynamic>>()
          .map((e) => QueueEntry.fromJson(e))
          .toList(growable: false);
      return list;
    });
  }

  Future<ApiResult<List<Booking>>> getTodayBookings(String barberId) async {
    return ApiResult.guard(() async {
      final today = DateTime.now().toIso8601String().split('T').first;
      final response = await _dioClient.get('/api/barbers/$barberId/bookings', queryParams: {'date': today});
      final items = (response['bookings'] as List<dynamic>?) ?? response as List<dynamic>;
      final list = items
          .whereType<Map<String, dynamic>>()
          .map(Booking.fromJson)
          .toList(growable: false);
      return list;
    });
  }

  Future<ApiResult<void>> updateQueueEntryStatus(String entryId, String status) async {
    return ApiResult.guard(() async {
      await _dioClient.patch('/api/queue/$entryId/status', body: {'status': status});
    });
  }

  Future<ApiResult<void>> addWalkIn(String shopId, List<String> serviceIds, String? customerName) async {
    return ApiResult.guard(() async {
      final body = {'shopId': shopId, 'serviceIds': serviceIds};
      if (customerName != null && customerName.isNotEmpty) body['customerName'] = customerName;
      await _dioClient.post('/api/queue/walk-in', body: body);
    });
  }

  Future<ApiResult<void>> updateBarberStatus(String barberId, bool isOnline) async {
    return ApiResult.guard(() async {
      await _dioClient.patch('/api/barbers/$barberId/status', body: {'isAvailable': isOnline});
    });
  }

  Future<ApiResult<List<WorkingHour>>> getWorkingHours(String barberId) async {
    return ApiResult.guard(() async {
      final response = await _dioClient.get('/api/barbers/$barberId/working-hours');
      final items = (response['hours'] as List<dynamic>?) ?? response as List<dynamic>;
      final list = items
          .whereType<Map<String, dynamic>>()
          .map(WorkingHour.fromJson)
          .toList(growable: false);
      return list;
    });
  }

  Future<ApiResult<void>> saveWorkingHours(String barberId, List<WorkingHour> hours) async {
    return ApiResult.guard(() async {
      final body = {'hours': hours.map((h) => h.toJson()).toList()};
      await _dioClient.post('/api/barbers/$barberId/working-hours', body: body);
    });
  }
}

final barberDashboardRepositoryProvider = Provider<BarberDashboardRepository>((ref) {
  return BarberDashboardRepository(ref.read(dioClientProvider));
});
