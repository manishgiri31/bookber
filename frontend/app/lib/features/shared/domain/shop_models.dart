class Shop {
  const Shop({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.rating,
    required this.reviewCount,
    required this.isOpen,
    this.waitTimeMinutes = 0,
    this.availableChairs = 0,
    this.queueLength = 0,
    this.imageUrl,
    this.distanceKm,
    this.latitude,
    this.longitude,
    this.phone,
    this.description,
    this.bookberReservedChairCount = 0,
    this.totalChairs = 0,
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final double rating;
  final int reviewCount;
  final bool isOpen;
  final int waitTimeMinutes;
  final int availableChairs;
  final int queueLength;
  final String? imageUrl;
  final double? distanceKm;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? description;
  final int bookberReservedChairCount;
  final int totalChairs;

  String get distanceLabel {
    final dist = distanceKm;
    if (dist == null) return '';
    if (dist < 1) return '${(dist * 1000).round()}m away';
    return '${dist.toStringAsFixed(1)}km away';
  }

  String get waitLabel => waitTimeMinutes > 0 ? '~$waitTimeMinutes min wait' : 'No wait';

  factory Shop.fromJson(Map<String, dynamic> json) => Shop(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (json['reviewCount'] as int?) ?? 0,
        isOpen: (json['isOpen'] as bool?) ?? true,
        waitTimeMinutes: (json['waitTimeMinutes'] as int?) ?? 0,
        availableChairs: (json['availableChairs'] as int?) ?? 0,
        queueLength: (json['queueLength'] as int?) ?? 0,
        imageUrl: json['imageUrl']?.toString(),
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        phone: json['phone']?.toString(),
        description: json['description']?.toString(),
        bookberReservedChairCount:
            (json['bookBerReservedChairCount'] as int?) ?? 0,
        totalChairs: (json['totalChairs'] as int?) ?? 0,
      );
}

class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.durationMin,
    required this.price,
    this.description,
    this.rebookIntervalDays,
  });

  final String id;
  final String name;
  final String category;
  final int durationMin;
  final double price;
  final String? description;
  final int? rebookIntervalDays;

  String get priceLabel => '₹${price.toStringAsFixed(0)}';
  String get durationLabel => '${durationMin}m';

  factory ServiceItem.fromJson(Map<String, dynamic> json) => ServiceItem(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        durationMin: (json['durationMin'] as int?) ??
            int.tryParse(json['duration']?.toString() ?? '') ??
            0,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        description: json['description']?.toString(),
        rebookIntervalDays: json['rebookIntervalDays'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'durationMin': durationMin,
        'price': price,
      };
}

class Barber {
  const Barber({
    required this.id,
    required this.name,
    required this.shopId,
    required this.isAvailable,
    this.rating,
    this.avatarUrl,
    this.bio,
    this.userId,
  });

  final String id;
  final String name;
  final String shopId;
  final bool isAvailable;
  final double? rating;
  final String? avatarUrl;
  final String? bio;
  final String? userId;

  factory Barber.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return Barber(
      id: json['id']?.toString() ?? '',
      name: user?['fullName']?.toString() ?? json['name']?.toString() ?? '',
      shopId: json['shopId']?.toString() ?? '',
      isAvailable: (json['isAvailable'] as bool?) ?? true,
      rating: (json['rating'] as num?)?.toDouble(),
      avatarUrl: user?['profileImage']?.toString() ??
          json['avatarUrl']?.toString(),
      bio: json['bio']?.toString(),
      userId: user?['id']?.toString() ?? json['userId']?.toString(),
    );
  }
}

class ShopReview {
  const ShopReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.customerName,
    this.tags = const [],
  });

  final String id;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String customerName;
  final List<String> tags;

  factory ShopReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return ShopReview(
      id: json['id']?.toString() ?? '',
      rating: (json['rating'] as int?) ?? 0,
      comment: json['comment']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      customerName:
          user?['fullName']?.toString() ?? json['customerName']?.toString() ?? 'Anonymous',
      tags: (json['tags'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class WaitEstimate {
  const WaitEstimate({
    required this.barberId,
    required this.barberName,
    required this.estimatedWaitMinutes,
    required this.queueLength,
    required this.isAvailable,
  });

  final String barberId;
  final String barberName;
  final int estimatedWaitMinutes;
  final int queueLength;
  final bool isAvailable;

  factory WaitEstimate.fromJson(Map<String, dynamic> json) {
    final barber = json['barber'] as Map<String, dynamic>?;
    final user = barber?['user'] as Map<String, dynamic>?;
    return WaitEstimate(
      barberId: barber?['id']?.toString() ?? json['barberId']?.toString() ?? '',
      barberName: user?['fullName']?.toString() ??
          barber?['name']?.toString() ??
          json['barberName']?.toString() ??
          'Barber',
      estimatedWaitMinutes: (json['estimatedWaitMinutes'] as int?) ?? 0,
      queueLength: (json['queueLength'] as int?) ?? 0,
      isAvailable: (json['isAvailable'] as bool?) ?? true,
    );
  }
}
