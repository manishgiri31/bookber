import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_empty_state.dart';
import '../../../core/widgets/bb_loading.dart';
import '../../../core/widgets/bb_status_chip.dart';
import '../../shared/domain/booking_models.dart';
import '../booking/booking_provider.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final async = ref.watch(myBookingsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('My Bookings')),
      body: async.when(
        loading: () => const BBSkeletonListView(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (bookings) => bookings.isEmpty
            ? const BBEmptyState(
                title: 'No bookings yet',
                subtitle: 'Book a barber shop to get started.',
                icon: Icons.calendar_today_rounded,
              )
            : ListView.separated(
                padding:
                    const EdgeInsets.all(BBSpacing.pageHorizontal),
                itemCount: bookings.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: BBSpacing.sm),
                itemBuilder: (ctx, i) =>
                    _BookingCard(booking: bookings[i]),
              ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return GestureDetector(
      onTap: () {
        if (booking.isActive) {
          context.push('/queue/${booking.id}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(BBSpacing.base),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(BBRadius.lg),
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
                Expanded(
                  child: Text(
                    booking.shopName,
                    style: BBTypography.textTheme.titleMedium
                        ?.copyWith(color: colors.text),
                  ),
                ),
                BBStatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: BBSpacing.sm),
            if (booking.serviceNames.isNotEmpty)
              Text(
                booking.serviceNames,
                style: BBTypography.textTheme.bodyMedium
                    ?.copyWith(color: colors.textSecondary),
              ),
            const SizedBox(height: BBSpacing.xs),
            if (booking.scheduledAt != null)
              Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 13, color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d · h:mm a')
                        .format(booking.scheduledAt!.toLocal()),
                    style: BBTypography.textTheme.labelSmall
                        ?.copyWith(color: colors.textTertiary),
                  ),
                ],
              ),
            if (booking.isActive) ...[
              const SizedBox(height: BBSpacing.sm),
              Row(
                children: [
                  Icon(Icons.arrow_forward_rounded,
                      size: 13, color: BBColors.amber),
                  const SizedBox(width: 4),
                  Text(
                    'Track Queue',
                    style: BBTypography.textTheme.labelSmall?.copyWith(
                      color: BBColors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
