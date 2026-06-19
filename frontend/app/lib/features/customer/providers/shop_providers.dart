import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/models/bookber_models.dart';
import '../../../core/network/api_result.dart';
import '../../maps/services/location_service.dart';
import '../../shops/data/shop_repository.dart';
import '../../shops/domain/shop_models.dart';

// ── Location ───────────────────────────────────────────────────

final locationProvider = FutureProvider<Position?>((ref) async {
  try {
    return await LocationService().getCurrentLocation();
  } catch (_) {
    return null;
  }
});

// ── Shops list ─────────────────────────────────────────────────

final nearbyShopsProvider = FutureProvider.family<List<ShopSummary>, String>(
  (ref, cityOrDefault) async {
    final repo = ref.read(shopRepositoryProvider);
    final locationAsync = await ref.watch(locationProvider.future);

    final result = await repo.searchShops(
      city: locationAsync == null ? cityOrDefault : null,
      latitude: locationAsync?.latitude,
      longitude: locationAsync?.longitude,
      radiusKm: locationAsync != null ? 10 : null,
      isActive: true,
    );

    if (result is ApiSuccess<ShopPage>) return result.data.data;
    return const [];
  },
);

// ── Shop detail ────────────────────────────────────────────────

final shopDetailProvider = FutureProvider.family<ShopDetail?, String>(
  (ref, shopId) async {
    if (shopId.isEmpty) return null;
    final result = await ref.read(shopRepositoryProvider).getShop(shopId);
    if (result is ApiSuccess<ShopDetail>) return result.data;
    return null;
  },
);

// ── Services ───────────────────────────────────────────────────

final shopServicesProvider = FutureProvider.family<List<ServiceItem>, String>(
  (ref, shopId) async {
    if (shopId.isEmpty) return const [];
    final result = await ref.read(shopRepositoryProvider).getServices(shopId);
    if (result is ApiSuccess<List<ShopService>>) {
      return result.data.map(_toServiceItem).toList();
    }
    return const [];
  },
);

ServiceItem _toServiceItem(ShopService s) => ServiceItem(
      id: s.id,
      name: s.name,
      category: '',
      durationMin: s.durationMinutes,
      price: s.price,
    );

// ── Barbers ────────────────────────────────────────────────────

final shopBarbersProvider = FutureProvider.family<List<Barber>, String>(
  (ref, shopId) async {
    // GET /shops/:shopId/barbers not yet in ShopRepository — returns empty until extended.
    return const [];
  },
);

// ── Search ─────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchShopsProvider = FutureProvider.family<List<ShopSummary>, String>(
  (ref, query) async {
    if (query.isEmpty) {
      return ref.watch(nearbyShopsProvider('Ludhiana')).when(
            data: (shops) => shops,
            loading: () => const [],
            error: (_, __) => const [],
          );
    }

    final repo = ref.read(shopRepositoryProvider);
    final locationAsync = await ref.watch(locationProvider.future);

    final result = await repo.searchShops(
      query: query,
      city: locationAsync == null ? 'Ludhiana' : null,
      latitude: locationAsync?.latitude,
      longitude: locationAsync?.longitude,
    );

    if (result is ApiSuccess<ShopPage>) return result.data.data;
    return const [];
  },
);

// ── Filters ────────────────────────────────────────────────────

class ShopFiltersNotifier extends StateNotifier<ShopFilters> {
  ShopFiltersNotifier() : super(const ShopFilters());

  void updateMaxDistance(double v) => state = state.copyWith(maxDistance: v);
  void updateMinRating(int v) => state = state.copyWith(minRating: v);
  void toggleOpenNow() => state = state.copyWith(openNow: !state.openNow);
  void updateSortBy(String v) => state = state.copyWith(sortBy: v);

  void toggleService(String service) {
    final next = Set<String>.from(state.services);
    if (next.contains(service)) {
      next.remove(service);
    } else {
      next.add(service);
    }
    state = state.copyWith(services: next);
  }

  void reset() => state = const ShopFilters();
}

final shopFiltersProvider =
    StateNotifierProvider<ShopFiltersNotifier, ShopFilters>(
  (ref) => ShopFiltersNotifier(),
);

// ── Live queue stub ────────────────────────────────────────────

final liveQueueProvider = StreamProvider.family<Map<String, dynamic>, String>(
  (ref, shopId) async* {
    // Replaced by real socket events in socket_providers.dart.
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 10));
      yield const {'waitTime': 0, 'peopleAhead': 0, 'availableChairs': 0};
    }
  },
);
