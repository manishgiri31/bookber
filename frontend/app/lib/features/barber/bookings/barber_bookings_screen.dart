import 'package:flutter/material.dart';
import '../../../core/design/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/bb_empty_state.dart';
import '../../../core/widgets/bb_loading.dart';
import '../../../core/widgets/bb_snackbar.dart';
import '../../../core/widgets/bb_status_chip.dart';
import '../../shared/domain/booking_models.dart';
import '../dashboard/barber_provider.dart';

final _barberBookingsProvider =
    FutureProvider.autoDispose<List<Booking>>((ref) async {
  final api = ref.watch(apiClientProvider);
  // .select() narrows the dependency to just the barber ID, so toggling
  // availability/break or refreshing queue/stats doesn't trigger a
  // redundant refetch of bookings every time the dashboard state changes.
  final barberId = ref.watch(barberDashProvider.select((s) => s.profile?.id));
  if (barberId == null) return [];
  try {
    final data = await api.get<Map<String, dynamic>>(
      ApiEndpoints.barberBookings(barberId),
    );
    final list = data['bookings'] as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Booking.fromJson)
        .toList();
  } catch (_) {
    return [];
  }
});

class BarberBookingsScreen extends ConsumerStatefulWidget {
  const BarberBookingsScreen({super.key});

  @override
  ConsumerState<BarberBookingsScreen> createState() =>
      _BarberBookingsScreenState();
}

class _BarberBookingsScreenState extends ConsumerState<BarberBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final async = ref.watch(_barberBookingsProvider);

    final bookings = async.valueOrNull ?? [];
    final upcoming = bookings
        .where((b) => ['QUEUED', 'READY', 'CALLED'].contains(b.status))
        .toList();
    final active = bookings
        .where((b) => b.status == 'IN_SERVICE')
        .toList();
    final past = bookings
        .where((b) => ['COMPLETED', 'CANCELLED', 'NO_SHOW'].contains(b.status))
        .toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Bookings'),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.refresh),
            onPressed: () => ref.invalidate(_barberBookingsProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: context.bbColors.accent,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: context.bbColors.accent,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(text: 'Upcoming (${upcoming.length})'),
            Tab(text: 'Active (${active.length})'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: async.when(
        loading: () => const BBSkeletonListView(),
        error: (_, _) => BBEmptyState(
          title: 'Couldn\'t load bookings',
          subtitle: 'Pull to retry.',
          icon: AppIcons.calendar,
        ),
        data: (_) => TabBarView(
          controller: _tab,
          children: [
            _BookingList(
              bookings: upcoming,
              emptyTitle: 'No upcoming bookings',
              emptySubtitle: 'Upcoming appointments will appear here.',
              ref: ref,
            ),
            _BookingList(
              bookings: active,
              emptyTitle: 'No active service',
              emptySubtitle: 'In-service appointments appear here.',
              ref: ref,
            ),
            _BookingList(
              bookings: past,
              emptyTitle: 'No past bookings',
              emptySubtitle: 'Completed and cancelled bookings appear here.',
              ref: ref,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.bookings,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.ref,
  });
  final List<Booking> bookings;
  final String emptyTitle;
  final String emptySubtitle;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return BBEmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
        icon: AppIcons.calendar,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      itemCount: bookings.length,
      separatorBuilder: (_, _) => const SizedBox(height: BBSpacing.sm),
      itemBuilder: (ctx, i) =>
          _BookingCard(booking: bookings[i], ref: ref),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.ref});
  final Booking booking;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final isActive = booking.isActive;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(
          color: isActive
              ? context.bbColors.accent.withValues(alpha: 0.4)
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
                    Text(
                      booking.shopName.isNotEmpty
                          ? booking.shopName
                          : 'Customer',
                      style: BBTypography.textTheme.titleMedium
                          ?.copyWith(color: colors.text),
                    ),
                    if (booking.serviceNames.isNotEmpty)
                      Text(
                        booking.serviceNames,
                        style: BBTypography.textTheme.bodySmall
                            ?.copyWith(color: colors.textSecondary),
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
                Icon(AppIcons.schedule,
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
          ],
          if (booking.totalAmount > 0) ...[
            const SizedBox(height: BBSpacing.sm),
            Row(
              children: [
                Icon(AppIcons.currencyRupee,
                    size: 13, color: colors.textTertiary),
                Text(
                  booking.totalAmount.toStringAsFixed(0),
                  style: BBTypography.textTheme.labelSmall
                      ?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ],
          if (booking.status == 'IN_SERVICE') ...[
            const SizedBox(height: BBSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _completeBooking(context),
                icon: const Icon(AppIcons.check, size: 16),
                label: const Text('Mark Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BBColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  minimumSize: Size.zero,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _completeBooking(BuildContext context) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post<void>(
        ApiEndpoints.completeService(booking.id),
        body: {},
      );
      ref.invalidate(_barberBookingsProvider);
      if (context.mounted) {
        showBBSnackbar(context, message: 'Booking completed', isSuccess: true);
      }
    } catch (e) {
      if (context.mounted) {
        showBBSnackbar(context, message: e.toString(), isError: true);
      }
    }
  }
}
