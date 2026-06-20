import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/providers.dart';
import '../../shared/domain/booking_models.dart';
import '../../shared/domain/shop_models.dart';

// ─────────────── Active bookings ───────────────

final activeBookingsProvider =
    FutureProvider.autoDispose<List<Booking>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final data =
        await api.get<Map<String, dynamic>>('/bookings/my?status=active');
    final list = data['bookings'] as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Booking.fromJson)
        .where((b) => b.isActive)
        .toList();
  } catch (_) {
    return [];
  }
});

// ─────────────── Home state ───────────────

class HomeState {
  const HomeState({
    this.shops = const [],
    this.activeBookings = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Shop> shops;
  final List<Booking> activeBookings;
  final bool isLoading;
  final String? error;

  HomeState copyWith({
    List<Shop>? shops,
    List<Booking>? activeBookings,
    bool? isLoading,
    String? error,
  }) =>
      HomeState(
        shops: shops ?? this.shops,
        activeBookings: activeBookings ?? this.activeBookings,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class HomeNotifier extends AutoDisposeNotifier<HomeState> {
  @override
  HomeState build() {
    // Reload shops when location becomes available
    ref.listen(locationProvider, (_, next) {
      if (next.hasValue) load();
    });
    load();
    return const HomeState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiClientProvider);
      final location = ref.read(locationProvider).valueOrNull;
      final params = <String, dynamic>{};
      if (location != null) {
        params['lat'] = location.latitude.toString();
        params['lng'] = location.longitude.toString();
      }
      final data = await api.get<Map<String, dynamic>>(
        ApiEndpoints.shops,
        params: params,
      );
      final shops = (data['shops'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Shop.fromJson)
          .toList();
      state = state.copyWith(shops: shops, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => load();
}

final homeProvider =
    AutoDisposeNotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);
