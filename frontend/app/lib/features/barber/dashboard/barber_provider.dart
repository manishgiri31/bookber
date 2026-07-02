import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/providers/providers.dart';
import '../../../core/storage/secure_storage.dart';
import '../../shared/domain/queue_models.dart';

// ─────────────── Barber profile ───────────────

class BarberProfile {
  const BarberProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.shopId,
    required this.shopName,
    required this.shopAddress,
    required this.isAvailable,
    required this.onBreak,
    this.profileImage,
    this.email,
    this.checkInToken,
  });

  final String id;
  final String userId;
  final String name;
  final String shopId;
  final String shopName;
  final String shopAddress;
  final bool isAvailable;
  final bool onBreak;
  final String? profileImage;
  final String? email;
  /// Permanent per-barber token encoded in the check-in QR code.
  final String? checkInToken;

  factory BarberProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final shop = json['shop'] as Map<String, dynamic>?;
    return BarberProfile(
      id: json['id']?.toString() ?? '',
      userId: user?['id']?.toString() ?? json['userId']?.toString() ?? '',
      name: user?['fullName']?.toString() ?? json['name']?.toString() ?? '',
      shopId: shop?['id']?.toString() ?? json['shopId']?.toString() ?? '',
      shopName: shop?['name']?.toString() ?? '',
      shopAddress: shop?['address']?.toString() ?? '',
      isAvailable: (json['isAvailable'] as bool?) ?? true,
      onBreak: (json['onBreak'] as bool?) ?? false,
      profileImage: user?['profileImage']?.toString(),
      email: user?['email']?.toString(),
      checkInToken: json['checkInToken']?.toString(),
    );
  }
}

class BarberStats {
  const BarberStats({
    required this.todayBookings,
    required this.activeQueue,
    required this.completedToday,
    this.revenueToday = 0.0,
    this.revenueWeek = 0.0,
    this.totalReviews = 0,
    this.averageRating = 0.0,
  });

  final int todayBookings;
  final int activeQueue;
  final int completedToday;
  final double revenueToday;
  final double revenueWeek;
  final int totalReviews;
  final double averageRating;

  factory BarberStats.fromJson(Map<String, dynamic> json) => BarberStats(
        todayBookings: (json['todayBookings'] as int?) ?? 0,
        activeQueue: (json['activeQueue'] as int?) ?? 0,
        completedToday: (json['completedToday'] as int?) ?? 0,
        revenueToday: (json['revenueToday'] as num?)?.toDouble() ?? 0.0,
        revenueWeek: (json['revenueWeek'] as num?)?.toDouble() ?? 0.0,
        totalReviews: (json['totalReviews'] as int?) ?? 0,
        averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      );
}

// ─────────────── State ───────────────

class BarberDashState {
  const BarberDashState({
    this.profile,
    this.stats,
    this.queueEntries = const [],
    this.isLoading = false,
    this.error,
  });

  final BarberProfile? profile;
  final BarberStats? stats;
  final List<QueueEntry> queueEntries;
  final bool isLoading;
  final String? error;

  BarberDashState copyWith({
    BarberProfile? profile,
    BarberStats? stats,
    List<QueueEntry>? queueEntries,
    bool? isLoading,
    String? error,
  }) =>
      BarberDashState(
        profile: profile ?? this.profile,
        stats: stats ?? this.stats,
        queueEntries: queueEntries ?? this.queueEntries,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class BarberDashNotifier extends Notifier<BarberDashState> {
  @override
  BarberDashState build() {
    load();
    return const BarberDashState(isLoading: true);
  }

  Future<void> load() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final api = ref.read(apiClientProvider);
      final storage = ref.read(secureStorageProvider);
      final cachedBarberId = await storage.read(StorageKeys.barberId);

      late final Map<String, dynamic> meData;
      late final Map<String, dynamic> statsData;
      late final Map<String, dynamic> queueData;

      if (cachedBarberId != null) {
        // All three in parallel — the fast path after first load.
        final results = await Future.wait([
          api.get<Map<String, dynamic>>(ApiEndpoints.barberMe),
          api.get<Map<String, dynamic>>(ApiEndpoints.barberStats(cachedBarberId)),
          api.get<Map<String, dynamic>>(ApiEndpoints.barberQueue(cachedBarberId)),
        ]);
        meData = results[0];
        statsData = results[1];
        queueData = results[2];
      } else {
        // First-ever load: profile must come first to get the barber ID.
        meData = await api.get<Map<String, dynamic>>(ApiEndpoints.barberMe);
        final id = (meData['barber'] as Map<String, dynamic>?)?['id']?.toString()
            ?? meData['id']?.toString()
            ?? '';
        if (id.isNotEmpty) {
          await storage.write(StorageKeys.barberId, id);
        }
        final parallel = await Future.wait([
          api.get<Map<String, dynamic>>(ApiEndpoints.barberStats(id)),
          api.get<Map<String, dynamic>>(ApiEndpoints.barberQueue(id)),
        ]);
        statsData = parallel[0];
        queueData = parallel[1];
      }

      final profile = BarberProfile.fromJson(
        meData['barber'] as Map<String, dynamic>? ?? meData,
      );
      // Keep cached ID in sync with the real profile ID.
      if (cachedBarberId == null || cachedBarberId != profile.id) {
        await storage.write(StorageKeys.barberId, profile.id);
      }

      final stats = BarberStats.fromJson(statsData);
      final entries = (queueData['queue'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(QueueEntry.fromJson)
          .toList();

      state = state.copyWith(
        profile: profile,
        stats: stats,
        queueEntries: entries,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateEntryStatus(String entryId, String newStatus) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.patch<void>(
        ApiEndpoints.queueEntryStatus(entryId),
        body: {'status': newStatus},
      );
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleAvailability() async {
    if (state.profile == null) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.patch<void>(
        ApiEndpoints.barberStatus(state.profile!.id),
        body: {'isAvailable': !state.profile!.isAvailable},
      );
      final p = state.profile!;
      state = state.copyWith(
        profile: BarberProfile(
          id: p.id, userId: p.userId, name: p.name,
          shopId: p.shopId, shopName: p.shopName, shopAddress: p.shopAddress,
          isAvailable: !p.isAvailable, onBreak: p.onBreak,
          profileImage: p.profileImage, email: p.email, checkInToken: p.checkInToken,
        ),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleBreak() async {
    if (state.profile == null) return;
    try {
      final api = ref.read(apiClientProvider);
      final newBreak = !state.profile!.onBreak;
      await api.patch<void>(
        ApiEndpoints.barberBreak(state.profile!.id),
        body: {'onBreak': newBreak},
      );
      final p = state.profile!;
      state = state.copyWith(
        profile: BarberProfile(
          id: p.id, userId: p.userId, name: p.name,
          shopId: p.shopId, shopName: p.shopName, shopAddress: p.shopAddress,
          isAvailable: p.isAvailable, onBreak: newBreak,
          profileImage: p.profileImage, email: p.email, checkInToken: p.checkInToken,
        ),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refresh() => load();
}

final barberDashProvider =
    NotifierProvider<BarberDashNotifier, BarberDashState>(
  BarberDashNotifier.new,
);
