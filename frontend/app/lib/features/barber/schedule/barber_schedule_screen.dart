import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import '../../../core/providers/auth_provider.dart';
import '../providers/barber_providers.dart';
import '../../../core/models/bookber_models.dart';
import '../../barber_dashboard/presentation/barber_dashboard_controller.dart';
import '../widgets/barber_bottom_nav.dart';

class BarberScheduleScreen extends ConsumerStatefulWidget {
  const BarberScheduleScreen({super.key});

  @override
  ConsumerState<BarberScheduleScreen> createState() => _BarberScheduleScreenState();
}

class _BarberScheduleScreenState extends ConsumerState<BarberScheduleScreen> {
  String _selectedDay = 'Today';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BookBerPalette.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Week View Header
            _WeekViewHeader(
              selectedDay: _selectedDay,
              onDaySelected: (day) => setState(() => _selectedDay = day),
            ),
            const SizedBox(height: 24),

            // Time Grid
            Expanded(
              child: _TimeGrid(selectedDay: _selectedDay),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWorkingHoursSheet(context),
        backgroundColor: BookBerPalette.primaryAccent,
        foregroundColor: BookBerPalette.bgPrimary,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BarberBottomNav(
        currentIndex: 2,
        onTap: (index) {
          // TODO: Navigate to respective screens
        },
      ),
    );
  }

  void _showWorkingHoursSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BookBerPalette.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _WorkingHoursSheet(),
    );
  }
}

class _WeekViewHeader extends StatelessWidget {
  const _WeekViewHeader({
    required this.selectedDay,
    required this.onDaySelected,
  });

  final String selectedDay;
  final ValueChanged<String> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final days = ['Today', 'Tomorrow', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day == selectedDay;

          return Padding(
            padding: EdgeInsets.only(right: index < days.length - 1 ? 12 : 0),
            child: GestureDetector(
              onTap: () => onDaySelected(day),
              child: Container(
                width: 70,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? BookBerPalette.primaryAccent
                      : BookBerPalette.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      day,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? BookBerPalette.bgPrimary
                            : BookBerPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${5 + index}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? BookBerPalette.bgPrimary
                            : BookBerPalette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimeGrid extends ConsumerWidget {
  const _TimeGrid({required this.selectedDay});

  final String selectedDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(barberScheduleProvider(selectedDay));

    return scheduleAsync.when(
      data: (bookings) => _TimeGridContent(bookings: bookings),
      loading: () => const Center(
        child: CircularProgressIndicator(color: BookBerPalette.primaryAccent),
      ),
      error: (_, __) => const Center(
        child: Text(
          'Error loading schedule',
          style: TextStyle(color: BookBerPalette.textSecondary),
        ),
      ),
    );
  }
}

class _TimeGridContent extends StatelessWidget {
  const _TimeGridContent({required this.bookings});

  final List<BookingSlot> bookings;

  @override
  Widget build(BuildContext context) {
    final hours = List.generate(12, (index) => '${9 + index}:00 ${index < 3 ? 'AM' : 'PM'}');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: hours.length,
      itemBuilder: (context, index) {
        final time = hours[index];
        final booking = index < bookings.length ? bookings[index] : null;

        return _TimeSlotRow(
          time: time,
          booking: index < bookings.length ? booking : null,
          onTap: () {
            if (booking != null) {
              _showBookingDetailModal(context, booking);
            }
          },
        );
      },
    );
  }

  void _showBookingDetailModal(BuildContext context, BookingSlot booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BookBerPalette.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _BookingDetailModal(booking: booking),
    );
  }
}

class _TimeSlotRow extends StatelessWidget {
  const _TimeSlotRow({
    required this.time,
    required this.booking,
    required this.onTap,
  });

  final String time;
  final BookingSlot? booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Time label
          SizedBox(
            width: 60,
            child: Text(
              time,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: BookBerPalette.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Booking block or available slot
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: booking == null
                  ? _AvailableSlot()
                  : _BookingBlock(booking: booking!),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingBlock extends StatelessWidget {
  const _BookingBlock({required this.booking});

  final BookingSlot booking;

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
      case BookingStatus.noShow:
        statusColor = BookBerPalette.urgentRed;
        statusLabel = 'No-Show';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.customerName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: BookBerPalette.textPrimary,
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
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${booking.price}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
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
        ],
      ),
    );
  }
}

class _AvailableSlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BookBerPalette.bgElevated.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x0FFFFFFF),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          'Available',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: BookBerPalette.textMuted,
          ),
        ),
      ),
    );
  }
}

class _BookingDetailModal extends StatelessWidget {
  const _BookingDetailModal({required this.booking});

  final BookingSlot booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: BookBerPalette.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Booking Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: BookBerPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // Customer info
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: BookBerPalette.bgElevated,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: BookBerPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.service,
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
          const SizedBox(height: 24),

          // Time and price
          Row(
            children: [
              Expanded(
                child: _DetailItem(
                  label: 'Time',
                  value: booking.time,
                ),
              ),
              Expanded(
                child: _DetailItem(
                  label: 'Duration',
                  value: '${booking.duration} min',
                ),
              ),
              Expanded(
                child: _DetailItem(
                  label: 'Price',
                  value: '₹${booking.price}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Call customer
                  },
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: Text(
                    'Call',
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
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Mark complete
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
                    'Complete',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                // TODO: Cancel booking
              },
              child: Text(
                'Cancel Booking',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BookBerPalette.urgentRed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: BookBerPalette.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: BookBerPalette.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _WorkingHoursSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: BookBerPalette.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Add Working Hours',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: BookBerPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // Day multi-select
          Text(
            'Select Days',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: BookBerPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
              return _DayChip(day: day);
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Time pickers
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BookBerPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: BookBerPalette.bgElevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          '9:00 AM',
                          style: TextStyle(color: BookBerPalette.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'End Time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BookBerPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: BookBerPalette.bgElevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          '8:00 PM',
                          style: TextStyle(color: BookBerPalette.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Save basic working hours for all days (wired)
                final user = ProviderScope.containerOf(context).read(currentUserProvider);
                final barberId = user?.id ?? '';
                final hours = [
                  for (final d in ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'])
                    WorkingHour(day: d, startTime: '09:00', endTime: '20:00', isActive: true),
                ];
                if (barberId.isNotEmpty) {
                  ProviderScope.containerOf(context).read(barberDashboardControllerProvider.notifier).saveWorkingHours(barberId, hours).then((res) {
                    ProviderScope.containerOf(context).read(workingHoursProvider);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Working hours saved')));
                  }).catchError((e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
                  });
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
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatefulWidget {
  const _DayChip({required this.day});

  final String day;

  @override
  State<_DayChip> createState() => _DayChipState();
}

class _DayChipState extends State<_DayChip> {
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isSelected = !_isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _isSelected
              ? BookBerPalette.primaryAccent.withValues(alpha: 0.12)
              : BookBerPalette.bgElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _isSelected ? BookBerPalette.primaryAccent : const Color(0x0FFFFFFF),
            width: 1,
          ),
        ),
        child: Text(
          widget.day,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _isSelected ? BookBerPalette.primaryAccent : BookBerPalette.textSecondary,
          ),
        ),
      ),
    );
  }
}
