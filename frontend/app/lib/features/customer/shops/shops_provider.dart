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

enum ShopSortBy { none, nearest, topRated, fastest }

class ShopsSearchState {
  const ShopsSearchState({
    this.query = '',
    this.shops = const [],
    this.isLoading = false,
    this.error,
    this.hasSearched = false,
    this.sortBy = ShopSortBy.none,
    this.openOnly = false,
    this.verifiedOnly = false,
    this.minRating = 0.0,
    this.maxDistanceKm,
  });

  final String query;
  final List<Shop> shops;
  final bool isLoading;
  final String? error;
  final bool hasSearched;
  final ShopSortBy sortBy;
  final bool openOnly;
  final bool verifiedOnly;
  final double minRating;
  final double? maxDistanceKm;

  bool get hasActiveFilters =>
      openOnly || verifiedOnly || minRating > 0 || maxDistanceKm != null;

  List<Shop> get displayed {
    var list = shops.where((s) {
      if (openOnly && !s.isOpen) return false;
      if (verifiedOnly && !(s.isVerified)) return false;
      if (minRating > 0 && s.rating < minRating) return false;
      if (maxDistanceKm != null &&
          s.distanceKm != null &&
          s.distanceKm! > maxDistanceKm!) return false;
      return true;
    }).toList();

    switch (sortBy) {
      case ShopSortBy.nearest:
        list.sort((a, b) {
          if (a.distanceKm == null && b.distanceKm == null) return 0;
          if (a.distanceKm == null) return 1;
          if (b.distanceKm == null) return -1;
          return a.distanceKm!.compareTo(b.distanceKm!);
        });
      case ShopSortBy.topRated:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case ShopSortBy.fastest:
        list.sort((a, b) => a.waitTimeMinutes.compareTo(b.waitTimeMinutes));
      case ShopSortBy.none:
        break;
    }
    return list;
  }

  ShopsSearchState copyWith({
    String? query,
    List<Shop>? shops,
    bool? isLoading,
    String? error,
    bool? hasSearched,
    ShopSortBy? sortBy,
    bool? openOnly,
    bool? verifiedOnly,
    double? minRating,
    Object? maxDistanceKm = _sentinel,
  }) =>
      ShopsSearchState(
        query: query ?? this.query,
        shops: shops ?? this.shops,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        hasSearched: hasSearched ?? this.hasSearched,
        sortBy: sortBy ?? this.sortBy,
        openOnly: openOnly ?? this.openOnly,
        verifiedOnly: verifiedOnly ?? this.verifiedOnly,
        minRating: minRating ?? this.minRating,
        maxDistanceKm: maxDistanceKm == _sentinel
            ? this.maxDistanceKm
            : maxDistanceKm as double?,
      );
}

const _sentinel = Object();

class ShopsNotifier extends AutoDisposeNotifier<ShopsSearchState> {
  @override
  ShopsSearchState build() {
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

  void setSortBy(ShopSortBy sort) {
    state = state.copyWith(
      sortBy: state.sortBy == sort ? ShopSortBy.none : sort,
    );
  }

  void setOpenOnly(bool val) => state = state.copyWith(openOnly: val);
  void setVerifiedOnly(bool val) => state = state.copyWith(verifiedOnly: val);
  void setMinRating(double val) => state = state.copyWith(minRating: val);
  void setMaxDistance(double? val) =>
      state = state.copyWith(maxDistanceKm: val);
  void clearFilters() => state = state.copyWith(
        openOnly: false,
        verifiedOnly: false,
        minRating: 0.0,
        maxDistanceKm: null,
      );

  void clear() => state = const ShopsSearchState();
  Future<void> refresh() => _loadAll();
}

final shopsProvider =
    AutoDisposeNotifierProvider<ShopsNotifier, ShopsSearchState>(
        ShopsNotifier.new);
