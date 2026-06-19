import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../../../core/components/bb_button.dart';
import '../../../core/components/bb_card.dart';
import '../../../core/components/bb_skeleton.dart';
import '../../../core/components/bb_status.dart';
import '../../../core/models/bookber_models.dart';
import '../../../core/network/api_result.dart';
import '../../../core/providers/auth_provider.dart';
import '../providers/barber_providers.dart';
import '../../barber_dashboard/presentation/barber_dashboard_controller.dart';

// ─────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────

class BarberHomeScreen extends ConsumerStatefulWidget {
  const BarberHomeScreen({super.key});

  @override
  ConsumerState<BarberHomeScreen> createState() => _BarberHomeScreenState();
}

class _BarberHomeScreenState extends ConsumerState<BarberHomeScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isOnline = ref.watch(barberStatusProvider);
    final statsAsync = ref.watch(barberStatsProvider);
    final todayBookingsAsync = ref.watch(todayBookingsProvider);
    final firstName = user?.name.split(' ').first ?? 'Barber';

    final colors = context.bbColors;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              greeting: _greeting,
              name: firstName,
              shopName: 'Style Zone',
              isOnline: isOnline,
              onToggleOnline: () async {
                final barberId = user?.id ?? '';
                try {
                  await ref
                      .read(barberStatusProvider.notifier)
                      .toggleStatus(barberId);
                  ref.invalidate(barberStatsProvider);
                } catch (_) {}
              },
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: BBSpacing.px20,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: BBSpacing.px20),

                    // ── Stats row ────────────────────────────
                    statsAsync.when(
                      data: (stats) => _StatsStrip(stats: stats),
                      loading: () => const _StatsStripSkeleton(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: BBSpacing.px24),

                    // ── Now serving ──────────────────────────
                    todayBookingsAsync.when(
                      data: (bookings) {
                        final active = bookings
                            .where((b) =>
                                b.status.toUpperCase() == 'IN_SERVICE')
                            .toList();
                        if (active.isEmpty) {
                          return _ReadyState(
                            onAddWalkIn: () =>
                                context.push('/barber/walkin'),
                          );
                        }
                        return _NowServingCard(booking: active.first);
                      },
                      loading: () => const _NowServingCardSkeleton(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: BBSpacing.px24),

                    // ── Queue preview ────────────────────────
                    todayBookingsAsync.when(
                      data: (bookings) {
                        final queued = bookings
                            .where((b) =>
                                b.status.toUpperCase() == 'QUEUED' ||
                                b.status.toUpperCase() == 'READY' ||
                                b.status.toUpperCase() == 'CALLED')
                            .take(4)
                            .toList();
                        if (queued.isEmpty) return const SizedBox.shrink();
                        return _QueuePreview(bookings: queued);
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: BBSpacing.px24),

                    // ── Quick actions ────────────────────────
                    const _QuickActions(),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.name,
    required this.shopName,
    required this.isOnline,
    required this.onToggleOnline,
  });

  final String greeting;
  final String name;
  final String shopName;
  final bool isOnline;
  final VoidCallback onToggleOnline;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        BBSpacing.px20,
        BBSpacing.px16,
        BBSpacing.px20,
        BBSpacing.px16,
      ),
      decoration: BoxDecoration(
        color: colors.bgCanvas,
        border: Border(
          bottom: BorderSide(color: colors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $name',
                  style: BBTypography.displayS,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: BBSpacing.px4),
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: BBIconSize.xs,
                      color: BBColors.textDisabled,
                    ),
                    const SizedBox(width: BBSpacing.px4),
                    Text(shopName, style: BBTypography.bodyS),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: BBSpacing.px12),
          GestureDetector(
            onTap: onToggleOnline,
            child: AnimatedContainer(
              duration: BBMotion.normal,
              curve: BBMotion.smooth,
              padding: const EdgeInsets.symmetric(
                horizontal: BBSpacing.px14,
                vertical: BBSpacing.px8,
              ),
              decoration: BoxDecoration(
                color: isOnline
                    ? BBColors.successDim
                    : BBColors.errorDim,
                borderRadius: BBRadius.pill,
                border: Border.all(
                  color: isOnline ? BBColors.success : BBColors.error,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BBPulse(
                    color: isOnline ? BBColors.success : BBColors.error,
                    size: 6,
                  ),
                  const SizedBox(width: BBSpacing.px8),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: BBTypography.labelM.copyWith(
                      color: isOnline ? BBColors.success : BBColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATS STRIP — horizontal scroll, 4 metrics
// ─────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.stats});

  final BarberStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        label: 'Today',
        value: stats.todayBookings.toString(),
        sub: 'bookings',
        color: BBColors.brandPrimary,
        icon: Icons.calendar_today_outlined,
      ),
      _StatItem(
        label: 'Queue',
        value: stats.inQueue.toString(),
        sub: 'waiting',
        color: BBColors.warning,
        icon: Icons.people_outline,
      ),
      _StatItem(
        label: 'Revenue',
        value: '₹${stats.todayRevenue.toStringAsFixed(0)}',
        sub: 'today',
        color: BBColors.success,
        icon: Icons.payments_outlined,
      ),
      _StatItem(
        label: 'Rating',
        value: stats.avgRating.toStringAsFixed(1),
        sub: 'avg',
        color: BBColors.warning,
        icon: Icons.star_outline_rounded,
      ),
    ];

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: BBSpacing.px12),
        itemBuilder: (_, i) => _StatChip(item: items[i]),
      ),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.item});
  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      width: 110,
      padding: const EdgeInsets.all(BBSpacing.px14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BBRadius.card,
        border: Border.all(color: colors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(item.icon, size: BBIconSize.sm, color: item.color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: BBTypography.displayS.copyWith(
                  color: item.color,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                item.sub,
                style: BBTypography.labelS,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsStripSkeleton extends StatelessWidget {
  const _StatsStripSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: BBSpacing.px12),
        itemBuilder: (_, __) => const BBSkeleton(
          width: 110,
          height: 92,
          borderRadius: BBRadius.card,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOW SERVING CARD
// ─────────────────────────────────────────────────────────────

class _NowServingCard extends ConsumerWidget {
  const _NowServingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    return BBCard(
      padding: EdgeInsets.zero,
      color: colors.bgSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent bar + status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: BBSpacing.px16,
              vertical: BBSpacing.px12,
            ),
            decoration: BoxDecoration(
              color: BBColors.brandPrimary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(BBRadius.r20),
                topRight: Radius.circular(BBRadius.r20),
              ),
            ),
            child: Row(
              children: [
                BBPulse(color: BBColors.brandPrimary, size: 6),
                const SizedBox(width: BBSpacing.px8),
                Text(
                  'Now Serving',
                  style: BBTypography.labelM.copyWith(
                    color: BBColors.brandPrimary,
                  ),
                ),
                const Spacer(),
                if (booking.chairLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BBSpacing.px10,
                      vertical: BBSpacing.px4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.bgElevated,
                      borderRadius: BBRadius.pill,
                    ),
                    child: Text(
                      'Chair ${booking.chairLabel}',
                      style: BBTypography.labelS,
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(BBSpacing.px16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer row
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: BBColors.brandPrimaryDim,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _initial(booking.customerName),
                          style: BBTypography.headingL.copyWith(
                            color: BBColors.brandPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: BBSpacing.px12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.customerName.isNotEmpty
                                ? booking.customerName
                                : 'Customer',
                            style: BBTypography.headingM,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: BBSpacing.px2),
                          Text(
                            booking.serviceName.isNotEmpty
                                ? booking.serviceName
                                : booking.services
                                    .map((s) => s.name)
                                    .join(' + '),
                            style: BBTypography.bodyS,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _ElapsedTimer(startedAt: booking.scheduledAt),
                  ],
                ),

                const SizedBox(height: BBSpacing.px16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: BBButton(
                        label: 'Complete',
                        size: BBButtonSize.medium,
                        icon: Icons.check_circle_outline_rounded,
                        onPressed: () async {
                          try {
                            final res = await ref
                                .read(barberDashboardControllerProvider.notifier)
                                .updateQueueEntryStatus(booking.id, 'completed');
                            if (res is ApiSuccess<void>) {
                              ref.invalidate(barberStatsProvider);
                              ref.invalidate(barberQueueProvider);
                            }
                          } catch (_) {}
                        },
                      ),
                    ),
                    const SizedBox(width: BBSpacing.px10),
                    Expanded(
                      child: BBButton.secondary(
                        label: 'No-show',
                        size: BBButtonSize.medium,
                        onPressed: () async {
                          try {
                            await ref
                                .read(barberDashboardControllerProvider.notifier)
                                .updateQueueEntryStatus(booking.id, 'NO_SHOW');
                          } catch (_) {}
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initial(String name) =>
      name.isNotEmpty ? name.trim()[0].toUpperCase() : 'C';
}

class _NowServingCardSkeleton extends StatelessWidget {
  const _NowServingCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const BBSkeleton(width: double.infinity, height: 160);
  }
}

// ─────────────────────────────────────────────────────────────
// READY STATE — no active booking
// ─────────────────────────────────────────────────────────────

class _ReadyState extends ConsumerWidget {
  const _ReadyState({required this.onAddWalkIn});
  final VoidCallback onAddWalkIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BBCard(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: BBColors.successDim,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: BBIconSize.xl,
              color: BBColors.success,
            ),
          ),
          const SizedBox(height: BBSpacing.px14),
          const Text('Ready for next customer', style: BBTypography.headingM),
          const SizedBox(height: BBSpacing.px6),
          const Text(
            'No active service. Call the next person or add a walk-in.',
            style: BBTypography.bodyM,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BBSpacing.px20),
          Row(
            children: [
              Expanded(
                child: BBButton(
                  label: 'Add Walk-in',
                  size: BBButtonSize.medium,
                  icon: Icons.person_add_outlined,
                  onPressed: onAddWalkIn,
                ),
              ),
              const SizedBox(width: BBSpacing.px10),
              Expanded(
                child: BBButton.secondary(
                  label: 'Call Next',
                  size: BBButtonSize.medium,
                  onPressed: () async {
                    final queue = ref.read(barberQueueProvider).valueOrNull ?? [];
                    final next = queue
                        .where((e) => e.status == QueueStatus.waiting)
                        .toList();
                    if (next.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No customers waiting in queue')),
                      );
                      return;
                    }
                    try {
                      await ref
                          .read(barberDashboardControllerProvider.notifier)
                          .updateQueueEntryStatus(next.first.id, 'CALLED');
                    } catch (_) {}
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// QUEUE PREVIEW — next 4 bookings
// ─────────────────────────────────────────────────────────────

class _QueuePreview extends StatelessWidget {
  const _QueuePreview({required this.bookings});
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Up Next', style: BBTypography.headingM),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/barber/queue'),
              child: Text(
                'Full queue',
                style: BBTypography.labelM.copyWith(
                  color: BBColors.brandPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: BBSpacing.px12),
        ...bookings.asMap().entries.map((e) {
          return _QueueItem(
            position: e.key + 1,
            booking: e.value,
          );
        }),
      ],
    );
  }
}

class _QueueItem extends StatelessWidget {
  const _QueueItem({required this.position, required this.booking});
  final int position;
  final Booking booking;

  static Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'READY':
        return BBColors.brandPrimary;
      case 'CALLED':
        return BBColors.warning;
      default:
        return BBColors.textDisabled;
    }
  }

  static String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'READY':
        return 'Ready';
      case 'CALLED':
        return 'Called';
      default:
        return 'Waiting';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(booking.status);
    final colors = context.bbColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: BBSpacing.px8),
      child: BBCard(
        padding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.px14,
          vertical: BBSpacing.px12,
        ),
        child: Row(
          children: [
            // Position number
            SizedBox(
              width: 28,
              child: Text(
                '#$position',
                style: BBTypography.numericM.copyWith(
                  fontSize: 16,
                  color: colors.textDisabled,
                ),
              ),
            ),
            const SizedBox(width: BBSpacing.px10),

            // Customer avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.bgElevated,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  booking.customerName.isNotEmpty
                      ? booking.customerName.trim()[0].toUpperCase()
                      : '?',
                  style: BBTypography.labelM.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: BBSpacing.px10),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.customerName.isNotEmpty
                        ? booking.customerName
                        : 'Customer',
                    style: BBTypography.headingS,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    booking.serviceName,
                    style: BBTypography.bodyS,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Status pill
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: BBSpacing.px8,
                vertical: BBSpacing.px4,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BBRadius.pill,
              ),
              child: Text(
                _statusLabel(booking.status),
                style: BBTypography.labelS.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// QUICK ACTIONS
// ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: BBTypography.headingM),
        const SizedBox(height: BBSpacing.px12),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.person_add_outlined,
                label: 'Add Walk-in',
                onTap: () => context.push('/barber/walkin'),
              ),
            ),
            const SizedBox(width: BBSpacing.px10),
            Expanded(
              child: _ActionTile(
                icon: Icons.block_outlined,
                label: 'Block Slot',
                onTap: () {},
              ),
            ),
            const SizedBox(width: BBSpacing.px10),
            Expanded(
              child: _ActionTile(
                icon: Icons.bar_chart_outlined,
                label: 'Earnings',
                onTap: () => context.push('/barber/earnings'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BBCard(
        padding: const EdgeInsets.symmetric(
          vertical: BBSpacing.px16,
          horizontal: BBSpacing.px8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: BBIconSize.lg, color: BBColors.brandPrimary),
            const SizedBox(height: BBSpacing.px8),
            Text(
              label,
              style: BBTypography.labelS.copyWith(
                color: context.bbColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ELAPSED TIMER — counts up from service start
// ─────────────────────────────────────────────────────────────

class _ElapsedTimer extends StatefulWidget {
  const _ElapsedTimer({this.startedAt});
  final DateTime? startedAt;

  @override
  State<_ElapsedTimer> createState() => _ElapsedTimerState();
}

class _ElapsedTimerState extends State<_ElapsedTimer> {
  late int _elapsedSeconds;

  @override
  void initState() {
    super.initState();
    _update();
    _tick();
  }

  void _update() {
    final start = widget.startedAt ?? DateTime.now();
    _elapsedSeconds = DateTime.now().difference(start).inSeconds.clamp(0, 9999);
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(_update);
      _tick();
    });
  }

  String get _formatted {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final isOverrun = _elapsedSeconds > 45 * 60;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpacing.px10,
        vertical: BBSpacing.px6,
      ),
      decoration: BoxDecoration(
        color: isOverrun ? BBColors.errorDim : colors.bgElevated,
        borderRadius: BBRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: BBIconSize.xs,
            color: isOverrun ? BBColors.error : colors.textSecondary,
          ),
          const SizedBox(width: BBSpacing.px4),
          Text(
            _formatted,
            style: BBTypography.labelM.copyWith(
              fontFamily: 'Satoshi',
              color: isOverrun ? BBColors.error : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
