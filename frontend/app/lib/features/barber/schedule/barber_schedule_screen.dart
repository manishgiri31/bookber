import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../../../core/models/bookber_models.dart';
import '../../../core/providers/auth_provider.dart';
import '../providers/barber_providers.dart';
import '../../barber_dashboard/presentation/barber_dashboard_controller.dart';

class BarberScheduleScreen extends ConsumerStatefulWidget {
  const BarberScheduleScreen({super.key});

  @override
  ConsumerState<BarberScheduleScreen> createState() =>
      _BarberScheduleScreenState();
}

class _BarberScheduleScreenState extends ConsumerState<BarberScheduleScreen> {
  String _selectedDay = 'Today';

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  BBSpacing.px20, BBSpacing.px20, BBSpacing.px20, 0),
              child: Row(
                children: [
                  Text('Schedule',
                      style: BBTypography.displayS
                          .copyWith(color: colors.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: BBSpacing.px16),
            _WeekViewHeader(
              selectedDay: _selectedDay,
              onDaySelected: (day) => setState(() => _selectedDay = day),
            ),
            const SizedBox(height: BBSpacing.px16),
            Expanded(child: _TimeGrid(selectedDay: _selectedDay)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWorkingHoursSheet(context),
        backgroundColor: BBColors.brandPrimary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showWorkingHoursSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _WorkingHoursSheet(),
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
    final colors = context.bbColors;
    final days = ['Today', 'Tomorrow', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day == selectedDay;

          return Padding(
            padding: EdgeInsets.only(
                right: index < days.length - 1 ? BBSpacing.px12 : 0),
            child: GestureDetector(
              onTap: () => onDaySelected(day),
              child: Container(
                width: 70,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected ? BBColors.brandPrimary : colors.bgSurface,
                  borderRadius: BBRadius.md,
                  border: isSelected
                      ? null
                      : Border.all(color: colors.borderSubtle),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      day,
                      style: BBTypography.caption.copyWith(
                        color: isSelected ? Colors.white : colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: BBSpacing.px4),
                    Text(
                      '${5 + index}',
                      style: BBTypography.headingM.copyWith(
                        color:
                            isSelected ? Colors.white : colors.textPrimary,
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
    final colors = context.bbColors;
    final scheduleAsync = ref.watch(barberScheduleProvider(selectedDay));

    return scheduleAsync.when(
      data: (bookings) => _TimeGridContent(bookings: bookings),
      loading: () => const Center(
          child: CircularProgressIndicator(color: BBColors.brandPrimary)),
      error: (_, __) => Center(
        child: Text('Error loading schedule',
            style: BBTypography.bodyM.copyWith(color: colors.textSecondary)),
      ),
    );
  }
}

class _TimeGridContent extends StatelessWidget {
  const _TimeGridContent({required this.bookings});

  final List<BookingSlot> bookings;

  @override
  Widget build(BuildContext context) {
    final hours = List.generate(
        12, (i) => '${9 + i}:00 ${i < 3 ? 'AM' : 'PM'}');

    return ListView.builder(
      padding:
          const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
      itemCount: hours.length,
      itemBuilder: (context, index) {
        final booking = index < bookings.length ? bookings[index] : null;
        return _TimeSlotRow(
          time: hours[index],
          booking: booking,
          onTap: () {
            if (booking != null) _showBookingDetail(context, booking);
          },
        );
      },
    );
  }

  void _showBookingDetail(BuildContext context, BookingSlot booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BookingDetailModal(booking: booking),
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
    final colors = context.bbColors;
    return Container(
      height: 76,
      margin: const EdgeInsets.only(bottom: BBSpacing.px8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(time,
                style: BBTypography.caption
                    .copyWith(color: colors.textSecondary)),
          ),
          const SizedBox(width: BBSpacing.px12),
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

  static Color _color(BookingStatus status) => switch (status) {
        BookingStatus.confirmed => BBColors.brandPrimary,
        BookingStatus.inProgress => BBColors.warning,
        BookingStatus.completed => BBColors.success,
        BookingStatus.noShow => BBColors.error,
      };

  static String _label(BookingStatus status) => switch (status) {
        BookingStatus.confirmed => 'Confirmed',
        BookingStatus.inProgress => 'In Progress',
        BookingStatus.completed => 'Completed',
        BookingStatus.noShow => 'No-Show',
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final statusColor = _color(booking.status);
    final statusLabel = _label(booking.status);

    return Container(
      padding: const EdgeInsets.all(BBSpacing.px12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BBRadius.md,
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(booking.customerName,
                    style: BBTypography.headingS
                        .copyWith(color: colors.textPrimary)),
                const SizedBox(height: BBSpacing.px2),
                Text(booking.service,
                    style: BBTypography.bodyS
                        .copyWith(color: colors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('₹${booking.price}',
                  style: BBTypography.headingS.copyWith(color: statusColor)),
              const SizedBox(height: BBSpacing.px4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: BBSpacing.px8, vertical: BBSpacing.px2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BBRadius.pill,
                ),
                child: Text(statusLabel,
                    style: BBTypography.caption.copyWith(color: statusColor)),
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
    final colors = context.bbColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BBRadius.md,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Center(
        child: Text('Available',
            style: BBTypography.labelS.copyWith(color: colors.textDisabled)),
      ),
    );
  }
}

class _BookingDetailModal extends ConsumerWidget {
  const _BookingDetailModal({required this.booking});

  final BookingSlot booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    return Padding(
      padding: const EdgeInsets.all(BBSpacing.px24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Booking Details',
              style: BBTypography.headingL.copyWith(color: colors.textPrimary)),
          const SizedBox(height: BBSpacing.px24),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: BBColors.brandPrimaryDim,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    booking.customerName.isNotEmpty
                        ? booking.customerName[0].toUpperCase()
                        : '?',
                    style: BBTypography.headingL
                        .copyWith(color: BBColors.brandPrimary),
                  ),
                ),
              ),
              const SizedBox(width: BBSpacing.px16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.customerName,
                        style: BBTypography.headingM
                            .copyWith(color: colors.textPrimary)),
                    Text(booking.service,
                        style: BBTypography.bodyM
                            .copyWith(color: colors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.px24),
          Row(
            children: [
              Expanded(
                  child: _DetailItem(
                      label: 'Time', value: booking.time, colors: colors)),
              Expanded(
                  child: _DetailItem(
                      label: 'Duration',
                      value: '${booking.duration} min',
                      colors: colors)),
              Expanded(
                  child: _DetailItem(
                      label: 'Price',
                      value: '₹${booking.price}',
                      colors: colors)),
            ],
          ),
          const SizedBox(height: BBSpacing.px24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Phone calling feature coming soon')),
                    );
                  },
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: BBSpacing.px12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Complete'),
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.px12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref
                      .read(barberDashboardControllerProvider.notifier)
                      .updateQueueEntryStatus(booking.id, 'CANCELLED');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking cancelled')),
                    );
                  }
                } catch (_) {}
              },
              style: TextButton.styleFrom(foregroundColor: BBColors.error),
              child: const Text('Cancel Booking'),
            ),
          ),
          const SizedBox(height: BBSpacing.px8),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final BBColorTheme colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: BBTypography.caption.copyWith(color: colors.textSecondary)),
        const SizedBox(height: BBSpacing.px4),
        Text(value,
            style: BBTypography.headingS.copyWith(color: colors.textPrimary)),
      ],
    );
  }
}

class _WorkingHoursSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: BBSpacing.px24,
        right: BBSpacing.px24,
        top: BBSpacing.px8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: BBSpacing.px16),
              decoration:
                  BoxDecoration(color: colors.border, borderRadius: BBRadius.pill),
            ),
          ),
          Text('Add Working Hours',
              style: BBTypography.headingL.copyWith(color: colors.textPrimary)),
          const SizedBox(height: BBSpacing.px20),
          Text('Select Days',
              style: BBTypography.labelM.copyWith(color: colors.textPrimary)),
          const SizedBox(height: BBSpacing.px12),
          Wrap(
            spacing: BBSpacing.px8,
            runSpacing: BBSpacing.px8,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => _DayChip(day: day))
                .toList(),
          ),
          const SizedBox(height: BBSpacing.px24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start Time',
                        style: BBTypography.labelM
                            .copyWith(color: colors.textPrimary)),
                    const SizedBox(height: BBSpacing.px8),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.bgElevated,
                        borderRadius: BBRadius.md,
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Center(
                        child: Text('9:00 AM',
                            style: BBTypography.bodyM
                                .copyWith(color: colors.textPrimary)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BBSpacing.px16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('End Time',
                        style: BBTypography.labelM
                            .copyWith(color: colors.textPrimary)),
                    const SizedBox(height: BBSpacing.px8),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.bgElevated,
                        borderRadius: BBRadius.md,
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Center(
                        child: Text('8:00 PM',
                            style: BBTypography.bodyM
                                .copyWith(color: colors.textPrimary)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.px24),
          SizedBox(
            width: double.infinity,
            height: BBTouchTarget.button,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                final user = ProviderScope.containerOf(context)
                    .read(currentUserProvider);
                final barberId = user?.id ?? '';
                final hours = [
                  for (final d in [
                    'Mon','Tue','Wed','Thu','Fri','Sat','Sun'
                  ])
                    WorkingHour(
                        day: d,
                        startTime: '09:00',
                        endTime: '20:00',
                        isActive: true),
                ];
                if (barberId.isNotEmpty) {
                  ProviderScope.containerOf(context)
                      .read(barberDashboardControllerProvider.notifier)
                      .saveWorkingHours(barberId, hours)
                      .then((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Working hours saved')));
                    }
                  }).catchError((e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save: $e')));
                    }
                  });
                }
              },
              child: const Text('Save'),
            ),
          ),
          const SizedBox(height: BBSpacing.px24),
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
    final colors = context.bbColors;
    return GestureDetector(
      onTap: () => setState(() => _isSelected = !_isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: BBSpacing.px16, vertical: BBSpacing.px10),
        decoration: BoxDecoration(
          color: _isSelected ? BBColors.brandPrimaryDim : colors.bgElevated,
          borderRadius: BBRadius.pill,
          border: Border.all(
            color: _isSelected ? BBColors.brandPrimary : colors.borderSubtle,
          ),
        ),
        child: Text(
          widget.day,
          style: BBTypography.labelS.copyWith(
            color: _isSelected ? BBColors.brandPrimary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
