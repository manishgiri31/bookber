import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_empty_state.dart';
import '../../../core/widgets/bb_loading.dart';
import '../../../core/widgets/bb_snackbar.dart';
import '../../../core/widgets/bb_status_chip.dart';
import '../../shared/domain/booking_models.dart';
import '../booking/booking_provider.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final async = ref.watch(myBookingsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tab,
          labelColor: colors.text,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: BBColors.amber,
          indicatorSize: TabBarIndicatorSize.label,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: async.when(
        loading: () => const BBSkeletonListView(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (bookings) {
          final all = bookings;
          final upcoming = bookings
              .where((b) => b.isActive || b.status == 'CONFIRMED' || b.status == 'PENDING')
              .toList();
          final completed = bookings.where((b) => b.status == 'COMPLETED').toList();
          final cancelled = bookings
              .where((b) => b.status == 'CANCELLED' || b.status == 'NO_SHOW')
              .toList();

          return TabBarView(
            controller: _tab,
            children: [
              _BookingList(bookings: all),
              _BookingList(bookings: upcoming, emptyTitle: 'No upcoming bookings'),
              _BookingList(bookings: completed, emptyTitle: 'No completed bookings yet'),
              _BookingList(bookings: cancelled, emptyTitle: 'No cancellations'),
            ],
          );
        },
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({required this.bookings, this.emptyTitle});
  final List<Booking> bookings;
  final String? emptyTitle;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return BBEmptyState(
        title: emptyTitle ?? 'No bookings yet',
        subtitle: 'Book a barber shop to get started.',
        icon: Icons.calendar_today_rounded,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      itemCount: bookings.length,
      separatorBuilder: (_, _) => const SizedBox(height: BBSpacing.sm),
      itemBuilder: (ctx, i) => _BookingCard(booking: bookings[i]),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  const _BookingCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final isCompleted = booking.status == 'COMPLETED';
    final isCancelled =
        booking.status == 'CANCELLED' || booking.status == 'NO_SHOW';

    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.xl),
        border: Border.all(
          color: booking.isActive
              ? BBColors.amber.withValues(alpha: 0.4)
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCancelled
                      ? colors.surfaceVariant
                      : isCompleted
                          ? BBColors.success.withValues(alpha: 0.12)
                          : BBColors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(BBRadius.md),
                ),
                child: Icon(
                  isCancelled
                      ? Icons.cancel_outlined
                      : isCompleted
                          ? Icons.check_circle_outline_rounded
                          : Icons.content_cut_rounded,
                  size: 20,
                  color: isCancelled
                      ? colors.textTertiary
                      : isCompleted
                          ? BBColors.success
                          : BBColors.amber,
                ),
              ),
              const SizedBox(width: BBSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.shopName,
                      style: BBTypography.textTheme.titleMedium?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (booking.serviceNames.isNotEmpty)
                      Text(
                        booking.serviceNames,
                        style: BBTypography.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              BBStatusChip(status: booking.status),
            ],
          ),
          if (booking.scheduledAt != null) ...[
            const SizedBox(height: BBSpacing.sm),
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 13, color: colors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy · h:mm a')
                      .format(booking.scheduledAt!.toLocal()),
                  style: BBTypography.textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: BBSpacing.md),
          // ── Actions ────────────────────────────────────────────────────
          Row(
            children: [
              if (booking.isActive)
                Expanded(
                  child: _ActionChip(
                    label: 'Track Queue',
                    icon: Icons.queue_rounded,
                    color: BBColors.amber,
                    onTap: () => context.push('/queue/${booking.id}'),
                  ),
                ),
              if (isCompleted) ...[
                Expanded(
                  child: _ActionChip(
                    label: 'Review',
                    icon: Icons.star_outline_rounded,
                    color: BBColors.amber,
                    onTap: () => context.push('/review/${booking.id}'),
                  ),
                ),
                const SizedBox(width: BBSpacing.sm),
              ],
              if (isCompleted || isCancelled)
                Expanded(
                  child: _ActionChip(
                    label: 'Book Again',
                    icon: Icons.refresh_rounded,
                    color: BBColors.info,
                    onTap: () =>
                        context.push('/shops/${booking.shopId}/book'),
                  ),
                ),
              if (isCompleted) ...[
                const SizedBox(width: BBSpacing.sm),
                Expanded(
                  child: _ActionChip(
                    label: 'Invoice',
                    icon: Icons.receipt_outlined,
                    color: colors.textSecondary,
                    onTap: () => showBBSnackbar(context,
                        message: 'Invoice download coming soon!'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(BBRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: BBTypography.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
