import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/providers/providers.dart';
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
    this.profileImage,
    this.email,
  });

  final String id;
  final String userId;
  final String name;
  final String shopId;
  final String shopName;
  final String shopAddress;
  final bool isAvailable;
  final String? profileImage;
  final String? email;

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
      profileImage: user?['profileImage']?.toString(),
      email: user?['email']?.toString(),
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

class BarberDashNotifier extends AutoDisposeNotifier<BarberDashState> {
  @override
  BarberDashState build() {
    load();
    return const BarberDashState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiClientProvider);
      final meData =
          await api.get<Map<String, dynamic>>(ApiEndpoints.barberMe);
      final profile = BarberProfile.fromJson(
        meData['barber'] as Map<String, dynamic>? ?? meData,
      );

      final [statsData, queueData] = await Future.wait([
        api.get<Map<String, dynamic>>(ApiEndpoints.barberStats(profile.id)),
        api.get<Map<String, dynamic>>(ApiEndpoints.barberQueue(profile.id)),
      ]);

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
      state = state.copyWith(
        profile: BarberProfile(
          id: state.profile!.id,
          userId: state.profile!.userId,
          name: state.profile!.name,
          shopId: state.profile!.shopId,
          shopName: state.profile!.shopName,
          shopAddress: state.profile!.shopAddress,
          isAvailable: !state.profile!.isAvailable,
          profileImage: state.profile!.profileImage,
          email: state.profile!.email,
        ),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refresh() => load();
}

final barberDashProvider =
    AutoDisposeNotifierProvider<BarberDashNotifier, BarberDashState>(
  BarberDashNotifier.new,
);
