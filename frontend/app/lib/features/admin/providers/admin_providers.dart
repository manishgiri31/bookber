import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/realtime/socket_providers.dart';

class AdminStats {
  const AdminStats({
    required this.totalUsers,
    required this.activeShops,
    required this.bookingsToday,
    required this.revenueToday,
    required this.platformCommission,
    required this.activeQueueEntries,
    required this.usersToday,
    required this.usersAllTime,
  });

  final int totalUsers;
  final int activeShops;
  final int bookingsToday;
  final int revenueToday;
  final int platformCommission;
  final int activeQueueEntries;
  final int usersToday;
  final int usersAllTime;

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: _asInt(json['totalUsers']),
      activeShops: _asInt(json['activeShops']),
      bookingsToday: _asInt(json['todayBookings'] ?? json['bookingsToday']),
      revenueToday: _asInt(json['todayRevenue'] ?? json['revenueToday']),
      platformCommission: _asInt(json['platformCommission']),
      activeQueueEntries: _asInt(json['activeQueueEntries']),
      usersToday: _asInt(json['usersToday']),
      usersAllTime: _asInt(json['usersAllTime'] ?? json['totalUsers']),
    );
  }
}

class PlatformActivity {
  const PlatformActivity({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.type,
    this.entityId,
  });

  final String id;
  final String message;
  final DateTime timestamp;
  final ActivityType type;
  final String? entityId;

  factory PlatformActivity.fromJson(Map<String, dynamic> json) {
    return PlatformActivity(
      id: json['id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      type: _activityTypeFromString(json['type']?.toString()),
      entityId: json['entityId']?.toString(),
    );
  }
}

enum ActivityType { success, warning, alert, info }

class AdminShop {
  const AdminShop({
    required this.id,
    required this.name,
    required this.city,
    required this.status,
    required this.todayBookings,
    required this.rating,
    required this.revenueToday,
  });

  final String id;
  final String name;
  final String city;
  final ShopStatus status;
  final int todayBookings;
  final double rating;
  final int revenueToday;

  factory AdminShop.fromJson(Map<String, dynamic> json) {
    return AdminShop(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      status: _shopStatusFromString(json['status']?.toString()),
      todayBookings: _asInt(json['todayBookings']),
      rating: _asDouble(json['rating']),
      revenueToday: _asInt(json['revenueToday']),
    );
  }
}

enum ShopStatus { active, inactive, pending }

class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.joinDate,
    required this.status,
    this.avatar,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime joinDate;
  final UserStatus status;
  final String? avatar;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'customer',
      joinDate: DateTime.tryParse(json['createdAt']?.toString() ?? json['joinDate']?.toString() ?? '') ?? DateTime.now(),
      status: _userStatusFromString(json['status']?.toString()),
      avatar: json['avatar']?.toString() ?? json['profilePhoto']?.toString(),
    );
  }
}

enum UserStatus { active, suspended, flagged }

class AdminBooking {
  const AdminBooking({
    required this.id,
    required this.customerName,
    required this.shopName,
    required this.service,
    required this.amount,
    required this.status,
    required this.scheduledAt,
    required this.barberName,
  });

  final String id;
  final String customerName;
  final String shopName;
  final String service;
  final int amount;
  final BookingStatus status;
  final DateTime scheduledAt;
  final String barberName;

  factory AdminBooking.fromJson(Map<String, dynamic> json) {
    final services = json['services'];
    return AdminBooking(
      id: json['id']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? json['customer']?.toString() ?? '',
      shopName: json['shopName']?.toString() ?? '',
      service: services is List && services.isNotEmpty
          ? services.first['name']?.toString() ?? ''
          : json['service']?.toString() ?? '',
      amount: _asInt(json['amount'] ?? json['totalAmount']),
      status: _bookingStatusFromString(json['status']?.toString()),
      scheduledAt: DateTime.tryParse(json['scheduledAt']?.toString() ?? '') ?? DateTime.now(),
      barberName: json['barberName']?.toString() ?? '',
    );
  }
}

enum BookingStatus { confirmed, inProgress, completed, cancelled, noShow }

class PlatformAlert {
  const PlatformAlert({
    required this.id,
    required this.type,
    required this.message,
    required this.entityId,
    required this.entityName,
  });

  final String id;
  final AlertType type;
  final String message;
  final String entityId;
  final String entityName;

  factory PlatformAlert.fromJson(Map<String, dynamic> json) {
    return PlatformAlert(
      id: json['id']?.toString() ?? '',
      type: _alertTypeFromString(json['type']?.toString()),
      message: json['message']?.toString() ?? '',
      entityId: json['entityId']?.toString() ?? '',
      entityName: json['entityName']?.toString() ?? json['entity']?.toString() ?? '',
    );
  }
}

enum AlertType { inactiveShop, longBooking, lowRatedShop }

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  ref.keepAlive();
  final timer = Timer(const Duration(seconds: 30), () => ref.invalidateSelf());
  ref.onDispose(timer.cancel);

  final response = await ref.read(dioClientProvider).get('/api/admin/stats');
  return AdminStats.fromJson(_payload(response, 'stats'));
});

final adminReportProvider = FutureProvider.family<AdminStats, String>((ref, range) async {
  final response = await ref.read(dioClientProvider).get(
        '/api/admin/stats',
        queryParams: {'range': range},
      );
  return AdminStats.fromJson(_payload(response, 'stats'));
});

final platformActivityProvider = StreamProvider<List<PlatformActivity>>((ref) {
  final controller = StreamController<List<PlatformActivity>>.broadcast();
  final socket = ref.watch(socketServiceProvider);
  final dio = ref.watch(dioClientProvider);
  Timer? pollTimer;

  Future<void> poll() async {
    final response = await dio.get('/api/admin/activity', queryParams: {'limit': 20});
    final items = _listPayload(response, 'activity');
    if (!controller.isClosed) {
      controller.add(items.whereType<Map<String, dynamic>>().map(PlatformActivity.fromJson).toList(growable: false));
    }
  }

  final sub = socket.events.listen((event) {
    if (event['event']?.toString() == 'admin:activity') {
      final data = event['data'];
      if (data is Map<String, dynamic> && !controller.isClosed) {
        controller.add([PlatformActivity.fromJson(data)]);
      }
    }
  });

  poll();
  pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => poll());
  ref.onDispose(() {
    sub.cancel();
    pollTimer?.cancel();
    controller.close();
  });
  return controller.stream;
});

final adminShopsProvider = FutureProvider<List<AdminShop>>((ref) async {
  final response = await ref.read(dioClientProvider).get('/api/admin/shops');
  return _listPayload(response, 'shops')
      .whereType<Map<String, dynamic>>()
      .map(AdminShop.fromJson)
      .toList(growable: false);
});

final adminUsersProvider = FutureProvider.family<List<AdminUser>, String>((ref, role) async {
  final normalizedRole = role == 'customers' ? 'customer' : role == 'barbers' ? 'barber' : role;
  final response = await ref.read(dioClientProvider).get(
        '/api/admin/users',
        queryParams: {'role': normalizedRole},
      );
  return _listPayload(response, 'users')
      .whereType<Map<String, dynamic>>()
      .map(AdminUser.fromJson)
      .toList(growable: false);
});

final adminBookingsProvider = FutureProvider<List<AdminBooking>>((ref) async {
  final response = await ref.read(dioClientProvider).get('/api/admin/bookings');
  return _listPayload(response, 'bookings')
      .whereType<Map<String, dynamic>>()
      .map(AdminBooking.fromJson)
      .toList(growable: false);
});

class AdminActions extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateShopStatus(String shopId, String status) async {
    state = const AsyncLoading();
    await ref.read(dioClientProvider).patch('/api/admin/shops/$shopId/status', body: {'status': status});
    ref.invalidate(adminShopsProvider);
    state = const AsyncData(null);
  }

  Future<void> updateUserStatus(String userId, String status) async {
    state = const AsyncLoading();
    await ref.read(dioClientProvider).patch('/api/admin/users/$userId/status', body: {'status': status});
    ref.invalidate(adminUsersProvider);
    state = const AsyncData(null);
  }

  Future<String> exportReport(String type, String range) async {
    final response = await ref.read(dioClientProvider).get(
          '/api/admin/export',
          queryParams: {'type': type, 'range': range},
        );
    final json = response is Map<String, dynamic> ? response : <String, dynamic>{};
    return json['url']?.toString() ?? json['fileUrl']?.toString() ?? json['downloadUrl']?.toString() ?? '';
  }
}

final adminActionsProvider = AsyncNotifierProvider<AdminActions, void>(AdminActions.new);

final platformAlertsProvider = FutureProvider<List<PlatformAlert>>((ref) async {
  final response = await ref.read(dioClientProvider).get('/api/admin/activity', queryParams: {'limit': 20});
  return _listPayload(response, 'alerts')
      .whereType<Map<String, dynamic>>()
      .map(PlatformAlert.fromJson)
      .toList(growable: false);
});

Map<String, dynamic> _payload(dynamic response, String key) {
  if (response is Map<String, dynamic>) {
    final nested = response[key];
    return nested is Map<String, dynamic> ? nested : response;
  }
  return <String, dynamic>{};
}

List<dynamic> _listPayload(dynamic response, String key) {
  if (response is List<dynamic>) return response;
  if (response is Map<String, dynamic>) {
    final nested = response[key] ?? response['data'];
    return nested is List<dynamic> ? nested : const <dynamic>[];
  }
  return const <dynamic>[];
}

int _asInt(dynamic value) => value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
double _asDouble(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;

ActivityType _activityTypeFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'success':
      return ActivityType.success;
    case 'warning':
      return ActivityType.warning;
    case 'alert':
      return ActivityType.alert;
    default:
      return ActivityType.info;
  }
}

ShopStatus _shopStatusFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'inactive':
      return ShopStatus.inactive;
    case 'pending':
      return ShopStatus.pending;
    default:
      return ShopStatus.active;
  }
}

UserStatus _userStatusFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'suspended':
      return UserStatus.suspended;
    case 'flagged':
      return UserStatus.flagged;
    default:
      return UserStatus.active;
  }
}

BookingStatus _bookingStatusFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'in_progress':
    case 'inprogress':
      return BookingStatus.inProgress;
    case 'completed':
      return BookingStatus.completed;
    case 'cancelled':
    case 'canceled':
      return BookingStatus.cancelled;
    case 'no_show':
    case 'noshow':
      return BookingStatus.noShow;
    default:
      return BookingStatus.confirmed;
  }
}

AlertType _alertTypeFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'long_booking':
    case 'longbooking':
      return AlertType.longBooking;
    case 'low_rated_shop':
    case 'lowratedshop':
      return AlertType.lowRatedShop;
    default:
      return AlertType.inactiveShop;
  }
}
