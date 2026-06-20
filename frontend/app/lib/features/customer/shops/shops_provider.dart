import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/providers.dart';
import '../../shared/domain/shop_models.dart';

// ─────────────── Shop detail ───────────────

final shopDetailProvider =
    FutureProvider.autoDispose.family<Shop, String>((ref, shopId) async {
  final api = ref.watch(apiClientProvider);
  final data =
      await api.get<Map<String, dynamic>>(ApiEndpoints.shopById(shopId));
  return Shop.fromJson(data['shop'] as Map<String, dynamic>? ?? data);
});

final shopServicesProvider =
    FutureProvider.autoDispose.family<List<ServiceItem>, String>((ref, shopId) async {
  final api = ref.watch(apiClientProvider);
  final data =
      await api.get<Map<String, dynamic>>(ApiEndpoints.shopServices(shopId));
  final list = data['services'] as List? ?? [];
  return list
      .whereType<Map<String, dynamic>>()
      .map(ServiceItem.fromJson)
      .toList();
});

final shopBarbersProvider =
    FutureProvider.autoDispose.family<List<Barber>, String>((ref, shopId) async {
  final api = ref.watch(apiClientProvider);
  try {
    final data =
        await api.get<Map<String, dynamic>>(ApiEndpoints.shopById(shopId));
    final shopData = data['shop'] as Map<String, dynamic>? ?? data;
    final list = shopData['barbers'] as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Barber.fromJson)
        .toList();
  } catch (_) {
    return [];
  }
});

final shopReviewsProvider =
    FutureProvider.autoDispose.family<List<ShopReview>, String>((ref, shopId) async {
  final api = ref.watch(apiClientProvider);
  try {
    final data =
        await api.get<Map<String, dynamic>>(ApiEndpoints.shopReviews(shopId));
    final list = data['reviews'] as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ShopReview.fromJson)
        .toList();
  } catch (_) {
    return [];
  }
});

final shopWaitEstimatesProvider =
    FutureProvider.autoDispose.family<List<WaitEstimate>, String>((ref, shopId) async {
  final api = ref.watch(apiClientProvider);
  try {
    final data = await api
        .get<Map<String, dynamic>>(ApiEndpoints.shopWaitEstimates(shopId));
    final list = data['estimates'] as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(WaitEstimate.fromJson)
        .toList();
  } catch (_) {
    return [];
  }
});

// ─────────────── Shop search ───────────────

class ShopsSearchState {
  const ShopsSearchState({
    this.query = '',
    this.shops = const [],
    this.isLoading = false,
    this.error,
    this.hasSearched = false,
  });

  final String query;
  final List<Shop> shops;
  final bool isLoading;
  final String? error;
  final bool hasSearched;

  ShopsSearchState copyWith({
    String? query,
    List<Shop>? shops,
    bool? isLoading,
    String? error,
    bool? hasSearched,
  }) =>
      ShopsSearchState(
        query: query ?? this.query,
        shops: shops ?? this.shops,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        hasSearched: hasSearched ?? this.hasSearched,
      );
}

class ShopsNotifier extends AutoDisposeNotifier<ShopsSearchState> {
  @override
  ShopsSearchState build() {
    // React to location changes — reload shops when location becomes available
    ref.listen(locationProvider, (_, next) {
      if (next.hasValue && state.hasSearched) {
        _loadAll();
      }
    });
    _loadAll();
    return const ShopsSearchState(isLoading: true);
  }

  Map<String, dynamic> _locationParams() {
    final location = ref.read(locationProvider).valueOrNull;
    if (location == null) return {};
    return {
      'lat': location.latitude.toString(),
      'lng': location.longitude.toString(),
    };
  }

  Future<void> _loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.get<Map<String, dynamic>>(
        ApiEndpoints.shops,
        params: _locationParams(),
      );
      final shops = (data['shops'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Shop.fromJson)
          .toList();
      state = state.copyWith(shops: shops, isLoading: false, hasSearched: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isLoading: true, error: null);
    try {
      final api = ref.read(apiClientProvider);
      final params = <String, dynamic>{...(_locationParams())};
      if (query.isNotEmpty) params['name'] = query;
      final data = await api.get<Map<String, dynamic>>(
        ApiEndpoints.shops,
        params: params,
      );
      final shops = (data['shops'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Shop.fromJson)
          .toList();
      state =
          state.copyWith(shops: shops, isLoading: false, hasSearched: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() => state = const ShopsSearchState();
  Future<void> refresh() => _loadAll();
}

final shopsProvider =
    AutoDisposeNotifierProvider<ShopsNotifier, ShopsSearchState>(
        ShopsNotifier.new);
