import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_bottom_nav.dart';

class AdminBookingsScreen extends ConsumerStatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  ConsumerState<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends ConsumerState<AdminBookingsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(adminBookingsProvider);

    return Scaffold(
      backgroundColor: BookBerPalette.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Bookings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: BookBerPalette.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Filter row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: _selectedFilter == 'All',
                      onTap: () => setState(() => _selectedFilter = 'All'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Today',
                      isSelected: _selectedFilter == 'Today',
                      onTap: () => setState(() => _selectedFilter = 'Today'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Upcoming',
                      isSelected: _selectedFilter == 'Upcoming',
                      onTap: () => setState(() => _selectedFilter = 'Upcoming'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Completed',
                      isSelected: _selectedFilter == 'Completed',
                      onTap: () => setState(() => _selectedFilter = 'Completed'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Cancelled',
                      isSelected: _selectedFilter == 'Cancelled',
                      onTap: () => setState(() => _selectedFilter = 'Cancelled'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'No-Show',
                      isSelected: _selectedFilter == 'No-Show',
                      onTap: () => setState(() => _selectedFilter = 'No-Show'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date range picker (placeholder)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: BookBerPalette.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: BookBerPalette.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Select date range',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: BookBerPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Booking list
            Expanded(
              child: bookingsAsync.when(
                data: (bookings) => _BookingList(bookings: bookings),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: BookBerPalette.primaryAccent),
                ),
                error: (_, __) => const Center(
                  child: Text(
                    'Error loading bookings',
                    style: TextStyle(color: BookBerPalette.textSecondary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: 3,
        onTap: (index) {
          // TODO: Navigate to respective screens
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? BookBerPalette.primaryAccent.withValues(alpha: 0.12)
              : BookBerPalette.bgSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? BookBerPalette.primaryAccent : const Color(0x0FFFFFFF),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? BookBerPalette.primaryAccent : BookBerPalette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({required this.bookings});

  final List<AdminBooking> bookings;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _BookingAdminTile(booking: booking);
      },
    );
  }
}

class _BookingAdminTile extends StatelessWidget {
  const _BookingAdminTile({required this.booking});

  final AdminBooking booking;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;

    switch (booking.status) {
      case BookingStatus.confirmed:
        statusColor = BookBerPalette.primaryAccent;
        statusLabel = 'Confirmed';
        break;
      case BookingStatus.inProgress:
        statusColor = BookBerPalette.warningAmber;
        statusLabel = 'In Progress';
        break;
      case BookingStatus.completed:
        statusColor = BookBerPalette.queueSafe;
        statusLabel = 'Completed';
        break;
      case BookingStatus.cancelled:
        statusColor = BookBerPalette.textMuted;
        statusLabel = 'Cancelled';
        break;
      case BookingStatus.noShow:
        statusColor = BookBerPalette.urgentRed;
        statusLabel = 'No-Show';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#${booking.id.split('_').last}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: BookBerPalette.textMuted,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: BookBerPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.shopName,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: BookBerPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${booking.amount}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: BookBerPalette.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.service,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: BookBerPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 14,
                color: BookBerPalette.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDateTime(booking.scheduledAt),
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: BookBerPalette.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.person,
                size: 14,
                color: BookBerPalette.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                booking.barberName,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: BookBerPalette.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
