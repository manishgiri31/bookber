import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/bookber_models.dart';
import '../../../core/network/api_result.dart';

class BookingRepository {
  const BookingRepository();

  Future<ApiResult<List<Barber>>> fetchBarbers() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return ApiSuccess([
      Barber(
        id: 'b1',
        name: 'Arjun Fade',
        rating: 4.9,
        distanceKm: 0.6,
        bio: 'Precision fades, beard shaping, and fast turnaround.',
        isAvailable: true,
      ),
      Barber(
        id: 'b2',
        name: 'Nikhil Studio',
        rating: 4.8,
        distanceKm: 1.2,
        bio: 'Combo packages and premium grooming.',
        isAvailable: false,
      ),
    ]);
  }

  Future<ApiResult<List<ServiceItem>>> fetchServices(String barberId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return ApiSuccess([
      ServiceItem(
        id: 's1',
        name: 'Haircut',
        category: 'Hair',
        durationMin: 30,
        price: 250,
      ),
      ServiceItem(
        id: 's2',
        name: 'Beard Trim',
        category: 'Beard',
        durationMin: 15,
        price: 120,
      ),
      ServiceItem(
        id: 's3',
        name: 'Haircut + Beard',
        category: 'Package',
        durationMin: 45,
        price: 320,
        isCombo: true,
      ),
    ]);
  }

  Future<ApiResult<Booking>> createBooking({
    required String barberId,
    required String barberName,
    required List<ServiceItem> services,
    DateTime? scheduledAt,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final duration = services.fold<int>(
      0,
      (sum, item) => sum + item.durationMin,
    );
    return ApiSuccess(
      Booking(
        id: 'bk_${DateTime.now().millisecondsSinceEpoch}',
        barberId: barberId,
        barberName: barberName,
        serviceNames: services.map((e) => e.name).toList(),
        status: 'CONFIRMED',
        scheduledAt:
            scheduledAt ?? DateTime.now().add(const Duration(minutes: 20)),
        queuePosition: 3,
        estimatedWaitMinutes: duration + 10,
      ),
    );
  }

  Future<ApiResult<List<Booking>>> fetchHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return ApiSuccess([
      Booking(
        id: 'old_1',
        barberId: 'b1',
        barberName: 'Arjun Fade',
        serviceNames: const ['Haircut'],
        status: 'COMPLETED',
        scheduledAt: DateTime.now().subtract(const Duration(days: 2)),
        queuePosition: 0,
        estimatedWaitMinutes: 0,
      ),
    ]);
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return const BookingRepository();
});
