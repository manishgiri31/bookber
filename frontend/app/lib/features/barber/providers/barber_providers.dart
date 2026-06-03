import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/realtime/socket_providers.dart';
import '../../../core/models/bookber_models.dart';
import '../../../core/network/api_result.dart';
import '../../barber_dashboard/data/barber_dashboard_repository.dart';

// 1. myBarberProfileProvider
final myBarberProfileProvider = FutureProvider<Barber>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get('/api/barbers/me');
  final json = response is Map<String, dynamic> ? response : <String, dynamic>{};
  return Barber.fromJson(json);
});

// 2. barberStatsProvider - refresh every 60s via keepAlive
final FutureProvider<BarberStats> barberStatsProvider = FutureProvider<BarberStats>((ref) async {
  final user = ref.read(currentUserProvider);
  final barberId = user?.id ?? '';

  final link = ref.keepAlive();
  Timer? timer;
  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 60), (_) {
      // invalidate to refetch
      ref.invalidate(barberStatsProvider);
    });
  }

  startTimer();
  ref.onDispose(() {
    timer?.cancel();
    link.close();
  });

  if (barberId.isEmpty) throw Exception('No barber id');
  final result = await ref.read(barberDashboardRepositoryProvider).getStats(barberId);
  return result is ApiSuccess<BarberStats> ? result.data : BarberStats.fromJson({});
});

// 3. barberQueueProvider - stream from socket, fallback to polling every 20s
final barberQueueProvider = StreamProvider<List<QueueEntry>>((ref) {
  final controller = StreamController<List<QueueEntry>>.broadcast();
  final socket = ref.read(socketServiceProvider);
  final repo = ref.read(barberDashboardRepositoryProvider);
  final user = ref.read(currentUserProvider);
  final barberId = user?.id ?? '';

  // socket listener
  final sub = socket.events.listen((event) async {
    final name = event['event']?.toString() ?? '';
    if (name == 'queue.updated') {
      final data = event['data'];
      if (data is Map<String, dynamic>) {
        // Attempt to parse queue array
        final items = (data['queue'] as List<dynamic>?) ?? (data['entries'] as List<dynamic>?);
        if (items != null) {
          final list = items.whereType<Map<String, dynamic>>().map(QueueEntry.fromJson).toList(growable: false);
          controller.add(list);
          return;
        }
      }
      // fallback to repo
      final res = await repo.getMyQueue(barberId);
      if (res is ApiSuccess<List<QueueEntry>>) controller.add(res.data);
    }
  });

  // polling fallback
  Timer? pollTimer;
  Future<void> pollOnce() async {
    final res = await repo.getMyQueue(barberId);
    if (res is ApiSuccess<List<QueueEntry>>) controller.add(res.data);
  }

  pollOnce();
  pollTimer = Timer.periodic(const Duration(seconds: 20), (_) => pollOnce());

  ref.onDispose(() {
    sub.cancel();
    pollTimer?.cancel();
    controller.close();
  });

  return controller.stream;
});

// 4. todayBookingsProvider
final todayBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final user = ref.read(currentUserProvider);
  final barberId = user?.id ?? '';
  if (barberId.isEmpty) return const [];
  final res = await ref.read(barberDashboardRepositoryProvider).getTodayBookings(barberId);
  return res is ApiSuccess<List<Booking>> ? res.data : const <Booking>[];
});

// 5. barberStatusProvider - optimistic state notifier
class BarberStatusNotifier extends StateNotifier<bool> {
  BarberStatusNotifier(this.ref, bool initial) : super(initial);

  final Ref ref;

  Future<void> toggleStatus(String barberId) async {
    final previous = state;
    state = !state; // optimistic
    try {
      final res = await ref.read(barberDashboardRepositoryProvider).updateBarberStatus(barberId, state);
      if (res is! ApiSuccess<void>) throw Exception('Failed to update');
    } catch (e) {
      state = previous; // revert
      rethrow;
    }
  }
}

final barberStatusProvider = StateNotifierProvider<BarberStatusNotifier, bool>((ref) {
  // initial state: derive from current user or assume online
  final user = ref.read(currentUserProvider);
  final initial = true;
  return BarberStatusNotifier(ref, initial);
});

// 6. chairStatusProvider - stream of chair states from socket 'queue.updated'.
final chairStatusProvider = StreamProvider<List<ChairStatus>>((ref) {
  final controller = StreamController<List<ChairStatus>>.broadcast();
  final socket = ref.read(socketServiceProvider);

  final sub = socket.events.listen((event) {
    final name = event['event']?.toString() ?? '';
    if (name == 'queue.updated' || name == 'chair.allocated') {
      final data = event['data'];
      final chairs = (data is Map<String, dynamic>) ? (data['chairs'] as List<dynamic>?) : null;
      if (chairs != null) {
        final list = chairs.whereType<Map<String, dynamic>>().map(ChairStatus.fromJson).toList(growable: false);
        controller.add(list);
      }
    }
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

// Schedule mapping: small BookingSlot used by schedule UI
class BookingSlot {
  const BookingSlot({
    required this.id,
    required this.time,
    required this.customerName,
    required this.service,
    required this.price,
    required this.status,
    required this.duration,
  });

  final String id;
  final String time;
  final String customerName;
  final String service;
  final int price;
  final BookingStatus status;
  final int duration;
}

enum BookingStatus {
  confirmed,
  inProgress,
  completed,
  noShow,
}

// Map today's bookings into a time-grid friendly list
final barberScheduleProvider = FutureProvider.family<List<BookingSlot>, String>(
  (ref, date) async {
    final bookings = await ref.read(todayBookingsProvider.future);
    // Map bookings into slots - naive mapping: take first 12 slots and map
    final slots = List<BookingSlot>.generate(12, (index) {
      if (index < bookings.length) {
        final b = bookings[index];
        return BookingSlot(
          id: b.id,
          time: b.scheduledAt != null ? '${b.scheduledAt!.hour}:${b.scheduledAt!.minute.toString().padLeft(2, '0')}' : '${9 + index}:00',
          customerName: b.bookingReference,
          service: b.services.isNotEmpty ? b.services.first.name : (b.serviceName ?? ''),
          price: b.totalAmount.toInt(),
          status: BookingStatus.confirmed,
          duration: b.services.isNotEmpty ? b.services.first.durationMin : 30,
        );
      }
      return BookingSlot(id: 'empty_$index', time: '${9 + index}:00', customerName: '', service: '', price: 0, status: BookingStatus.confirmed, duration: 0);
    });

    return slots;
  },
);

// Working hours provider (from repo)
final workingHoursProvider = FutureProvider<List<WorkingHour>>((ref) async {
  final user = ref.read(currentUserProvider);
  final barberId = user?.id ?? '';
  if (barberId.isEmpty) return const [];
  final res = await ref.read(barberDashboardRepositoryProvider).getWorkingHours(barberId);
  return res is ApiSuccess<List<WorkingHour>> ? res.data : const <WorkingHour>[];
});
