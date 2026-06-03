import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import '../../../core/models/bookber_models.dart';
import '../../../core/network/api_result.dart';
import '../../../core/providers/auth_provider.dart';
import '../providers/barber_providers.dart';
import '../../barber_dashboard/presentation/barber_dashboard_controller.dart';
import '../widgets/barber_bottom_nav.dart';

class BarberHomeScreen extends ConsumerStatefulWidget {
  const BarberHomeScreen({super.key});

  @override
  ConsumerState<BarberHomeScreen> createState() => _BarberHomeScreenState();
}

class _BarberHomeScreenState extends ConsumerState<BarberHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(barberStatusProvider);
    final statsAsync = ref.watch(barberStatsProvider);
    final todayBookingsAsync = ref.watch(todayBookingsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: BookBerPalette.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hey, Aasmaan ✂️',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: BookBerPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Style Zone, Ludhiana',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: BookBerPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Online/Offline toggle
                  GestureDetector(
                    onTap: () async {
                      final user = ref.read(currentUserProvider);
                      final barberId = user?.id ?? '';
                      try {
                        await ref.read(barberStatusProvider.notifier).toggleStatus(barberId);
                        ref.invalidate(barberStatsProvider);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? BookBerPalette.queueSafe.withValues(alpha: 0.12)
                            : BookBerPalette.urgentRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isOnline ? BookBerPalette.queueSafe : BookBerPalette.urgentRed,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isOnline ? BookBerPalette.queueSafe : BookBerPalette.urgentRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isOnline ? BookBerPalette.queueSafe : BookBerPalette.urgentRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Row
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      statsAsync.when(
                        data: (stats) => _StatsRow(stats: stats),
                        loading: () => const _StatsLoading(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    const SizedBox(height: 24),

                    // Active Booking Card
                    todayBookingsAsync.when(
                      data: (list) {
                        final active = list.firstWhere(
                          (b) => b.status.toLowerCase() == 'in_service' || b.status.toLowerCase() == 'in_service',
                          orElse: () => null as Booking,
                        );
                        if (active == null) return const SizedBox.shrink();
                        return _ActiveBookingCardLive(booking: active);
                      },
                      loading: () => const _ActiveBookingCard(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),

                    // Today's Schedule
                    const _TodayScheduleSection(),
                    const SizedBox(height: 24),

                    // Quick Actions
                    const _QuickActionsRow(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BarberBottomNav(
        currentIndex: 0,
        onTap: (index) {
          // TODO: Navigate to respective screens
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final BarberStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          label: 'Today\'s Bookings',
          value: stats.todayBookings.toString(),
          color: BookBerPalette.primaryAccent,
        ),
        _StatCard(
          label: 'In Queue',
          value: stats.inQueue.toString(),
          color: BookBerPalette.primaryAccent,
        ),
        _StatCard(
          label: 'Today\'s Revenue',
          value: '₹${stats.todayRevenue}',
          color: BookBerPalette.queueSafe,
        ),
        _StatCard(
          label: 'Avg Rating',
          value: '${stats.avgRating} ⭐',
          color: BookBerPalette.warningAmber,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: BookBerPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: List.generate(4, (_) => _StatCardSkeleton()),
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: BookBerPalette.bgElevated,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 24,
            decoration: BoxDecoration(
              color: BookBerPalette.bgElevated,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBookingCard extends StatelessWidget {
  const _ActiveBookingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: BookBerPalette.primaryAccent,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: BookBerPalette.primaryAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Currently Serving',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: BookBerPalette.primaryAccent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: BookBerPalette.bgElevated,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ravi Kumar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: BookBerPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Haircut + Beard Trim',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: BookBerPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 16,
                color: BookBerPalette.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Started 10 min ago · 20 min elapsed',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: BookBerPalette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Complete service
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BookBerPalette.primaryAccent,
                    foregroundColor: BookBerPalette.bgPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Complete Service',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Add service
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BookBerPalette.textPrimary,
                    side: BorderSide(color: const Color(0x0FFFFFFF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    'Add Service',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveBookingCardLive extends ConsumerWidget {
  const _ActiveBookingCardLive({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: BookBerPalette.primaryAccent,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: BookBerPalette.primaryAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Currently Serving',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: BookBerPalette.primaryAccent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: BookBerPalette.bgElevated,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName ?? booking.barberName ?? 'Customer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: BookBerPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.services.isNotEmpty ? booking.services.map((s) => s.name).join(', ') : booking.serviceName ?? '',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: BookBerPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 16,
                color: BookBerPalette.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                booking.scheduledAt != null ? 'Started · ${booking.estimatedWaitMinutes} min elapsed' : 'In service',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: BookBerPalette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final entryId = booking.id;
                    try {
                      final res = await ref.read(barberDashboardControllerProvider.notifier).updateQueueEntryStatus(entryId, 'completed');
                      if (res is ApiSuccess<void>) {
                        ref.invalidate(barberStatsProvider);
                        ref.invalidate(barberQueueProvider);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service completed')));
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BookBerPalette.primaryAccent,
                    foregroundColor: BookBerPalette.bgPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Complete Service',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BookBerPalette.textPrimary,
                    side: BorderSide(color: const Color(0x0FFFFFFF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    'Add Service',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayScheduleSection extends StatelessWidget {
  const _TodayScheduleSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Schedule',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BookBerPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _TimelineBookingTile(
          time: '11:00 AM',
          customerName: 'Vikram Singh',
          service: 'Fade',
          status: BookingStatus.inProgress,
        ),
        _TimelineBookingTile(
          time: '12:00 PM',
          customerName: 'Mohit Sharma',
          service: 'Haircut',
          status: BookingStatus.confirmed,
        ),
        _TimelineBookingTile(
          time: '2:00 PM',
          customerName: 'Rajesh Kumar',
          service: 'Hair Color',
          status: BookingStatus.confirmed,
        ),
      ],
    );
  }
}

class _TimelineBookingTile extends StatelessWidget {
  const _TimelineBookingTile({
    required this.time,
    required this.customerName,
    required this.service,
    required this.status,
  });

  final String time;
  final String customerName;
  final String service;
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 70,
            child: Text(
              time,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BookBerPalette.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Customer + Service
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BookBerPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                color: BookBerPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          _StatusBadge(status: status),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case BookingStatus.confirmed:
        color = BookBerPalette.primaryAccent;
        label = 'Confirmed';
        break;
      case BookingStatus.inProgress:
        color = BookBerPalette.warningAmber;
        label = 'In Progress';
        break;
      case BookingStatus.completed:
        color = BookBerPalette.queueSafe;
        label = 'Completed';
        break;
      case BookingStatus.noShow:
        color = BookBerPalette.urgentRed;
        label = 'No-Show';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Add walk-in
            },
            icon: const Icon(Icons.person_add_outlined, size: 20),
            label: Text(
              'Add Walk-in',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: BookBerPalette.textPrimary,
              side: BorderSide(color: const Color(0x0FFFFFFF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Block slot
            },
            icon: const Icon(Icons.block_outlined, size: 20),
            label: Text(
              'Block Slot',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: BookBerPalette.textPrimary,
              side: BorderSide(color: const Color(0x0FFFFFFF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: () {
            // TODO: View earnings
          },
          child: Text(
            'View Earnings',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: BookBerPalette.primaryAccent,
            ),
          ),
        ),
      ],
    );
  }
}
