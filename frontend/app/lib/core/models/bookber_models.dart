class Barber {
  Barber({
    required this.id,
    required this.name,
    required this.rating,
    required this.distanceKm,
    required this.bio,
    required this.isAvailable,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final double rating;
  final double distanceKm;
  final String bio;
  final bool isAvailable;
  final String? avatarUrl;
  String get userId => id;
  String? get profilePhoto => avatarUrl;
  List<String> get specializations => bio.isEmpty ? const <String>[] : <String>[bio];
  String? get nextAvailableTime => null;

  factory Barber.fromJson(Map<String, dynamic> json) {
    return Barber(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      rating: (json['rating'] is num ? (json['rating'] as num).toDouble() : 0.0),
      distanceKm: (json['distanceKm'] is num
          ? (json['distanceKm'] as num).toDouble()
          : (json['distance'] is String
              ? double.tryParse(json['distance'].replaceAll(RegExp('[^0-9.]'), '')) ?? 0.0
              : 0.0)),
      bio: json['bio']?.toString() ?? '',
      isAvailable: json['isAvailable'] is bool
          ? json['isAvailable'] as bool
          : (json['available'] is bool ? json['available'] as bool : true),
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar']?.toString(),
    );
  }
}

class ServiceItem {
  ServiceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.durationMin,
    required this.price,
    this.isCombo = false,
  });

  final String id;
  final String name;
  final String category;
  final int durationMin;
  final double price;
  final bool isCombo;
  int get durationMinutes => durationMin;
  int get duration => durationMin;

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      durationMin: json['durationMin'] is int
          ? json['durationMin'] as int
          : int.tryParse(json['duration']?.toString() ?? '') ?? 0,
      price: (json['price'] is num ? (json['price'] as num).toDouble() : 0.0),
      isCombo: json['isCombo'] is bool ? json['isCombo'] as bool : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'durationMin': durationMin,
      'price': price,
      'isCombo': isCombo,
    };
  }
}

class Shop {
  Shop({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.waitTimeMinutes,
    required this.availableChairs,
    required this.address,
    required this.isOpen,
    this.imageUrl,
  });

  final String id;
  final String name;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final int waitTimeMinutes;
  final int availableChairs;
  final String address;
  final bool isOpen;
  final String? imageUrl;
  String get city => '';
  double get latitude => 0;
  double get longitude => 0;
  int get currentWaitMinutes => waitTimeMinutes;
  int get totalChairs => availableChairs;
  bool get isBookberVerified => false;
  List<String> get photos => imageUrl == null ? const <String>[] : <String>[imageUrl!];
  Map<String, String> get operatingHours => const <String, String>{};

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km';
  String get waitTimeLabel => '~$waitTimeMinutes min wait';

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      rating: (json['rating'] is num ? (json['rating'] as num).toDouble() : 0.0),
      reviewCount: json['reviewCount'] is int
          ? json['reviewCount'] as int
          : int.tryParse(json['reviews']?.toString() ?? '') ?? 0,
      distanceKm: (json['distanceKm'] is num
          ? (json['distanceKm'] as num).toDouble()
          : (json['distance'] is String
              ? double.tryParse(json['distance'].replaceAll(RegExp('[^0-9.]'), '')) ?? 0.0
              : 0.0)),
      waitTimeMinutes: json['waitTimeMinutes'] is int
          ? json['waitTimeMinutes'] as int
          : int.tryParse((json['waitTime']?.toString() ?? '').replaceAll(RegExp('[^0-9]'), '')) ?? 0,
      availableChairs: json['availableChairs'] is int
          ? json['availableChairs'] as int
          : int.tryParse(json['availableChairs']?.toString() ?? '') ?? 0,
      address: json['address']?.toString() ?? json['location']?.toString() ?? '',
      isOpen: json['isOpen'] is bool
          ? json['isOpen'] as bool
          : (json['open'] is bool ? json['open'] as bool : true),
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
    );
  }
}

class ShopFilters {
  const ShopFilters({
    this.maxDistance = 10.0,
    this.minRating = 0,
    this.openNow = false,
    this.sortBy = 'Distance',
    this.services = const <String>{},
  });

  final double maxDistance;
  final int minRating;
  final bool openNow;
  final String sortBy;
  final Set<String> services;

  ShopFilters copyWith({
    double? maxDistance,
    int? minRating,
    bool? openNow,
    String? sortBy,
    Set<String>? services,
  }) {
    return ShopFilters(
      maxDistance: maxDistance ?? this.maxDistance,
      minRating: minRating ?? this.minRating,
      openNow: openNow ?? this.openNow,
      sortBy: sortBy ?? this.sortBy,
      services: services ?? this.services,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'radius': maxDistance,
      'minRating': minRating,
      'sortBy': sortBy.toLowerCase().replaceAll(' ', '_'),
    };
    if (openNow) {
      params['openNow'] = true;
    }
    if (services.isNotEmpty) {
      params['services'] = services.join(',');
    }
    return params;
  }
}

typedef ShopService = ServiceItem;
typedef Service = ServiceItem;

class TimeSlot {
  TimeSlot({
    DateTime? startTime,
    String? time,
    this.durationMin = 0,
    required this.isAvailable,
    this.isNextAvailable = false,
  }) : startTime = startTime ?? _parseDisplayTime(time);

  final DateTime startTime;
  final int durationMin;
  final bool isAvailable;
  final bool isNextAvailable;
  DateTime get endTime => startTime.add(Duration(minutes: durationMin));
  String get time => label;

  String get label {
    final hour = startTime.hour % 12 == 0 ? 12 : startTime.hour % 12;
    final minute = startTime.minute.toString().padLeft(2, '0');
    final period = startTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static DateTime _parseDisplayTime(String? value) {
    if (value == null || value.isEmpty) return DateTime.now();
    final parsedIso = DateTime.tryParse(value);
    if (parsedIso != null) return parsedIso;
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$', caseSensitive: false).firstMatch(value);
    if (match == null) return DateTime.now();
    var hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '') ?? 0;
    final period = match.group(3)?.toUpperCase();
    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    final dateString = json['startTime']?.toString() ?? json['time']?.toString() ?? '';
    return TimeSlot(
      startTime: DateTime.tryParse(dateString) ?? DateTime.now(),
      durationMin: json['durationMin'] is int
          ? json['durationMin'] as int
          : int.tryParse(json['duration']?.toString() ?? '') ?? 0,
      isAvailable: json['isAvailable'] is bool ? json['isAvailable'] as bool : true,
      isNextAvailable: json['isNextAvailable'] is bool ? json['isNextAvailable'] as bool : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'durationMin': durationMin,
      'isAvailable': isAvailable,
      'isNextAvailable': isNextAvailable,
    };
  }
}

class Booking {
  Booking({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.barberId,
    required this.barberName,
    required this.services,
    required this.status,
    required this.scheduledAt,
    required this.queuePosition,
    required this.estimatedWaitMinutes,
    required this.paymentMethod,
    required this.isQueueMode,
    required this.bookingReference,
    this.totalAmount = 0.0,
    this.discountAmount = 0.0,
    this.finalAmount = 0.0,
    this.chairLabel,
  });

  final String id;
  final String shopId;
  final String shopName;
  final String barberId;
  final String barberName;
  final List<ServiceItem> services;
  final String status;
  final DateTime? scheduledAt;
  final int queuePosition;
  final int estimatedWaitMinutes;
  final String paymentMethod;
  final bool isQueueMode;
  final String bookingReference;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String? chairLabel;
  String get customerId => '';
  String get customerName => bookingReference;
  List<String> get serviceIds => services.map((service) => service.id).toList(growable: false);
  DateTime get createdAt => scheduledAt ?? DateTime.now();
  String get serviceName => services.isNotEmpty ? services.first.name : '';
  List<String> get serviceNames => services.map((service) => service.name).toList(growable: false);

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id']?.toString() ?? json['bookingId']?.toString() ?? '',
      shopId: json['shopId']?.toString() ?? json['shop_id']?.toString() ?? '',
      shopName: json['shopName']?.toString() ?? json['shop_name']?.toString() ?? '',
      barberId: json['barberId']?.toString() ?? json['barber_id']?.toString() ?? '',
      barberName: json['barberName']?.toString() ?? json['barber_name']?.toString() ?? '',
      services: json['services'] is List
          ? (json['services'] as List)
              .whereType<Map<String, dynamic>>()
              .map(ServiceItem.fromJson)
              .toList()
          : const [],
      status: json['status']?.toString() ?? 'UNKNOWN',
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'].toString())
          : null,
      queuePosition: json['queuePosition'] is int
          ? json['queuePosition'] as int
          : int.tryParse(json['queue_position']?.toString() ?? '') ?? 0,
      estimatedWaitMinutes: json['estimatedWaitMinutes'] is int
          ? json['estimatedWaitMinutes'] as int
          : int.tryParse(json['estimated_wait_minutes']?.toString() ?? '') ?? 0,
      paymentMethod: json['paymentMethod']?.toString() ?? json['payment_method']?.toString() ?? 'pay_at_shop',
      isQueueMode: json['isQueueMode'] is bool
          ? json['isQueueMode'] as bool
          : (json['mode']?.toString().toLowerCase() == 'queue'),
      bookingReference: json['bookingReference']?.toString() ?? json['reference']?.toString() ?? json['id']?.toString() ?? '',
      totalAmount: json['totalAmount'] is num
          ? (json['totalAmount'] as num).toDouble()
          : double.tryParse((json['totalAmount'] ?? json['total_amount'] ?? json['amount'])?.toString() ?? '') ?? 0.0,
      discountAmount: json['discountAmount'] is num
          ? (json['discountAmount'] as num).toDouble()
          : double.tryParse((json['discountAmount'] ?? json['discount_amount'])?.toString() ?? '') ?? 0.0,
      finalAmount: json['finalAmount'] is num
          ? (json['finalAmount'] as num).toDouble()
          : double.tryParse((json['finalAmount'] ?? json['final_amount'])?.toString() ?? '') ?? 0.0,
      chairLabel: json['chairLabel']?.toString() ?? json['chair_label']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'barberId': barberId,
      'services': services.map((item) => item.toJson()).toList(),
      'status': status,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'queuePosition': queuePosition,
      'estimatedWaitMinutes': estimatedWaitMinutes,
      'paymentMethod': paymentMethod,
      'isQueueMode': isQueueMode,
      'bookingReference': bookingReference,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'finalAmount': finalAmount,
      'chairLabel': chairLabel,
    };
  }
}

class BookingFormState {
  const BookingFormState({
    this.shopId = '',
    this.shopName = '',
    this.selectedServices = const <ShopService>[],
    this.selectedBarberId,
    this.anyBarber = false,
    this.selectedDate,
    this.selectedSlot,
    this.paymentMethod = 'pay_at_shop',
    this.currentStep = 1,
    this.totalSteps = 4,
    this.isJoinQueue = false,
  });

  final String shopId;
  final String shopName;
  final List<ShopService> selectedServices;
  final String? selectedBarberId;
  final bool anyBarber;
  final DateTime? selectedDate;
  final TimeSlot? selectedSlot;
  final String paymentMethod;
  final int currentStep;
  final int totalSteps;
  final bool isJoinQueue;

  BookingFormState copyWith({
    String? shopId,
    String? shopName,
    List<ShopService>? selectedServices,
    String? selectedBarberId,
    bool? anyBarber,
    DateTime? selectedDate,
    TimeSlot? selectedSlot,
    String? paymentMethod,
    int? currentStep,
    int? totalSteps,
    bool? isJoinQueue,
  }) {
    return BookingFormState(
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      selectedServices: selectedServices ?? this.selectedServices,
      selectedBarberId: selectedBarberId ?? this.selectedBarberId,
      anyBarber: anyBarber ?? this.anyBarber,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedSlot: selectedSlot ?? this.selectedSlot,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      isJoinQueue: isJoinQueue ?? this.isJoinQueue,
    );
  }

  int get totalDuration {
    return selectedServices.fold<int>(0, (sum, item) => sum + item.durationMin);
  }

  double get totalAmount {
    return selectedServices.fold<double>(0, (sum, item) => sum + item.price);
  }

  double get discountAmount {
    // Placeholder discount logic for loyalty or promotions.
    return selectedServices.isEmpty ? 0.0 : selectedServices.length > 1 ? 50.0 : 0.0;
  }

  List<String> get selectedServiceIds => selectedServices.map((service) => service.id).toList();
  TimeSlot? get selectedTimeSlot => selectedSlot;
  double get totalPrice => totalAmount - discountAmount;
  bool get isQueueMode => isJoinQueue;
}

class QueueEntry {
  QueueEntry({
    required this.shopId,
    required this.bookingId,
    required this.position,
    required this.etaMinutes,
    required this.status,
    required this.estimatedTotal,
    this.chairAssignment,
    this.barberName,
    this.serviceName,
    this.customerName,
    this.isWalkIn = false,
    this.waitTime,
  });

  final String shopId;
  final String bookingId;
  final int position;
  final int etaMinutes;
  final QueueStatus status;
  final int estimatedTotal;
  final ChairAssignment? chairAssignment;
  final String? barberName;
  final String? serviceName;
  final String? customerName;
  final bool isWalkIn;
  final String? waitTime;
  String get id => bookingId;
  List<String> get serviceIds => serviceName == null ? const <String>[] : <String>[serviceName!];
  int get estimatedWaitMinutes => etaMinutes;
  String? get chairId => chairAssignment?.barberId;
  int? get chairNumber => chairAssignment?.chairNumber;
  String get entryType => isWalkIn ? 'walkin' : 'booked';
  String get service => serviceName ?? '';

  factory QueueEntry.fromJson(Map<String, dynamic> json) {
    return QueueEntry(
      shopId: json['shopId']?.toString() ?? json['shop_id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? json['booking_id']?.toString() ?? '',
      position: json['position'] is int
          ? json['position'] as int
          : int.tryParse(json['position']?.toString() ?? '') ?? 0,
      etaMinutes: json['etaMinutes'] is int
          ? json['etaMinutes'] as int
          : int.tryParse(json['eta_minutes']?.toString() ?? '') ?? 0,
      status: QueueStatus.values.firstWhere(
        (value) => value.name.toLowerCase() == json['status']?.toString().toLowerCase(),
        orElse: () => QueueStatus.waiting,
      ),
      estimatedTotal: json['estimatedTotal'] is int
          ? json['estimatedTotal'] as int
          : int.tryParse(json['estimated_total']?.toString() ?? '') ?? 0,
      chairAssignment: json['chairAssignment'] is Map<String, dynamic>
          ? ChairAssignment.fromJson(json['chairAssignment'] as Map<String, dynamic>)
          : json['chair_assignment'] is Map<String, dynamic>
              ? ChairAssignment.fromJson(json['chair_assignment'] as Map<String, dynamic>)
              : null,
      barberName: json['barberName']?.toString() ?? json['barber_name']?.toString(),
      serviceName: json['serviceName']?.toString() ?? json['service_name']?.toString(),
      customerName: json['customerName']?.toString() ?? json['customer_name']?.toString() ?? json['customer']?.toString(),
      isWalkIn: json['isWalkIn'] is bool ? json['isWalkIn'] as bool : (json['walkIn'] is bool ? json['walkIn'] as bool : false),
      waitTime: json['waitTime']?.toString() ?? json['wait_time']?.toString(),
    );
  }
}

class BarberStats {
  BarberStats({
    required this.todayBookings,
    required this.inQueueCount,
    required this.todayRevenue,
    required this.avgRating,
  });

  final int todayBookings;
  final int inQueueCount;
  final double todayRevenue;
  final double avgRating;
  int get inQueue => inQueueCount;
  bool get isAvailable => true;

  factory BarberStats.fromJson(Map<String, dynamic> json) {
    return BarberStats(
      todayBookings: json['todayBookings'] is int
          ? json['todayBookings'] as int
          : int.tryParse(json['today_bookings']?.toString() ?? '') ?? 0,
      inQueueCount: json['inQueueCount'] is int
          ? json['inQueueCount'] as int
          : int.tryParse(json['in_queue_count']?.toString() ?? '') ?? 0,
      todayRevenue: json['todayRevenue'] is num
          ? (json['todayRevenue'] as num).toDouble()
          : double.tryParse(json['today_revenue']?.toString() ?? '') ?? 0.0,
      avgRating: json['avgRating'] is num
          ? (json['avgRating'] as num).toDouble()
          : double.tryParse(json['avg_rating']?.toString() ?? '') ?? 0.0,
    );
  }
}

class BarberQueueEntry extends QueueEntry {
  BarberQueueEntry({
    required super.shopId,
    required super.bookingId,
    required super.position,
    required super.etaMinutes,
    required super.status,
    required super.estimatedTotal,
    super.chairAssignment,
    super.barberName,
    super.serviceName,
    super.customerName,
    super.isWalkIn,
    super.waitTime,
    this.customerPhone,
  });

  final String? customerPhone;

  factory BarberQueueEntry.fromJson(Map<String, dynamic> json) {
    final base = QueueEntry.fromJson(json);
    return BarberQueueEntry(
      shopId: base.shopId,
      bookingId: base.bookingId,
      position: base.position,
      etaMinutes: base.etaMinutes,
      status: base.status,
      estimatedTotal: base.estimatedTotal,
      chairAssignment: base.chairAssignment,
      barberName: base.barberName,
      serviceName: base.serviceName,
      customerName: base.customerName,
      isWalkIn: base.isWalkIn,
      waitTime: base.waitTime,
      customerPhone: json['customerPhone']?.toString() ?? json['phone']?.toString(),
    );
  }
}

class WorkingHour {
  WorkingHour({
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  final String day;
  final String startTime;
  final String endTime;
  final bool isActive;

  factory WorkingHour.fromJson(Map<String, dynamic> json) {
    return WorkingHour(
      day: json['day']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? json['start_time']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? json['end_time']?.toString() ?? '',
      isActive: json['isActive'] is bool ? json['isActive'] as bool : (json['active'] is bool ? json['active'] as bool : true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'isActive': isActive,
    };
  }
}

enum QueueStatus {
  waiting,
  next,
  inService,
  completed,
}

enum ChairStatusType { available, inService, onBreak, reserved }

class ChairStatus {
  ChairStatus({
    required this.id,
    required this.chairNumber,
    required this.status,
    this.customerName,
    this.service,
    this.timeRemaining,
  });

  final String id;
  final int chairNumber;
  final ChairStatusType status;
  final String? customerName;
  final String? service;
  final int? timeRemaining;

  factory ChairStatus.fromJson(Map<String, dynamic> json) {
    return ChairStatus(
      id: json['id']?.toString() ?? json['chairId']?.toString() ?? '',
      chairNumber: json['chairNumber'] is int
          ? json['chairNumber'] as int
          : int.tryParse((json['number'] ?? json['chairNumber'])?.toString() ?? '') ?? 0,
      status: _chairStatusFromJson(json['status']?.toString()),
      customerName: json['customerName']?.toString() ?? json['currentCustomerName']?.toString(),
      service: json['service']?.toString(),
      timeRemaining: json['timeRemaining'] is int
          ? json['timeRemaining'] as int
          : int.tryParse((json['remainingMinutes'] ?? json['timeRemaining'])?.toString() ?? ''),
    );
  }

  static ChairStatusType _chairStatusFromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'in_service':
      case 'inservice':
        return ChairStatusType.inService;
      case 'reserved':
        return ChairStatusType.reserved;
      case 'on_break':
      case 'onbreak':
        return ChairStatusType.onBreak;
      default:
        return ChairStatusType.available;
    }
  }
}

class ChairAssignment {
  ChairAssignment({
    required this.chairNumber,
    required this.assignedAt,
    this.barberId,
    this.barberName,
  });

  final int chairNumber;
  final DateTime assignedAt;
  final String? barberId;
  final String? barberName;

  factory ChairAssignment.fromJson(Map<String, dynamic> json) {
    return ChairAssignment(
      chairNumber: json['chairNumber'] is int
          ? json['chairNumber'] as int
          : int.tryParse(json['chair_number']?.toString() ?? '') ?? 0,
      assignedAt: json['assignedAt'] != null
          ? DateTime.tryParse(json['assignedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      barberId: json['barberId']?.toString() ?? json['barber_id']?.toString(),
      barberName: json['barberName']?.toString() ?? json['barber_name']?.toString(),
    );
  }
}

class QueueStateModel {
  QueueStateModel({
    required this.bookingId,
    required this.position,
    required this.etaMinutes,
    required this.status,
    required this.chairLabel,
  });

  final String bookingId;
  final int position;
  final int etaMinutes;
  final String status;
  final String chairLabel;
}

class AuthResponse {
  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final UserProfile user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final userData = json['user'];
    return AuthResponse(
      accessToken: json['accessToken'] as String? ?? json['access_token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? json['refresh_token'] as String? ?? '',
      user: UserProfile.fromJson(
        userData is Map<String, dynamic>
            ? userData
            : json,
      ),
    );
  }
}

class UserProfile {
  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profilePhoto,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? profilePhoto;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'customer',
      profilePhoto: json['profilePhoto']?.toString() ?? json['profile_photo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      if (profilePhoto != null) 'profilePhoto': profilePhoto,
    };
  }
}

class RegisterRequest {
  RegisterRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
  });

  final String name;
  final String email;
  final String phone;
  final String password;
  final String role;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
    };
  }
}

class Payment {
  Payment({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.discountAmount,
    required this.finalAmount,
    required this.method,
    required this.status,
    required this.transactionId,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final double amount;
  final double discountAmount;
  final double finalAmount;
  final String method;
  final String status;
  final String transactionId;
  final DateTime createdAt;

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id']?.toString() ?? json['paymentId']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? json['booking_id']?.toString() ?? '',
      amount: json['amount'] is num ? (json['amount'] as num).toDouble() : double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      discountAmount: json['discountAmount'] is num ? (json['discountAmount'] as num).toDouble() : double.tryParse((json['discountAmount'] ?? json['discount_amount'])?.toString() ?? '') ?? 0.0,
      finalAmount: json['finalAmount'] is num ? (json['finalAmount'] as num).toDouble() : double.tryParse((json['finalAmount'] ?? json['final_amount'])?.toString() ?? '') ?? 0.0,
      method: json['method']?.toString() ?? json['payment_method']?.toString() ?? '',
      status: json['status']?.toString() ?? 'unknown',
      transactionId: json['transactionId']?.toString() ?? json['transaction_id']?.toString() ?? json['txn']?.toString() ?? '',
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.tryParse((json['createdAt'] ?? json['created_at']).toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ReviewFormState {
  const ReviewFormState({
    this.bookingId = '',
    this.rating = 0,
    this.selectedTags = const <String>[],
    this.comment = '',
    this.photoUrls = const <String>[],
  });

  final String bookingId;
  final int rating;
  final List<String> selectedTags;
  final String comment;
  final List<String> photoUrls;
  List<String> get photos => photoUrls;
  List<String> get tags => selectedTags;

  ReviewFormState copyWith({
    String? bookingId,
    int? rating,
    List<String>? selectedTags,
    String? comment,
    List<String>? photoUrls,
  }) {
    return ReviewFormState(
      bookingId: bookingId ?? this.bookingId,
      rating: rating ?? this.rating,
      selectedTags: selectedTags ?? this.selectedTags,
      comment: comment ?? this.comment,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'rating': rating,
      'tags': selectedTags,
      'comment': comment,
      'photos': photoUrls,
    };
  }
}
