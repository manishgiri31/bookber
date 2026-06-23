import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../shared/domain/shop_models.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class ShopDetail {
  const ShopDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.phone,
    required this.openingTime,
    required this.closingTime,
    required this.isActive,
    required this.isAcceptingBookings,
    required this.isAcceptingWalkIns,
    this.services = const [],
    this.chairs = const [],
  });

  final String id;
  final String name;
  final String description;
  final String address;
  final String city;
  final String state;
  final String phone;
  final String openingTime;
  final String closingTime;
  final bool isActive;
  final bool isAcceptingBookings;
  final bool isAcceptingWalkIns;
  final List<ServiceItem> services;
  final List<ShopChair> chairs;

  factory ShopDetail.fromJson(Map<String, dynamic> json) => ShopDetail(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        state: json['state']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        openingTime: json['openingTime']?.toString() ?? '09:00',
        closingTime: json['closingTime']?.toString() ?? '21:00',
        isActive: (json['isActive'] as bool?) ?? true,
        isAcceptingBookings: (json['isAcceptingBookings'] as bool?) ?? true,
        isAcceptingWalkIns: (json['isAcceptingWalkIns'] as bool?) ?? true,
        services: (json['services'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ServiceItem.fromJson)
            .toList(),
        chairs: (json['chairs'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ShopChair.fromJson)
            .toList(),
      );
}

class ShopChair {
  const ShopChair({
    required this.id,
    required this.number,
    required this.status,
    required this.reservedForBookBer,
  });
  final String id;
  final int number;
  final String status;
  final bool reservedForBookBer;

  factory ShopChair.fromJson(Map<String, dynamic> json) => ShopChair(
        id: json['id']?.toString() ?? '',
        number: (json['number'] as int?) ?? 0,
        status: json['status']?.toString() ?? 'AVAILABLE',
        reservedForBookBer: (json['reservedForBookBer'] as bool?) ?? false,
      );
}

// ─── State ────────────────────────────────────────────────────────────────────

class ShopManagementState {
  const ShopManagementState({
    this.shop,
    this.isLoading = false,
    this.error,
    this.isSaving = false,
  });
  final ShopDetail? shop;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  ShopManagementState copyWith({
    ShopDetail? shop,
    bool? isLoading,
    String? error,
    bool? isSaving,
    bool clearError = false,
  }) =>
      ShopManagementState(
        shop: shop ?? this.shop,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        isSaving: isSaving ?? this.isSaving,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ShopManagementNotifier
    extends AutoDisposeNotifier<ShopManagementState> {
  @override
  ShopManagementState build() {
    load();
    return const ShopManagementState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.get<Map<String, dynamic>>('/shops/my');
      final shop = ShopDetail.fromJson(
          data['shop'] as Map<String, dynamic>? ?? data);
      state = state.copyWith(shop: shop, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createService(Map<String, dynamic> body) async {
    if (state.shop == null) return false;
    state = state.copyWith(isSaving: true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<void>('/shops/${state.shop!.id}/services', body: body);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateService(String serviceId, Map<String, dynamic> body) async {
    state = state.copyWith(isSaving: true);
    try {
      final api = ref.read(apiClientProvider);
      await api.patch<void>('/shops/services/$serviceId', body: body);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteService(String serviceId) async {
    state = state.copyWith(isSaving: true);
    try {
      final api = ref.read(apiClientProvider);
      await api.delete<void>('/shops/services/$serviceId');
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateShopInfo(Map<String, dynamic> body) async {
    if (state.shop == null) return false;
    state = state.copyWith(isSaving: true);
    try {
      final api = ref.read(apiClientProvider);
      await api.patch<void>('/shops/${state.shop!.id}', body: body);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> toggleAcceptingBookings() async {
    if (state.shop == null) return false;
    return updateShopInfo(
        {'isAcceptingBookings': !state.shop!.isAcceptingBookings});
  }

  Future<bool> toggleAcceptingWalkIns() async {
    if (state.shop == null) return false;
    return updateShopInfo(
        {'isAcceptingWalkIns': !state.shop!.isAcceptingWalkIns});
  }
}

final shopManagementProvider = AutoDisposeNotifierProvider<
    ShopManagementNotifier, ShopManagementState>(
  ShopManagementNotifier.new,
);
