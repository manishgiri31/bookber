import 'shop_models.dart';

class Booking {
  const Booking({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.status,
    required this.isWalkIn,
    this.barberId,
    this.barberName,
    this.services = const [],
    this.scheduledAt,
    this.queuePosition,
    this.estimatedWaitMinutes,
    this.chairLabel,
    this.bookingReference,
    this.totalAmount = 0.0,
    this.finalAmount = 0.0,
    this.notes,
    this.hasReview = false,
  });

  final String id;
  final String shopId;
  final String shopName;
  final String status;
  final bool isWalkIn;
  final String? barberId;
  final String? barberName;
  final List<ServiceItem> services;
  final DateTime? scheduledAt;
  final int? queuePosition;
  final int? estimatedWaitMinutes;
  final String? chairLabel;
  final String? bookingReference;
  final double totalAmount;
  final double finalAmount;
  final String? notes;
  final bool hasReview;

  bool get isActive => ['QUEUED', 'READY', 'CALLED', 'IN_SERVICE'].contains(status);
  String get serviceNames =>
      services.map((s) => s.name).join(', ');

  factory Booking.fromJson(Map<String, dynamic> json) {
    final shop = json['shop'] as Map<String, dynamic>?;
    final barber = json['barber'] as Map<String, dynamic>?;
    final barberUser = barber?['user'] as Map<String, dynamic>?;
    final serviceRaw = json['service'];
    final List<ServiceItem> services;
    if (serviceRaw is Map<String, dynamic>) {
      services = [ServiceItem.fromJson(serviceRaw)];
    } else if (json['services'] is List) {
      services = (json['services'] as List)
          .whereType<Map<String, dynamic>>()
          .map(ServiceItem.fromJson)
          .toList();
    } else {
      services = [];
    }

    return Booking(
      id: json['id']?.toString() ?? '',
      shopId: json['shopId']?.toString() ?? shop?['id']?.toString() ?? '',
      shopName: shop?['name']?.toString() ?? json['shopName']?.toString() ?? '',
      status: json['status']?.toString() ?? 'UNKNOWN',
      isWalkIn: (json['walkIn'] as bool?) ?? (json['isWalkIn'] as bool?) ?? false,
      barberId: barber?['id']?.toString() ?? json['barberId']?.toString(),
      barberName: barberUser?['fullName']?.toString() ??
          barber?['name']?.toString() ??
          json['barberName']?.toString(),
      services: services,
      scheduledAt: DateTime.tryParse(
        json['arrivalWindowStart']?.toString() ??
            json['scheduledAt']?.toString() ??
            '',
      ),
      queuePosition: json['queuePosition'] as int?,
      estimatedWaitMinutes: json['estimatedWaitMinutes'] as int?,
      chairLabel: json['chairLabel']?.toString(),
      bookingReference: json['id']?.toString(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes']?.toString(),
      hasReview: json['review'] != null,
    );
  }
}

class BookingCreateRequest {
  const BookingCreateRequest({
    required this.shopId,
    required this.serviceIds,
    this.barberId,
    this.scheduledAt,
    this.notes,
    this.walkIn = false,
  });

  final String shopId;
  final List<String> serviceIds;
  final String? barberId;
  final DateTime? scheduledAt;
  final String? notes;
  final bool walkIn;

  Map<String, dynamic> toJson() => {
        'shopId': shopId,
        'serviceIds': serviceIds,
        if (barberId != null) 'barberId': barberId,
        if (scheduledAt != null)
          'scheduledAt': scheduledAt!.toIso8601String(),
        if (notes != null) 'notes': notes,
        'walkIn': walkIn,
      };
}
