import 'shop_models.dart';

enum QueueStatus {
  waiting,
  ready,
  called,
  inService,
  completed,
  cancelled,
  noShow;

  static QueueStatus fromString(String? s) => switch ((s ?? '').toUpperCase()) {
        'READY' => ready,
        'CALLED' => called,
        'IN_SERVICE' => inService,
        'COMPLETED' => completed,
        'CANCELLED' => cancelled,
        'NO_SHOW' => noShow,
        _ => waiting,
      };

  String get label => switch (this) {
        waiting => 'Waiting',
        ready => 'Ready',
        called => 'Called',
        inService => 'In Service',
        completed => 'Completed',
        cancelled => 'Cancelled',
        noShow => 'No Show',
      };

  String get apiValue => switch (this) {
        waiting => 'WAITING',
        ready => 'READY',
        called => 'CALLED',
        inService => 'IN_SERVICE',
        completed => 'COMPLETED',
        cancelled => 'CANCELLED',
        noShow => 'NO_SHOW',
      };

  bool get isActive =>
      this == waiting || this == ready || this == called || this == inService;
}

class QueueEntry {
  const QueueEntry({
    required this.id,
    required this.bookingId,
    required this.shopId,
    required this.position,
    required this.status,
    required this.lane,
    this.estimatedWaitMinutes = 0,
    this.chairNumber,
    this.chairLabel,
    this.barberId,
    this.barberName,
    this.customerName,
    this.services = const [],
    this.isWalkIn = false,
  });

  final String id;
  final String bookingId;
  final String shopId;
  final int position;
  final QueueStatus status;
  final String lane;
  final int estimatedWaitMinutes;
  final int? chairNumber;
  final String? chairLabel;
  final String? barberId;
  final String? barberName;
  final String? customerName;
  final List<ServiceItem> services;
  final bool isWalkIn;

  String get serviceNames =>
      services.map((s) => s.name).join(', ');

  String get waitLabel =>
      estimatedWaitMinutes > 0 ? '~$estimatedWaitMinutes min' : 'Up next';

  factory QueueEntry.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'] as Map<String, dynamic>?;
    final barber = json['barber'] as Map<String, dynamic>? ??
        booking?['barber'] as Map<String, dynamic>?;
    final barberUser = barber?['user'] as Map<String, dynamic>?;
    final bookingUser = booking?['user'] as Map<String, dynamic>?;
    final serviceRaw = booking?['service'];
    final List<ServiceItem> services;
    if (serviceRaw is Map<String, dynamic>) {
      services = [ServiceItem.fromJson(serviceRaw)];
    } else {
      services = [];
    }

    return QueueEntry(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? booking?['id']?.toString() ?? '',
      shopId: json['shopId']?.toString() ?? '',
      position: (json['position'] as int?) ?? 0,
      status: QueueStatus.fromString(json['queueStatus']?.toString()),
      lane: json['lane']?.toString() ?? 'WALKIN',
      estimatedWaitMinutes: (json['estimatedWaitMinutes'] as int?) ?? 0,
      chairNumber: json['chairNumber'] as int?,
      chairLabel: json['chairLabel']?.toString() ??
          (json['chairNumber'] != null ? 'Chair ${json['chairNumber']}' : null),
      barberId: barber?['id']?.toString() ?? json['barberId']?.toString(),
      barberName: barberUser?['fullName']?.toString() ??
          barber?['name']?.toString(),
      customerName: bookingUser?['fullName']?.toString() ??
          booking?['notes']?.toString(),
      services: services,
      isWalkIn: (booking?['walkIn'] as bool?) ?? false,
    );
  }
}

class MyQueuePosition {
  const MyQueuePosition({
    required this.bookingId,
    required this.position,
    required this.estimatedWaitMinutes,
    required this.status,
    required this.shopId,
    required this.shopName,
    this.chairLabel,
    this.barberName,
    this.serviceNames = '',
  });

  final String bookingId;
  final int position;
  final int estimatedWaitMinutes;
  final String status;
  final String shopId;
  final String shopName;
  final String? chairLabel;
  final String? barberName;
  final String serviceNames;

  bool get isActive =>
      ['QUEUED', 'WAITING', 'READY', 'CALLED', 'IN_SERVICE'].contains(status.toUpperCase());

  factory MyQueuePosition.fromBooking(Map<String, dynamic> json) {
    final shop = json['shop'] as Map<String, dynamic>?;
    final queueEntry = json['queueEntry'] as Map<String, dynamic>?;
    final barber = json['barber'] as Map<String, dynamic>?;
    final barberUser = barber?['user'] as Map<String, dynamic>?;
    final serviceRaw = json['service'];
    final services = serviceRaw is Map<String, dynamic>
        ? [ServiceItem.fromJson(serviceRaw)]
        : <ServiceItem>[];

    return MyQueuePosition(
      bookingId: json['id']?.toString() ?? '',
      position: (queueEntry?['position'] as int?) ?? 0,
      estimatedWaitMinutes:
          (queueEntry?['estimatedWaitMinutes'] as int?) ?? 0,
      status: queueEntry?['queueStatus']?.toString() ??
          json['status']?.toString() ??
          'UNKNOWN',
      shopId: shop?['id']?.toString() ?? json['shopId']?.toString() ?? '',
      shopName: shop?['name']?.toString() ?? '',
      chairLabel: queueEntry?['chairLabel']?.toString(),
      barberName: barberUser?['fullName']?.toString() ??
          barber?['name']?.toString(),
      serviceNames: services.map((s) => s.name).join(', '),
    );
  }
}
