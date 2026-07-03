import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/bb_colors.dart';
import '../../core/design/bb_tokens.dart';
import '../../core/design/bb_typography.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/bb_button.dart';
import '../../core/widgets/bb_error_widget.dart';
import '../../core/widgets/bb_loading.dart';
import '../../core/widgets/bb_snackbar.dart';
import '../auth/data/auth_provider.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class AdminDashboardData {
  const AdminDashboardData({required this.analytics, required this.earnings});
  final AnalyticsOverview analytics;
  final EarningsOverview earnings;
}

class AnalyticsOverview {
  const AnalyticsOverview({
    required this.totalUsers,
    required this.totalBarbers,
    required this.totalShops,
    required this.totalBookings,
    required this.totalRevenue,
    required this.activeBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.averageRating,
  });

  final int totalUsers;
  final int totalBarbers;
  final int totalShops;
  final int totalBookings;
  final double totalRevenue;
  final int activeBookings;
  final int completedBookings;
  final int cancelledBookings;
  final double averageRating;

  factory AnalyticsOverview.fromJson(Map<String, dynamic> j) =>
      AnalyticsOverview(
        totalUsers: _i(j['totalUsers']),
        totalBarbers: _i(j['totalBarbers']),
        totalShops: _i(j['totalShops']),
        totalBookings: _i(j['totalBookings']),
        totalRevenue: _d(j['totalRevenue']),
        activeBookings: _i(j['activeBookings']),
        completedBookings: _i(j['completedBookings']),
        cancelledBookings: _i(j['cancelledBookings']),
        averageRating: _d(j['averageRating']),
      );

  static int _i(dynamic v) => (v as num?)?.toInt() ?? 0;
  static double _d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
}

class EarningsOverview {
  const EarningsOverview({
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.pendingPayouts,
    required this.revenueByShop,
  });

  final double totalRevenue;
  final double averageOrderValue;
  final double pendingPayouts;
  final List<ShopRevenue> revenueByShop;

  factory EarningsOverview.fromJson(Map<String, dynamic> j) => EarningsOverview(
        totalRevenue: (j['totalRevenue'] as num?)?.toDouble() ?? 0.0,
        averageOrderValue: (j['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
        pendingPayouts: (j['pendingPayouts'] as num?)?.toDouble() ?? 0.0,
        revenueByShop: (j['revenueByShop'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ShopRevenue.fromJson)
            .toList(),
      );
}

class ShopRevenue {
  const ShopRevenue({
    required this.shopName,
    required this.revenue,
  });

  final String shopName;
  final double revenue;

  factory ShopRevenue.fromJson(Map<String, dynamic> j) => ShopRevenue(
        shopName: j['shopName']?.toString() ?? '',
        revenue: (j['revenue'] as num?)?.toDouble() ?? 0.0,
      );
}

class BarberModerationItem {
  const BarberModerationItem({
    required this.barberId,
    required this.barberName,
    required this.shopName,
    required this.status,
    required this.totalBookings,
    required this.averageRating,
    required this.flaggedForReview,
  });

  final String barberId;
  final String barberName;
  final String shopName;
  final String status;
  final int totalBookings;
  final double averageRating;
  final bool flaggedForReview;

  factory BarberModerationItem.fromJson(Map<String, dynamic> j) =>
      BarberModerationItem(
        barberId: j['barberId']?.toString() ?? '',
        barberName: j['barberName']?.toString() ?? '',
        shopName: j['shopName']?.toString() ?? '',
        status: j['status']?.toString() ?? 'ACTIVE',
        totalBookings: (j['totalBookings'] as num?)?.toInt() ?? 0,
        averageRating: (j['averageRating'] as num?)?.toDouble() ?? 0.0,
        flaggedForReview: (j['flaggedForReview'] as bool?) ?? false,
      );
}

class ActiveQueue {
  const ActiveQueue({
    required this.shopName,
    required this.totalQueued,
    required this.averageWaitTime,
    required this.activeBarbers,
  });

  final String shopName;
  final int totalQueued;
  final double averageWaitTime;
  final int activeBarbers;

  factory ActiveQueue.fromJson(Map<String, dynamic> j) => ActiveQueue(
        shopName: j['shopName']?.toString() ?? '',
        totalQueued: (j['totalQueued'] as num?)?.toInt() ?? 0,
        averageWaitTime: (j['averageWaitTime'] as num?)?.toDouble() ?? 0.0,
        activeBarbers: (j['activeBarbers'] as num?)?.toInt() ?? 0,
      );
}

// ─── Providers ────────────────────────────────────────────────────────────────

final adminDashboardProvider =
    FutureProvider.autoDispose<AdminDashboardData>((ref) async {
  final api = ref.watch(apiClientProvider);
  final results = await Future.wait([
    api.get<Map<String, dynamic>>(ApiEndpoints.adminAnalyticsOverview),
    api.get<Map<String, dynamic>>(ApiEndpoints.adminAnalyticsEarnings),
  ]);
  return AdminDashboardData(
    analytics: AnalyticsOverview.fromJson(results[0]),
    earnings: EarningsOverview.fromJson(results[1]),
  );
});

final adminBarbersProvider =
    FutureProvider.autoDispose<List<BarberModerationItem>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.get<Map<String, dynamic>>(ApiEndpoints.adminBarbers);
  final list = data['data'] as List? ?? (data['barbers'] as List? ?? []);
  return list
      .whereType<Map<String, dynamic>>()
      .map(BarberModerationItem.fromJson)
      .toList();
});

final adminQueuesProvider =
    FutureProvider.autoDispose<List<ActiveQueue>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final data =
      await api.get<Map<String, dynamic>>(ApiEndpoints.adminActiveQueues);
  final rawList = data['queues'] ?? data;
  final list = rawList is List ? rawList : <dynamic>[];
  return list
      .whereType<Map<String, dynamic>>()
      .map(ActiveQueue.fromJson)
      .toList();
});

// ─── Admin screen ────────────────────────────────────────────────────────────

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Panel',
              style: BBTypography.textTheme.titleLarge?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (user?.email != null)
              Text(
                user!.email,
                style: BBTypography.textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(AppIcons.logout, color: colors.textSecondary),
            onPressed: () => ref.read(authProvider.notifier).logout(),
            tooltip: 'Sign out',
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: context.bbColors.accent,
          unselectedLabelColor: colors.textTertiary,
          indicatorColor: context.bbColors.accent,
          labelStyle: BBTypography.textTheme.labelMedium
              ?.copyWith(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Barbers'),
            Tab(text: 'Live Queues'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _DashboardTab(),
          _BarbersTab(),
          _QueuesTab(),
        ],
      ),
    );
  }
}

// ─── Dashboard tab ────────────────────────────────────────────────────────────

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminDashboardProvider);
    return async.when(
      loading: () => const BBSkeletonListView(),
      error: (e, _) => BBErrorWidget(
        error: e.toString(),
        onRetry: () => ref.invalidate(adminDashboardProvider),
        fullScreen: true,
      ),
      data: (data) => RefreshIndicator(
        color: context.bbColors.accent,
        onRefresh: () async => ref.invalidate(adminDashboardProvider),
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: BBSpacing.pageHorizontal,
            vertical: BBSpacing.base,
          ),
          children: [
            _SectionTitle('Platform Overview'),
            const SizedBox(height: BBSpacing.md),
            _KpiGrid(analytics: data.analytics),
            const SizedBox(height: BBSpacing.xl),
            _SectionTitle('Revenue'),
            const SizedBox(height: BBSpacing.md),
            _RevenueCard(earnings: data.earnings),
            const SizedBox(height: BBSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.analytics});
  final AnalyticsOverview analytics;

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiItem('Users', '${analytics.totalUsers}', AppIcons.people,
          BBColors.info),
      _KpiItem('Barbers', '${analytics.totalBarbers}',
          AppIcons.scissors, context.bbColors.accent),
      _KpiItem('Shops', '${analytics.totalShops}', AppIcons.store,
          BBColors.success),
      _KpiItem('Bookings', '${analytics.totalBookings}',
          AppIcons.calendar, BBColors.warning),
      _KpiItem('Active', '${analytics.activeBookings}',
          AppIcons.circleFill, BBColors.error),
      _KpiItem('Avg Rating', analytics.averageRating.toStringAsFixed(1),
          AppIcons.starFill, context.bbColors.accent),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: BBSpacing.sm,
        mainAxisSpacing: BBSpacing.sm,
        childAspectRatio: 1.0,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _KpiCard(item: items[i]),
    );
  }
}

class _KpiItem {
  const _KpiItem(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item});
  final _KpiItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 20, color: item.color),
          const SizedBox(height: BBSpacing.xs),
          Text(
            item.value,
            style: BBTypography.textTheme.titleLarge?.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            item.label,
            style: BBTypography.textTheme.labelSmall?.copyWith(
              color: colors.textTertiary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.earnings});
  final EarningsOverview earnings;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Revenue',
                      style: BBTypography.textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      '₹${earnings.totalRevenue.toStringAsFixed(0)}',
                      style: BBTypography.textTheme.headlineMedium?.copyWith(
                        color: BBColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Avg Order',
                    style: BBTypography.textTheme.labelSmall
                        ?.copyWith(color: colors.textTertiary),
                  ),
                  Text(
                    '₹${earnings.averageOrderValue.toStringAsFixed(0)}',
                    style: BBTypography.textTheme.titleMedium?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (earnings.revenueByShop.isNotEmpty) ...[
            const SizedBox(height: BBSpacing.base),
            const Divider(height: 1),
            const SizedBox(height: BBSpacing.base),
            Text(
              'By Shop',
              style: BBTypography.textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: BBSpacing.sm),
            ...earnings.revenueByShop.take(5).map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: BBSpacing.xs),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            s.shopName,
                            style: BBTypography.textTheme.bodySmall
                                ?.copyWith(color: colors.text),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '₹${s.revenue.toStringAsFixed(0)}',
                          style: BBTypography.textTheme.labelMedium?.copyWith(
                            color: BBColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

// ─── Barbers tab ──────────────────────────────────────────────────────────────

class _BarbersTab extends ConsumerWidget {
  const _BarbersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminBarbersProvider);
    return async.when(
      loading: () => const BBSkeletonListView(),
      error: (e, _) => BBErrorWidget(
        error: e.toString(),
        onRetry: () => ref.invalidate(adminBarbersProvider),
        fullScreen: true,
      ),
      data: (barbers) => barbers.isEmpty
          ? Center(
              child: Text(
                'No barbers found',
                style: BBTypography.textTheme.bodyMedium
                    ?.copyWith(color: context.bbColors.textSecondary),
              ),
            )
          : RefreshIndicator(
              color: context.bbColors.accent,
              onRefresh: () async => ref.invalidate(adminBarbersProvider),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: BBSpacing.pageHorizontal,
                  vertical: BBSpacing.base,
                ),
                itemCount: barbers.length,
                separatorBuilder: (_, _) => const SizedBox(height: BBSpacing.sm),
                itemBuilder: (ctx, i) =>
                    _BarberModerationCard(barber: barbers[i], ref: ref),
              ),
            ),
    );
  }
}

class _BarberModerationCard extends StatelessWidget {
  const _BarberModerationCard({required this.barber, required this.ref});
  final BarberModerationItem barber;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final isSuspended = barber.status == 'SUSPENDED';
    final statusColor = isSuspended ? BBColors.error : BBColors.success;

    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(
          color: barber.flaggedForReview
              ? BBColors.warning.withValues(alpha: 0.5)
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          barber.barberName,
                          style: BBTypography.textTheme.titleMedium?.copyWith(
                            color: colors.text,
                          ),
                        ),
                        if (barber.flaggedForReview) ...[
                          const SizedBox(width: BBSpacing.xs),
                          Icon(AppIcons.flagFill,
                              size: 14, color: BBColors.warning),
                        ],
                      ],
                    ),
                    Text(
                      barber.shopName,
                      style: BBTypography.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(BBRadius.full),
                ),
                child: Text(
                  barber.status,
                  style: BBTypography.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.sm),
          Row(
            children: [
              Icon(AppIcons.starFill, size: 13, color: context.bbColors.accent),
              const SizedBox(width: 3),
              Text(
                barber.averageRating.toStringAsFixed(1),
                style: BBTypography.textTheme.labelSmall
                    ?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(width: BBSpacing.md),
              Icon(AppIcons.calendar,
                  size: 13, color: colors.textTertiary),
              const SizedBox(width: 3),
              Text(
                '${barber.totalBookings} bookings',
                style: BBTypography.textTheme.labelSmall
                    ?.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.sm),
          Row(
            children: [
              BBButton(
                label: isSuspended ? 'Activate' : 'Suspend',
                onPressed: () => _moderate(
                  context,
                  barber.barberId,
                  isSuspended ? 'ACTIVATE' : 'SUSPEND',
                ),
                variant:
                    isSuspended ? BBButtonVariant.secondary : BBButtonVariant.destructive,
                small: true,
                expand: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _moderate(
      BuildContext context, String barberId, String action) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post<void>(
        ApiEndpoints.adminModerationAction,
        body: {
          'targetId': barberId,
          'targetType': 'BARBER',
          'action': action,
          'reason': 'Admin action',
        },
      );
      ref.invalidate(adminBarbersProvider);
      if (context.mounted) {
        showBBSnackbar(context,
            message: 'Action applied', isSuccess: true);
      }
    } catch (e) {
      if (context.mounted) {
        showBBSnackbar(context, message: e.toString(), isError: true);
      }
    }
  }
}

// ─── Live queues tab ──────────────────────────────────────────────────────────

class _QueuesTab extends ConsumerWidget {
  const _QueuesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminQueuesProvider);
    return async.when(
      loading: () => const BBSkeletonListView(),
      error: (e, _) => BBErrorWidget(
        error: e.toString(),
        onRetry: () => ref.invalidate(adminQueuesProvider),
        fullScreen: true,
      ),
      data: (queues) => queues.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.queue,
                      size: 48, color: context.bbColors.textTertiary),
                  const SizedBox(height: BBSpacing.md),
                  Text(
                    'No active queues',
                    style: BBTypography.textTheme.titleMedium?.copyWith(
                      color: context.bbColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: context.bbColors.accent,
              onRefresh: () async => ref.invalidate(adminQueuesProvider),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: BBSpacing.pageHorizontal,
                  vertical: BBSpacing.base,
                ),
                itemCount: queues.length,
                separatorBuilder: (_, _) => const SizedBox(height: BBSpacing.sm),
                itemBuilder: (_, i) => _QueueMonitorCard(queue: queues[i]),
              ),
            ),
    );
  }
}

class _QueueMonitorCard extends StatelessWidget {
  const _QueueMonitorCard({required this.queue});
  final ActiveQueue queue;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(
          color: queue.totalQueued > 10
              ? BBColors.warning.withValues(alpha: 0.5)
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            queue.shopName,
            style: BBTypography.textTheme.titleMedium
                ?.copyWith(color: colors.text, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: BBSpacing.sm),
          Row(
            children: [
              _QueueStat(
                label: 'Queued',
                value: '${queue.totalQueued}',
                color: queue.totalQueued > 10
                    ? BBColors.warning
                    : context.bbColors.accent,
              ),
              const SizedBox(width: BBSpacing.base),
              _QueueStat(
                label: 'Avg Wait',
                value: '${queue.averageWaitTime.toStringAsFixed(0)}m',
                color: BBColors.info,
              ),
              const SizedBox(width: BBSpacing.base),
              _QueueStat(
                label: 'Barbers',
                value: '${queue.activeBarbers}',
                color: BBColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QueueStat extends StatelessWidget {
  const _QueueStat(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: BBTypography.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: BBTypography.textTheme.labelSmall?.copyWith(
            color: colors.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Text(
      title,
      style: BBTypography.textTheme.titleLarge?.copyWith(
        color: colors.text,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
