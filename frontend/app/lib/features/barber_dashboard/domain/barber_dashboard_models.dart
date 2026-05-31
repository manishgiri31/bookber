class QueueCustomer {
  QueueCustomer({
    required this.id,
    required this.name,
    required this.status,
    required this.waitMinutes,
    required this.position,
    required this.serviceName,
    required this.walkIn,
  });

  final String id;
  final String name;
  final String status;
  final int waitMinutes;
  final int position;
  final String serviceName;
  final bool walkIn;
}

class ChairModel {
  ChairModel({
    required this.id,
    required this.label,
    required this.status,
    required this.currentCustomer,
  });

  final String id;
  final String label;
  final String status;
  final String? currentCustomer;
}

class EarningsSummary {
  EarningsSummary({
    required this.today,
    required this.week,
    required this.month,
    required this.completedBookings,
  });

  final double today;
  final double week;
  final double month;
  final int completedBookings;
}

class BarberDashboardState {
  BarberDashboardState({
    required this.queue,
    required this.chairs,
    required this.earnings,
    required this.isAvailable,
    required this.activeServices,
    required this.walkInCount,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<QueueCustomer> queue;
  final List<ChairModel> chairs;
  final EarningsSummary earnings;
  final bool isAvailable;
  final List<String> activeServices;
  final int walkInCount;
  final bool isLoading;
  final String? errorMessage;

  BarberDashboardState copyWith({
    List<QueueCustomer>? queue,
    List<ChairModel>? chairs,
    EarningsSummary? earnings,
    bool? isAvailable,
    List<String>? activeServices,
    int? walkInCount,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BarberDashboardState(
      queue: queue ?? this.queue,
      chairs: chairs ?? this.chairs,
      earnings: earnings ?? this.earnings,
      isAvailable: isAvailable ?? this.isAvailable,
      activeServices: activeServices ?? this.activeServices,
      walkInCount: walkInCount ?? this.walkInCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  factory BarberDashboardState.initial() {
    return BarberDashboardState(
      queue: const [],
      chairs: const [],
      earnings: EarningsSummary(today: 0, week: 0, month: 0, completedBookings: 0),
      isAvailable: true,
      activeServices: const [],
      walkInCount: 0,
    );
  }
}
