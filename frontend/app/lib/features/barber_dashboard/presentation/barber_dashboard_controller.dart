import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/models/bookber_models.dart';
import '../../../core/network/api_result.dart';
import '../../../core/realtime/socket_providers.dart';
import '../domain/barber_dashboard_models.dart';
import '../data/barber_dashboard_repository.dart';

class BarberDashboardController extends AsyncNotifier<BarberDashboardState> {
  @override
  Future<BarberDashboardState> build() async {
    final user = ref.read(currentUserProvider);
    final barberId = user?.id ?? '';

    final socket = ref.read(socketServiceProvider);

    socket.events.listen((event) {
      final name = event['event']?.toString() ?? '';
      if (name == 'queue.updated' || name == 'chair.allocated' || name == 'booking.updated') {
        refresh();
      }
    });

    if (barberId.isEmpty) return BarberDashboardState.initial();
    return _loadState(barberId);
  }

  Future<BarberDashboardState> _loadState(String barberId) async {
    final repo = ref.read(barberDashboardRepositoryProvider);
    final result = await ref.read(barberDashboardRepositoryProvider).getStats(barberId);
    final stats = result is ApiSuccess<BarberStats> ? result.data : BarberStats.fromJson({});
    final queueResult = await repo.getMyQueue(barberId);
    final bookingsResult = await repo.getTodayBookings(barberId);
    final queue = queueResult is ApiSuccess<List<QueueEntry>>
        ? queueResult.data
        : const <QueueEntry>[];
    final bookings = bookingsResult is ApiSuccess<List<Booking>>
        ? bookingsResult.data
        : const <Booking>[];

    return BarberDashboardState(
      queue: queue.map(_queueCustomerFromEntry).toList(growable: false),
      chairs: queue
          .where((entry) => entry.chairNumber != null)
          .map(
            (entry) => ChairModel(
              id: entry.chairId ?? entry.id,
              label: 'Chair ${entry.chairNumber}',
              status: entry.status.name.toUpperCase(),
              currentCustomer: entry.customerName,
            ),
          )
          .toList(growable: false),
      earnings: EarningsSummary(
        today: stats.todayRevenue,
        week: stats.todayRevenue,
        month: stats.todayRevenue,
        completedBookings: bookings.where((booking) => booking.status.toLowerCase() == 'completed').length,
      ),
      isAvailable: stats.isAvailable,
      activeServices: bookings.expand((booking) => booking.serviceNames).toSet().toList(growable: false),
      walkInCount: queue.where((entry) => entry.entryType == 'walkin').length,
    );
  }

  QueueCustomer _queueCustomerFromEntry(QueueEntry entry) {
    return QueueCustomer(
      id: entry.id,
      name: entry.customerName ?? 'Customer',
      status: entry.status.name,
      waitMinutes: entry.estimatedWaitMinutes,
      position: entry.position,
      serviceName: entry.service,
      walkIn: entry.entryType == 'walkin',
    );
  }

  Future<void> refresh() async {
    final user = ref.read(currentUserProvider);
    final barberId = user?.id ?? '';
    state = const AsyncLoading();
    state = AsyncData(barberId.isEmpty ? BarberDashboardState.initial() : await _loadState(barberId));
  }

  Future<void> toggleAvailability() async {
    final current = state.value ?? BarberDashboardState.initial();
    final user = ref.read(currentUserProvider);
    final barberId = user?.id ?? '';
    state = AsyncData(current.copyWith(isAvailable: !current.isAvailable));
    if (barberId.isNotEmpty) {
      final result = await updateBarberStatus(barberId, !current.isAvailable);
      if (result is ApiError<void>) state = AsyncData(current);
    }
  }

  Future<void> markReady(String entryId) => updateQueueEntryStatus(entryId, 'ready');

  Future<void> markStarted(String entryId) => updateQueueEntryStatus(entryId, 'in_service');

  Future<void> setChairStatus(String chairId, String status) async {
    final current = state.value ?? BarberDashboardState.initial();
    state = AsyncData(
      current.copyWith(
        chairs: current.chairs
            .map((chair) => chair.id == chairId
                ? ChairModel(
                    id: chair.id,
                    label: chair.label,
                    status: status,
                    currentCustomer: chair.currentCustomer,
                  )
                : chair)
            .toList(growable: false),
      ),
    );
  }

  Future<void> acceptWalkIn() async {
    final user = ref.read(currentUserProvider);
    final shopId = user?.id ?? '';
    if (shopId.isNotEmpty) {
      await addWalkIn(shopId, const <String>[], null);
    }
  }

  Future<ApiResult<void>> updateQueueEntryStatus(String entryId, String status) async {
    final res = await ref.read(barberDashboardRepositoryProvider).updateQueueEntryStatus(entryId, status);
    if (res is ApiSuccess<void>) {
      await refresh();
    }
    return res;
  }

  Future<ApiResult<void>> addWalkIn(String shopId, List<String> serviceIds, String? customerName) async {
    final res = await ref.read(barberDashboardRepositoryProvider).addWalkIn(shopId, serviceIds, customerName);
    if (res is ApiSuccess<void>) await refresh();
    return res;
  }

  Future<ApiResult<void>> updateBarberStatus(String barberId, bool isOnline) async {
    final res = await ref.read(barberDashboardRepositoryProvider).updateBarberStatus(barberId, isOnline);
    if (res is ApiSuccess<void>) await refresh();
    return res;
  }

  Future<ApiResult<List<WorkingHour>>> getWorkingHours(String barberId) async {
    return await ref.read(barberDashboardRepositoryProvider).getWorkingHours(barberId);
  }

  Future<ApiResult<void>> saveWorkingHours(String barberId, List<WorkingHour> hours) async {
    final res = await ref.read(barberDashboardRepositoryProvider).saveWorkingHours(barberId, hours);
    if (res is ApiSuccess<void>) await refresh();
    return res;
  }
}

final barberDashboardControllerProvider =
    AsyncNotifierProvider<BarberDashboardController, BarberDashboardState>(
  BarberDashboardController.new,
);
