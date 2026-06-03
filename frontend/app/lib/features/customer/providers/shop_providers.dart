import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/models/bookber_models.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../../maps/services/location_service.dart';

// Location provider with graceful fallback to default city
final locationProvider = FutureProvider<Position?>((ref) async {
  try {
    final locationService = LocationService();
    final position = await locationService.getCurrentLocation();
    return position;
  } catch (_) {
    // If location fails, return null (fallback to city-based search)
    return null;
  }
});

// Nearby shops provider with location-based search or city fallback
final nearbyShopsProvider = FutureProvider.family<List<Shop>, String>(
  (ref, cityOrDefault) async {
    final dio = ref.read(dioClientProvider);
    
    try {
      // Try to get current location
      final locationAsync = await ref.watch(locationProvider.future);
      
      String url;
      if (locationAsync != null) {
        // Location-based search
        url = '/api/shops?lat=${locationAsync.latitude}&lng=${locationAsync.longitude}&radius=10&limit=20';
      } else {
        // Fallback to city-based search
        url = '/api/shops?city=Ludhiana&limit=20';
      }
      
      final response = await dio.get(url);
      
      if (response is List) {
        return response
            .map((json) => Shop.fromJson(json is Map<String, dynamic> ? json : {}))
            .toList();
      }
      
      if (response is Map<String, dynamic> && response['data'] is List) {
        return (response['data'] as List)
            .map((json) => Shop.fromJson(json is Map<String, dynamic> ? json : {}))
            .toList();
      }
      
      return [];
    } catch (_) {
      return [];
    }
  },
);

// Shop detail provider
final shopDetailProvider = FutureProvider.family<Shop?, String>(
  (ref, shopId) async {
    if (shopId.isEmpty) return null;
    
    final dio = ref.read(dioClientProvider);
    
    try {
      final response = await dio.get('/api/shops/$shopId');
      
      if (response is Map<String, dynamic>) {
        return Shop.fromJson(response);
      }
      
      if (response is Map<String, dynamic> && response['data'] is Map<String, dynamic>) {
        return Shop.fromJson(response['data'] as Map<String, dynamic>);
      }
      
      return null;
    } catch (_) {
      return null;
    }
  },
);

// Shop services provider
final shopServicesProvider = FutureProvider.family<List<ServiceItem>, String>(
  (ref, shopId) async {
    if (shopId.isEmpty) return [];
    
    final dio = ref.read(dioClientProvider);
    
    try {
      final response = await dio.get('/api/shops/$shopId/services');
      
      if (response is List) {
        return response
            .map((json) => ServiceItem.fromJson(json is Map<String, dynamic> ? json : {}))
            .toList();
      }
      
      if (response is Map<String, dynamic> && response['data'] is List) {
        return (response['data'] as List)
            .map((json) => ServiceItem.fromJson(json is Map<String, dynamic> ? json : {}))
            .toList();
      }
      
      return [];
    } catch (_) {
      return [];
    }
  },
);

// Shop barbers provider
final shopBarbersProvider = FutureProvider.family<List<Barber>, String>(
  (ref, shopId) async {
    if (shopId.isEmpty) return [];
    
    final dio = ref.read(dioClientProvider);
    
    try {
      final response = await dio.get('/api/shops/$shopId/barbers');
      
      if (response is List) {
        return response
            .map((json) => Barber.fromJson(json is Map<String, dynamic> ? json : {}))
            .toList();
      }
      
      if (response is Map<String, dynamic> && response['data'] is List) {
        return (response['data'] as List)
            .map((json) => Barber.fromJson(json is Map<String, dynamic> ? json : {}))
            .toList();
      }
      
      return [];
    } catch (_) {
      return [];
    }
  },
);

// Search query state provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Shop filters state provider with notifier
class ShopFiltersNotifier extends StateNotifier<ShopFilters> {
  ShopFiltersNotifier() : super(const ShopFilters());

  void updateMaxDistance(double value) {
    state = state.copyWith(maxDistance: value);
  }

  void updateMinRating(int value) {
    state = state.copyWith(minRating: value);
  }

  void toggleOpenNow() {
    state = state.copyWith(openNow: !state.openNow);
  }

  void updateSortBy(String value) {
    state = state.copyWith(sortBy: value);
  }

  void toggleService(String service) {
    final newServices = Set<String>.from(state.services);
    if (newServices.contains(service)) {
      newServices.remove(service);
    } else {
      newServices.add(service);
    }
    state = state.copyWith(services: newServices);
  }

  void reset() {
    state = const ShopFilters();
  }
}

final shopFiltersProvider =
    StateNotifierProvider<ShopFiltersNotifier, ShopFilters>(
  (ref) => ShopFiltersNotifier(),
);

// Search shops provider with search query and filters
final searchShopsProvider = FutureProvider.family<List<Shop>, String>(
  (ref, query) async {
    if (query.isEmpty) {
      // If query is empty, return nearby shops instead
      return ref.watch(nearbyShopsProvider('Ludhiana')).when(
        data: (shops) => shops,
        loading: () => [],
        error: (_, __) => [],
      );
    }
    
    final dio = ref.read(dioClientProvider);
    final filters = ref.watch(shopFiltersProvider);
    final locationAsync = await ref.watch(locationProvider.future);
    
    try {
      final queryParams = <String, dynamic>{
        'q': query,
        ...filters.toQueryParams(),
      };
      
      if (locationAsync != null) {
        queryParams['lat'] = locationAsync.latitude;
        queryParams['lng'] = locationAsync.longitude;
      } else {
        queryParams['city'] = 'Ludhiana';
      }
      
      final response = await dio.get('/api/shops/search', queryParams: queryParams);
      
      if (response is List) {
        return response
            .map((json) => Shop.fromJson(json is Map<String, dynamic> ? json : {}))
            .toList();
      }
      
      if (response is Map<String, dynamic> && response['data'] is List) {
        return (response['data'] as List)
            .map((json) => Shop.fromJson(json is Map<String, dynamic> ? json : {}))
            .toList();
      }
      
      return [];
    } catch (_) {
      return [];
    }
  },
);

// Live queue provider (stream for real-time updates via Socket.io)
final liveQueueProvider = StreamProvider.family<Map<String, dynamic>, String>(
  (ref, shopId) async* {
    // TODO: Replace with socket.io connection once socket service is integrated
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      yield {
        'waitTime': 8,
        'peopleAhead': 4,
        'availableChairs': 3,
      };
    }
  },
);
