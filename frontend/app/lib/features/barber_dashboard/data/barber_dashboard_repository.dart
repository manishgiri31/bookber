import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../domain/barber_dashboard_models.dart';

class BarberDashboardRepository {
  const BarberDashboardRepository();

  Future<ApiResult<BarberDashboardState>> fetchDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return ApiSuccess(
      BarberDashboardState(
        queue: [
          QueueCustomer(
            id: 'q1',
            name: 'Aman',
            status: 'WAITING',
            waitMinutes: 12,
            position: 1,
            serviceName: 'Haircut',
            walkIn: false,
          ),
          QueueCustomer(
            id: 'q2',
            name: 'Rahul',
            status: 'APPROACHING',
            waitMinutes: 4,
            position: 2,
            serviceName: 'Beard Trim',
            walkIn: true,
          ),
        ],
        chairs: [
          ChairModel(id: 'c1', label: 'Chair 1', status: 'OCCUPIED', currentCustomer: 'Aman'),
          ChairModel(id: 'c2', label: 'Chair 2', status: 'RESERVED', currentCustomer: null),
          ChairModel(id: 'c3', label: 'Chair 3', status: 'AVAILABLE', currentCustomer: null),
        ],
        earnings: EarningsSummary(today: 4200, week: 24800, month: 98200, completedBookings: 18),
        isAvailable: true,
        activeServices: const ['Haircut', 'Beard Trim', 'Haircut + Beard'],
        walkInCount: 5,
      ),
    );
  }

  Future<void> setAvailability(bool available) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  Future<void> updateChairStatus(String chairId, String status) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  Future<void> acceptWalkIn() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  Future<void> markBookingReady(String queueId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  Future<void> markBookingStarted(String queueId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}

final barberDashboardRepositoryProvider = Provider<BarberDashboardRepository>((ref) {
  return const BarberDashboardRepository();
});
