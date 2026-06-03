import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import '../../../core/models/bookber_models.dart' show TimeSlot;
import '../widgets/booking_step_indicator.dart';
import '../providers/booking_form_provider.dart';

class SelectTimeStep extends ConsumerStatefulWidget {
  const SelectTimeStep({super.key});

  @override
  ConsumerState<SelectTimeStep> createState() => _SelectTimeStepState();
}

class _SelectTimeStepState extends ConsumerState<SelectTimeStep> {
  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(bookingFormProvider);
    final selectedDate = formState.selectedDate ?? DateTime.now();

    return Column(
      children: [
        // Step indicator
        const BookingStepIndicator(currentStep: 3),
        const SizedBox(height: 24),

        // Book Slot / Join Queue toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: BookBerPalette.bgElevated,
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => ref.read(bookingFormProvider.notifier).toggleJoinQueue(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 40,
                      decoration: BoxDecoration(
                        color: !formState.isJoinQueue
                            ? BookBerPalette.primaryAccent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Center(
                        child: Text(
                          'Book Slot',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: !formState.isJoinQueue
                                ? BookBerPalette.bgPrimary
                                : BookBerPalette.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => ref.read(bookingFormProvider.notifier).toggleJoinQueue(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 40,
                      decoration: BoxDecoration(
                        color: formState.isJoinQueue
                            ? BookBerPalette.primaryAccent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Center(
                        child: Text(
                          'Join Queue',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: formState.isJoinQueue
                                ? BookBerPalette.bgPrimary
                                : BookBerPalette.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Content based on mode
        if (formState.isJoinQueue)
          _buildJoinQueueContent(formState)
        else
          _buildBookSlotContent(selectedDate, formState),
      ],
    );
  }

  Widget _buildJoinQueueContent(BookingFormState formState) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Live wait time
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: BookBerPalette.bgSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0x0FFFFFFF),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 48,
                    color: BookBerPalette.primaryAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Current wait',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: BookBerPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '~12 minutes',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: BookBerPalette.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.people,
                        size: 20,
                        color: BookBerPalette.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "You'd be #4 in queue",
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: BookBerPalette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Join Queue button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => ref.read(bookingFormProvider.notifier).nextStep(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BookBerPalette.primaryAccent,
                  foregroundColor: BookBerPalette.bgPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Join Queue Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookSlotContent(DateTime selectedDate, BookingFormState formState) {
    return Column(
      children: [
        // Date picker row
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 7,
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected = formState.selectedDate != null &&
                  _isSameDay(date, formState.selectedDate!);
              final isPast = index == 0 && date.hour < 6; // Early morning considered past

              return Padding(
                padding: EdgeInsets.only(right: index < 6 ? 12 : 0),
                child: GestureDetector(
                  onTap: isPast
                      ? null
                      : () => ref
                          .read(bookingFormProvider.notifier)
                          .selectDate(date),
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
                          index == 0 ? 'Today' : index == 1 ? 'Tomorrow' : _getDayName(date),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? BookBerPalette.bgPrimary
                                : isPast
                                    ? BookBerPalette.textMuted
                                    : BookBerPalette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? BookBerPalette.bgPrimary
                                : isPast
                                    ? BookBerPalette.textMuted
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
        ),
        const SizedBox(height: 24),

        // Time slots grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FutureBuilder<List<TimeSlot>>(
              future: _getTimeSlots(formState),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: BookBerPalette.primaryAccent),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading time slots',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: BookBerPalette.textSecondary,
                      ),
                    ),
                  );
                }

                final slots = snapshot.data ?? [];
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    final isSelected = formState.selectedTimeSlot == slot.time;

                    return GestureDetector(
                      onTap: slot.isAvailable
                          ? () => ref
                              .read(bookingFormProvider.notifier)
                              .selectTimeSlot(slot.time)
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: slot.isAvailable
                              ? isSelected
                                  ? BookBerPalette.primaryAccent
                                  : BookBerPalette.bgSurface
                              : BookBerPalette.bgPrimary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: slot.isAvailable
                                ? isSelected
                                    ? BookBerPalette.primaryAccent
                                    : const Color(0x0FFFFFFF)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                slot.time,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: slot.isAvailable
                                      ? isSelected
                                          ? BookBerPalette.bgPrimary
                                          : BookBerPalette.textPrimary
                                      : BookBerPalette.textMuted,
                                  decoration: !slot.isAvailable
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            if (slot.isNextAvailable)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BookBerPalette.queueSafe,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Next',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),

        // Bottom section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BookBerPalette.bgSurface,
            border: Border(
              top: BorderSide(
                color: const Color(0x0FFFFFFF),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Back button
              Expanded(
                child: TextButton(
                  onPressed: () => ref.read(bookingFormProvider.notifier).previousStep(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: BookBerPalette.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Continue button
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: formState.selectedTimeSlot != null
                        ? () => ref.read(bookingFormProvider.notifier).nextStep()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BookBerPalette.primaryAccent,
                      foregroundColor: BookBerPalette.bgPrimary,
                      disabledBackgroundColor: BookBerPalette.bgElevated,
                      disabledForegroundColor: BookBerPalette.textMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  Future<List<TimeSlot>> _getTimeSlots(BookingFormState formState) async {
    // Use the provider
    final barberId = formState.anyBarber ? 'any' : (formState.selectedBarberId ?? 'any');
    final date = formState.selectedDate ?? DateTime.now();
    
    // This would normally use the provider, but for simplicity we'll call it directly
    // In a real implementation, you'd use: ref.read(availableTimeSlotsProvider((barberId: barberId, date: date)))
    return [
      TimeSlot(time: '10:00 AM', isAvailable: true, isNextAvailable: true),
      TimeSlot(time: '10:30 AM', isAvailable: true),
      TimeSlot(time: '11:00 AM', isAvailable: true),
      TimeSlot(time: '11:30 AM', isAvailable: false),
      TimeSlot(time: '12:00 PM', isAvailable: true),
      TimeSlot(time: '12:30 PM', isAvailable: true),
      TimeSlot(time: '1:00 PM', isAvailable: false),
      TimeSlot(time: '1:30 PM', isAvailable: true),
      TimeSlot(time: '2:00 PM', isAvailable: true),
      TimeSlot(time: '2:30 PM', isAvailable: true),
    ];
  }
}
