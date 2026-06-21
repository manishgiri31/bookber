import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/providers.dart';
import '../../shared/domain/shop_models.dart';

// ─── Nearby shops (POST /geolocation/nearby) ─────────────────────────────────

final nearbyShopsProvider =
    FutureProvider.autoDispose<List<Shop>>((ref) async {
  final location = ref.watch(locationProvider).valueOrNull;
  if (location == null) return [];

  try {
    final api = ref.read(apiClientProvider);
    final data = await api.post<Map<String, dynamic>>(
      ApiEndpoints.nearbyShops,
      body: {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'radius': 10,
        'limit': 10,
        'sortBy': 'distance',
      },
    );
    final rawList = data['data'] ?? data['shops'] ?? [];
    final list = rawList is List ? rawList : <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(_nearbyToShop)
        .toList();
  } catch (_) {
    return [];
  }
});

// ─── Top rated shops (GET /geolocation/top-rated) ────────────────────────────

final topRatedShopsProvider =
    FutureProvider.autoDispose<List<Shop>>((ref) async {
  final location = ref.watch(locationProvider).valueOrNull;

  try {
    final api = ref.read(apiClientProvider);
    final params = <String, dynamic>{'limit': '8', 'radius': '50'};
    if (location != null) {
      params['latitude'] = location.latitude.toString();
      params['longitude'] = location.longitude.toString();
    }
    final data = await api.get<Map<String, dynamic>>(
      ApiEndpoints.topRatedShops,
      params: params,
    );
    final rawList = data['data'] ?? data['shops'] ?? [];
    final list = rawList is List ? rawList : <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(_nearbyToShop)
        .toList();
  } catch (_) {
    return [];
  }
});

// ─── Helper: map geolocation API fields → Shop ───────────────────────────────

Shop _nearbyToShop(Map<String, dynamic> j) => Shop(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      address: j['address']?.toString() ?? '',
      city: j['city']?.toString() ?? '',
      rating: (j['averageRating'] as num?)?.toDouble() ??
          (j['rating'] as num?)?.toDouble() ??
          0.0,
      reviewCount: (j['reviewCount'] as num?)?.toInt() ?? 0,
      isOpen: (j['isAcceptingBookings'] as bool?) ??
          (j['isActive'] as bool?) ??
          true,
      waitTimeMinutes: (j['estimatedWaitMinutes'] as num?)?.toInt() ??
          (j['waitTimeMinutes'] as num?)?.toInt() ??
          0,
      availableChairs: (j['availableChairs'] as num?)?.toInt() ?? 0,
      imageUrl: j['profileImage']?.toString() ?? j['imageUrl']?.toString(),
      distanceKm: (j['distance'] as num?)?.toDouble() ??
          (j['distanceKm'] as num?)?.toDouble(),
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      description: j['description']?.toString(),
    );
