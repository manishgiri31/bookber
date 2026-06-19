import 'dart:math' as math;

// ── Service ────────────────────────────────────────────────────

class ShopService {
  const ShopService({
    required this.id,
    required this.shopId,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.description,
    this.isActive = true,
  });

  final String id;
  final String shopId;
  final String name;
  final double price;
  final int durationMinutes;
  final String? description;
  final bool isActive;

  String get priceLabel => '₹${price.toStringAsFixed(0)}';
  String get durationLabel => '${durationMinutes}m';

  factory ShopService.fromJson(Map<String, dynamic> j) => ShopService(
        id: j['id']?.toString() ?? '',
        shopId: j['shopId']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        price: (j['price'] as num?)?.toDouble() ?? 0,
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 30,
        description: j['description']?.toString(),
        isActive: j['isActive'] as bool? ?? true,
      );
}

// ── Chair ──────────────────────────────────────────────────────

class ShopChair {
  const ShopChair({
    required this.id,
    required this.shopId,
    required this.number,
    required this.status,
  });

  final String id;
  final String shopId;
  final int number;
  final String status; // AVAILABLE | OCCUPIED | CLEANING | BLOCKED

  bool get isAvailable => status == 'AVAILABLE';

  factory ShopChair.fromJson(Map<String, dynamic> j) => ShopChair(
        id: j['id']?.toString() ?? '',
        shopId: j['shopId']?.toString() ?? '',
        number: (j['number'] as num?)?.toInt() ?? 0,
        status: j['status']?.toString() ?? 'AVAILABLE',
      );
}

// ── Shop Summary (list card) ────────────────────────────────────

class ShopSummary {
  const ShopSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.isActive,
    this.description,
    this.openingTime,
    this.closingTime,
    this.latitude,
    this.longitude,
    this.rating = 0.0,
    this.reviewCount,
    this.imageUrl,
    this.waitTimeMinutes,
    this.distanceKm,
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final bool isActive;
  final String? description;
  final String? openingTime;
  final String? closingTime;
  final double? latitude;
  final double? longitude;
  final double rating;
  final int? reviewCount;
  final String? imageUrl;
  final int? waitTimeMinutes;
  final double? distanceKm;

  bool get isOpen => isActive;
  String get subtitle => city;
  int? get waitMinutes => (waitTimeMinutes != null && waitTimeMinutes! > 0) ? waitTimeMinutes : null;
  String get distanceLabel => distanceKm != null ? '${distanceKm!.toStringAsFixed(1)} km' : '';
  String get waitTimeLabel => waitTimeMinutes != null && waitTimeMinutes! > 0 ? '~$waitTimeMinutes min' : 'No wait';

  double? distanceTo(double? userLat, double? userLng) {
    if (latitude == null || longitude == null || userLat == null || userLng == null) {
      return null;
    }
    const R = 6371.0;
    final dLat = _deg2rad(latitude! - userLat);
    final dLon = _deg2rad(longitude! - userLng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(userLat)) *
            math.cos(_deg2rad(latitude!)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _deg2rad(double deg) => deg * (math.pi / 180);

  factory ShopSummary.fromJson(Map<String, dynamic> j) => ShopSummary(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        address: j['address']?.toString() ?? '',
        city: j['city']?.toString() ?? '',
        isActive: j['isActive'] as bool? ?? false,
        description: j['description']?.toString(),
        openingTime: j['openingTime']?.toString(),
        closingTime: j['closingTime']?.toString(),
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (j['reviewCount'] as num?)?.toInt(),
        imageUrl: j['imageUrl']?.toString() ?? j['image']?.toString(),
        waitTimeMinutes: (j['waitTimeMinutes'] as num?)?.toInt(),
        distanceKm: (j['distanceKm'] as num?)?.toDouble(),
      );
}

// ── Shop Detail (full) ─────────────────────────────────────────

class ShopDetail extends ShopSummary {
  const ShopDetail({
    required super.id,
    required super.name,
    required super.address,
    required super.city,
    required super.isActive,
    super.description,
    super.openingTime,
    super.closingTime,
    super.latitude,
    super.longitude,
    required this.state,
    required this.country,
    this.services = const [],
    this.chairs = const [],
  });

  final String state;
  final String country;
  final List<ShopService> services;
  final List<ShopChair> chairs;

  int get availableChairs => chairs.where((c) => c.isAvailable).length;

  factory ShopDetail.fromJson(Map<String, dynamic> j) {
    final raw = j['shop'] is Map<String, dynamic>
        ? j['shop'] as Map<String, dynamic>
        : j;
    return ShopDetail(
      id: raw['id']?.toString() ?? '',
      name: raw['name']?.toString() ?? '',
      address: raw['address']?.toString() ?? '',
      city: raw['city']?.toString() ?? '',
      state: raw['state']?.toString() ?? '',
      country: raw['country']?.toString() ?? '',
      isActive: raw['isActive'] as bool? ?? false,
      description: raw['description']?.toString(),
      openingTime: raw['openingTime']?.toString(),
      closingTime: raw['closingTime']?.toString(),
      latitude: (raw['latitude'] as num?)?.toDouble(),
      longitude: (raw['longitude'] as num?)?.toDouble(),
      services: (raw['services'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ShopService.fromJson)
              .toList() ??
          [],
      chairs: (raw['chairs'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ShopChair.fromJson)
              .toList() ??
          [],
    );
  }
}

// ── Paginated result ───────────────────────────────────────────

class ShopPage {
  const ShopPage({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final List<ShopSummary> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory ShopPage.fromJson(Map<String, dynamic> j) {
    final list = j['data'] is List
        ? (j['data'] as List).whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
    return ShopPage(
      data: list.map(ShopSummary.fromJson).toList(),
      total: (j['total'] as num?)?.toInt() ?? 0,
      page: (j['page'] as num?)?.toInt() ?? 1,
      limit: (j['limit'] as num?)?.toInt() ?? 20,
      totalPages: (j['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
