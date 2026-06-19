import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
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
    final colors = context.bbColors;
    final formState = ref.watch(bookingFormProvider);
    final selectedDate = formState.selectedDate ?? DateTime.now();

    return Column(
      children: [
        const BookingStepIndicator(currentStep: 3),
        const SizedBox(height: BBSpacing.px24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BBRadius.pill,
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => ref.read(bookingFormProvider.notifier).toggleJoinQueue(),
                    child: AnimatedContainer(
                      duration: BBMotion.fast,
                      height: 40,
                      decoration: BoxDecoration(
                        color: !formState.isJoinQueue
                            ? BBColors.brandPrimary
                            : Colors.transparent,
                        borderRadius: BBRadius.pill,
                      ),
                      child: Center(
                        child: Text(
                          'Book Slot',
                          style: BBTypography.labelM.copyWith(
                            color: !formState.isJoinQueue
                                ? Colors.white
                                : colors.textSecondary,
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
                      duration: BBMotion.fast,
                      height: 40,
                      decoration: BoxDecoration(
                        color: formState.isJoinQueue
                            ? BBColors.brandPrimary
                            : Colors.transparent,
                        borderRadius: BBRadius.pill,
                      ),
                      child: Center(
                        child: Text(
                          'Join Queue',
                          style: BBTypography.labelM.copyWith(
                            color: formState.isJoinQueue
                                ? Colors.white
                                : colors.textSecondary,
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
        const SizedBox(height: BBSpacing.px24),

        if (formState.isJoinQueue)
          _buildJoinQueueContent(formState, colors)
        else
          _buildBookSlotContent(selectedDate, formState, colors),
      ],
    );
  }

  Widget _buildJoinQueueContent(BookingFormState formState, BBColorTheme colors) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(BBSpacing.px32),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BBRadius.xl,
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Column(
                children: [
                  const Icon(Icons.access_time, size: 48, color: BBColors.brandPrimary),
                  const SizedBox(height: BBSpacing.px16),
                  Text(
                    'Current wait',
                    style: BBTypography.bodyM.copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: BBSpacing.px8),
                  Text(
                    '~12 minutes',
                    style: BBTypography.numericXL.copyWith(color: BBColors.brandPrimary),
                  ),
                  const SizedBox(height: BBSpacing.px16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 20, color: colors.textSecondary),
                      const SizedBox(width: BBSpacing.px8),
                      Text(
                        "You'd be #4 in queue",
                        style: BBTypography.bodyL.copyWith(color: colors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: BBSpacing.px32),
            SizedBox(
              width: double.infinity,
              height: BBTouchTarget.button,
              child: ElevatedButton(
                onPressed: () => ref.read(bookingFormProvider.notifier).nextStep(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BBColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BBRadius.pill),
                  elevation: 0,
                ),
                child: Text('Join Queue Now', style: BBTypography.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookSlotContent(
      DateTime selectedDate, BookingFormState formState, BBColorTheme colors) {
    return Column(
      children: [
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
            itemCount: 7,
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected = formState.selectedDate != null &&
                  _isSameDay(date, formState.selectedDate!);
              final isPast = index == 0 && date.hour < 6;

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
                          ? BBColors.brandPrimary
                          : colors.bgSurface,
                      borderRadius: BBRadius.md,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          index == 0
                              ? 'Today'
                              : index == 1
                                  ? 'Tomorrow'
                                  : _getDayName(date),
                          style: BBTypography.caption.copyWith(
                            color: isSelected
                                ? Colors.white
                                : isPast
                                    ? colors.textDisabled
                                    : colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: BBSpacing.px4),
                        Text(
                          date.day.toString(),
                          style: BBTypography.headingS.copyWith(
                            color: isSelected
                                ? Colors.white
                                : isPast
                                    ? colors.textDisabled
                                    : colors.textPrimary,
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
        const SizedBox(height: BBSpacing.px24),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
            child: FutureBuilder<List<TimeSlot>>(
              future: _getTimeSlots(formState),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: BBColors.brandPrimary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading time slots',
                      style: BBTypography.bodyM.copyWith(color: colors.textSecondary),
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
                                  ? BBColors.brandPrimary
                                  : colors.bgSurface
                              : colors.bgCanvas,
                          borderRadius: BBRadius.md,
                          border: Border.all(
                            color: slot.isAvailable
                                ? isSelected
                                    ? BBColors.brandPrimary
                                    : colors.borderSubtle
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                slot.time,
                                style: BBTypography.labelM.copyWith(
                                  color: slot.isAvailable
                                      ? isSelected
                                          ? Colors.white
                                          : colors.textPrimary
                                      : colors.textDisabled,
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
                                    color: BBColors.success,
                                    borderRadius: BBRadius.pill,
                                  ),
                                  child: Text(
                                    'Next',
                                    style: BBTypography.overline.copyWith(
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

        Container(
          padding: const EdgeInsets.all(BBSpacing.px20),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            border: Border(top: BorderSide(color: colors.borderSubtle)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () =>
                      ref.read(bookingFormProvider.notifier).previousStep(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: BBSpacing.px14),
                  ),
                  child: Text(
                    'Back',
                    style: BBTypography.button.copyWith(color: colors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: BBSpacing.px12),
              Expanded(
                child: SizedBox(
                  height: BBTouchTarget.button,
                  child: ElevatedButton(
                    onPressed: formState.selectedTimeSlot != null
                        ? () =>
                            ref.read(bookingFormProvider.notifier).nextStep()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BBColors.brandPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: colors.bgElevated,
                      disabledForegroundColor: colors.textDisabled,
                      shape: RoundedRectangleBorder(borderRadius: BBRadius.pill),
                      elevation: 0,
                    ),
                    child: Text('Continue', style: BBTypography.button),
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
