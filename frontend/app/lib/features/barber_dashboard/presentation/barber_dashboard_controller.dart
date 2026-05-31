import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../../../core/network/api_result.dart';
import '../../../core/realtime/socket_providers.dart';
import '../data/barber_dashboard_repository.dart';
import '../domain/barber_dashboard_models.dart';

class BarberDashboardController extends AsyncNotifier<BarberDashboardState> {
  @override
  Future<BarberDashboardState> build() async {
    final socket = ref.read(socketServiceProvider);
    await socket.connect();
    socket.subscribeToShop('demo-shop');

    ref.listen(socketEventsProvider, (_, next) {
      next.whenData((event) {
        final name = event['event'];
        if (name == 'queue.updated' || name == 'chair.allocated' || name == 'booking.updated') {
          refresh();
        }
        if (name == 'barber.delayed' || name == 'customer.checked_in') {
          refresh();
        }
      });
    });

    final result = await ref.read(barberDashboardRepositoryProvider).fetchDashboard();
    return result is ApiSuccess<BarberDashboardState>
        ? result.data
        : BarberDashboardState.initial();
  }

  Future<void> refresh() async {
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(current.copyWith(isLoading: true));
    } else {
      state = const AsyncLoading();
    }

    final result = await ref.read(barberDashboardRepositoryProvider).fetchDashboard();
    state = AsyncData(
      result is ApiSuccess<BarberDashboardState>
          ? result.data
          : BarberDashboardState.initial(),
    );
  }

  Future<void> toggleAvailability() async {
    final current = state.asData?.value ?? BarberDashboardState.initial();
    final updated = !current.isAvailable;
    state = AsyncData(current.copyWith(isAvailable: updated));
    try {
      await ref.read(barberDashboardRepositoryProvider).setAvailability(updated);
    } catch (_) {
      state = AsyncData(current);
    }
  }

  Future<void> setChairStatus(String chairId, String status) async {
    final current = state.asData?.value ?? BarberDashboardState.initial();
    final chairs = current.chairs
        .map(
          (chair) => chair.id == chairId
              ? ChairModel(
                  id: chair.id,
                  label: chair.label,
                  status: status,
                  currentCustomer: chair.currentCustomer,
                )
              : chair,
        )
        .toList();
    state = AsyncData(current.copyWith(chairs: chairs));

    try {
      await ref.read(barberDashboardRepositoryProvider).updateChairStatus(chairId, status);
    } catch (_) {
      state = AsyncData(current);
    }
  }

  Future<void> acceptWalkIn() async {
    final current = state.asData?.value ?? BarberDashboardState.initial();
    state = AsyncData(current.copyWith(walkInCount: current.walkInCount + 1));
    await ref.read(barberDashboardRepositoryProvider).acceptWalkIn();
  }

  Future<void> markReady(String queueId) async {
    await ref.read(barberDashboardRepositoryProvider).markBookingReady(queueId);
    await refresh();
  }

  Future<void> markStarted(String queueId) async {
    await ref.read(barberDashboardRepositoryProvider).markBookingStarted(queueId);
    await refresh();
  }
}

final barberDashboardControllerProvider =
    AsyncNotifierProvider<BarberDashboardController, BarberDashboardState>(
  BarberDashboardController.new,
);
