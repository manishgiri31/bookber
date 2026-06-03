import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import '../../../core/models/bookber_models.dart' show Barber;
import '../widgets/booking_step_indicator.dart';
import '../providers/booking_form_provider.dart';

class SelectBarberStep extends ConsumerWidget {
  const SelectBarberStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(bookingFormProvider);
    final barbersAsync = ref.watch(availableBarbersProvider(formState.shopId));

    return Column(
      children: [
        // Step indicator
        const BookingStepIndicator(currentStep: 2),
        const SizedBox(height: 24),

        // "Any Available Barber" card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () => ref.read(bookingFormProvider.notifier).selectAnyBarber(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: formState.anyBarber
                    ? BookBerPalette.primaryAccent.withValues(alpha: 0.08)
                    : BookBerPalette.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: formState.anyBarber
                      ? BookBerPalette.primaryAccent
                      : const Color(0x0FFFFFFF),
                  width: formState.anyBarber ? 2 : 1,
                  style: formState.anyBarber ? BorderStyle.solid : BorderStyle.none,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: BookBerPalette.bgElevated,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 28,
                      color: BookBerPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Any Available Barber',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: BookBerPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Let us assign the best available',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: BookBerPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (formState.anyBarber)
                    const Icon(
                      Icons.check_circle,
                      color: BookBerPalette.primaryAccent,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Barber cards
        Expanded(
          child: barbersAsync.when(
            data: (barbers) {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: barbers.length,
                itemBuilder: (context, index) {
                  final barber = barbers[index];
                  final isSelected = formState.selectedBarberId == barber.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _BarberCard(
                      barber: barber,
                      isSelected: isSelected,
                      onTap: () => ref.read(bookingFormProvider.notifier).selectBarber(barber.id),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: BookBerPalette.primaryAccent),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Error loading barbers',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: BookBerPalette.textSecondary,
                ),
              ),
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
                    onPressed: formState.anyBarber || formState.selectedBarberId != null
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
}

class _BarberCard extends StatelessWidget {
  const _BarberCard({
    required this.barber,
    required this.isSelected,
    required this.onTap,
  });

  final Barber barber;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? BookBerPalette.primaryAccent.withValues(alpha: 0.08)
              : BookBerPalette.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? BookBerPalette.primaryAccent
                : const Color(0x0FFFFFFF),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: BookBerPalette.bgElevated,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                // Availability indicator
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: barber.isAvailable
                          ? BookBerPalette.queueSafe
                          : BookBerPalette.textMuted,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: BookBerPalette.bgSurface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        barber.name,
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: BookBerPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: BookBerPalette.primaryAccent,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        barber.rating.toStringAsFixed(1),
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: BookBerPalette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Specializations
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: barber.specializations.take(3).map((spec) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: BookBerPalette.bgElevated,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          spec,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: BookBerPalette.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  // Next available time
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: BookBerPalette.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Next: ${barber.nextAvailableTime}',
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
            ),
            // Checkmark
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: BookBerPalette.primaryAccent,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
