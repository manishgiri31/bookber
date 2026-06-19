import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/bookber_models.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';

class BookingRepository {
  BookingRepository(this._dioClient);

  final DioClient _dioClient;

  Future<ApiResult<List<TimeSlot>>> getAvailableSlots(
    String barberId,
    DateTime date,
    int durationMinutes,
  ) async {
    return ApiResult.guard(() async {
      final queryParams = {
        'date': DateTime(date.year, date.month, date.day).toIso8601String().split('T').first,
        'duration': durationMinutes,
      };
      final response = await _dioClient.get('/barbers/$barberId/slots', queryParams: queryParams);
      final raw = response as Map<String, dynamic>? ?? {};
      final slots = (raw['slots'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(TimeSlot.fromJson)
              .toList() ??
          [];
      return slots;
    });
  }

  Future<ApiResult<Booking>> createBooking({
    required String shopId,
    String? barberId,
    List<String> serviceIds = const [],
    bool walkIn = false,
  }) async {
    return ApiResult.guard(() async {
      final body = <String, dynamic>{
        'shopId': shopId,
        if (barberId != null) 'barberId': barberId,
        'serviceIds': serviceIds,
        'walkIn': walkIn,
      };

      final response = await _dioClient.post('/bookings', body: body);
      final data = response as Map<String, dynamic>? ?? {};
      return Booking.fromJson(
        data['booking'] is Map<String, dynamic> ? data['booking'] as Map<String, dynamic> : data,
      );
    });
  }

  Future<ApiResult<List<Booking>>> getMyBookings() async {
    return ApiResult.guard(() async {
      final response = await _dioClient.get('/bookings/my');
      final data = response as Map<String, dynamic>? ?? {};
      final list = data['bookings'] as List? ?? data['data'] as List? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(Booking.fromJson)
          .toList();
    });
  }

  Future<ApiResult<List<Booking>>> fetchHistory() => getMyBookings();

  Future<ApiResult<List<ServiceItem>>> fetchServices(String shopId) async {
    return ApiResult.guard(() async {
      final response = await _dioClient.get('/shops/$shopId/services');
      final data = response as Map<String, dynamic>? ?? {};
      final list = data['services'] as List? ?? data['data'] as List? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(ServiceItem.fromJson)
          .toList();
    });
  }

  Future<ApiResult<Booking>> getBookingById(String bookingId) async {
    return ApiResult.guard(() async {
      final response = await _dioClient.get('/bookings/$bookingId');
      final data = response as Map<String, dynamic>? ?? {};
      return Booking.fromJson(
        data['booking'] is Map<String, dynamic> ? data['booking'] as Map<String, dynamic> : data,
      );
    });
  }

  Future<ApiResult<void>> cancelBooking(String bookingId) async {
    return ApiResult.guard(() async {
      await _dioClient.patch('/bookings/$bookingId/cancel');
    });
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepository(ref.read(dioClientProvider)),
);
