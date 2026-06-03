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
      final response = await _dioClient.get('/api/barbers/$barberId/slots', queryParams: queryParams);
      final slots = (response['slots'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(TimeSlot.fromJson)
              .toList() ??
          [];
      return slots;
    });
  }

  Future<ApiResult<Booking>> createBooking({
    BookingFormState? formState,
    String? barberId,
    String? barberName,
    List<ServiceItem>? services,
    DateTime? scheduledAt,
  }) async {
    return ApiResult.guard(() async {
      final form = formState;
      final body = <String, dynamic>{
        'shopId': form?.shopId ?? '',
        'barberId': form?.selectedBarberId ?? barberId,
        'serviceIds': form?.selectedServiceIds ?? services?.map((service) => service.id).toList() ?? const <String>[],
        'paymentMethod': form?.paymentMethod ?? 'cash',
        'mode': form?.isJoinQueue == true ? 'queue' : 'appointment',
      };

      final slotTime = form?.selectedSlot?.startTime ?? scheduledAt;
      if (slotTime != null) {
        body['scheduledAt'] = slotTime.toIso8601String();
      }

      final response = await _dioClient.post('/api/bookings', body: body);
      final bookingJson = response is Map<String, dynamic>
          ? (response['booking'] as Map<String, dynamic>?) ?? response
          : <String, dynamic>{};
      return Booking.fromJson(bookingJson);
    });
  }

  Future<ApiResult<List<Booking>>> getMyBookings() async {
    return ApiResult.guard(() async {
      final response = await _dioClient.get('/api/bookings/my');
      final bookings = (response['bookings'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(Booking.fromJson)
              .toList() ??
          [];
      return bookings;
    });
  }

  Future<ApiResult<List<Booking>>> fetchHistory() => getMyBookings();

  Future<ApiResult<List<ServiceItem>>> fetchServices(String shopId) async {
    return ApiResult.guard(() async {
      final response = await _dioClient.get('/api/shops/$shopId/services');
      final items = response is Map<String, dynamic>
          ? (response['services'] as List<dynamic>?) ?? response['data'] as List<dynamic>? ?? const <dynamic>[]
          : response is List<dynamic>
              ? response
              : const <dynamic>[];
      return items.whereType<Map<String, dynamic>>().map(ServiceItem.fromJson).toList(growable: false);
    });
  }

  Future<ApiResult<Booking>> getBookingById(String bookingId) async {
    return ApiResult.guard(() async {
      final response = await _dioClient.get('/api/bookings/$bookingId');
      final bookingJson = response is Map<String, dynamic>
          ? (response['booking'] as Map<String, dynamic>?) ?? response
          : <String, dynamic>{};
      return Booking.fromJson(bookingJson);
    });
  }

  Future<ApiResult<void>> cancelBooking(String bookingId) async {
    return ApiResult.guard(() async {
      await _dioClient.patch('/api/bookings/$bookingId/cancel');
    });
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.read(dioClientProvider));
});
