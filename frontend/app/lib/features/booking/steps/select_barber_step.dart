import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../../../core/models/bookber_models.dart' show Barber;
import '../widgets/booking_step_indicator.dart';
import '../providers/booking_form_provider.dart';

class SelectBarberStep extends ConsumerWidget {
  const SelectBarberStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final formState = ref.watch(bookingFormProvider);
    final barbersAsync = ref.watch(availableBarbersProvider(formState.shopId));

    return Column(
      children: [
        const BookingStepIndicator(currentStep: 2),
        const SizedBox(height: BBSpacing.px24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
          child: GestureDetector(
            onTap: () => ref.read(bookingFormProvider.notifier).selectAnyBarber(),
            child: Container(
              padding: const EdgeInsets.all(BBSpacing.px16),
              decoration: BoxDecoration(
                color: formState.anyBarber ? BBColors.brandPrimaryDim : colors.bgSurface,
                borderRadius: BBRadius.md,
                border: Border.all(
                  color: formState.anyBarber ? BBColors.brandPrimary : colors.borderSubtle,
                  width: formState.anyBarber ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors.bgElevated,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(Icons.person_outline, size: 28, color: colors.textSecondary),
                  ),
                  const SizedBox(width: BBSpacing.px16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Any Available Barber',
                          style: BBTypography.bodyL.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: BBSpacing.px4),
                        Text(
                          'Let us assign the best available',
                          style: BBTypography.bodyS.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (formState.anyBarber)
                    const Icon(Icons.check_circle, color: BBColors.brandPrimary, size: 24),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: BBSpacing.px24),

        Expanded(
          child: barbersAsync.when(
            data: (barbers) {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
                itemCount: barbers.length,
                itemBuilder: (context, index) {
                  final barber = barbers[index];
                  final isSelected = formState.selectedBarberId == barber.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: BBSpacing.px16),
                    child: _BarberCard(
                      barber: barber,
                      isSelected: isSelected,
                      onTap: () =>
                          ref.read(bookingFormProvider.notifier).selectBarber(barber.id),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: BBColors.brandPrimary),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Error loading barbers',
                style: BBTypography.bodyM.copyWith(color: colors.textSecondary),
              ),
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
                  onPressed: () => ref.read(bookingFormProvider.notifier).previousStep(),
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
                    onPressed: formState.anyBarber || formState.selectedBarberId != null
                        ? () => ref.read(bookingFormProvider.notifier).nextStep()
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
    final colors = context.bbColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(BBSpacing.px16),
        decoration: BoxDecoration(
          color: isSelected ? BBColors.brandPrimaryDim : colors.bgSurface,
          borderRadius: BBRadius.md,
          border: Border.all(
            color: isSelected ? BBColors.brandPrimary : colors.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.bgElevated,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: barber.isAvailable ? BBColors.success : colors.textDisabled,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.bgSurface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: BBSpacing.px16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        barber.name,
                        style: BBTypography.bodyL.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: BBSpacing.px8),
                      Icon(Icons.star, size: 14, color: BBColors.brandSecondary),
                      const SizedBox(width: 2),
                      Text(
                        barber.rating.toStringAsFixed(1),
                        style: BBTypography.bodyS.copyWith(color: colors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: BBSpacing.px8),
                  Wrap(
                    spacing: BBSpacing.px8,
                    runSpacing: BBSpacing.px8,
                    children: barber.specializations.take(3).map((spec) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: BBSpacing.px8, vertical: BBSpacing.px4),
                        decoration: BoxDecoration(
                          color: colors.bgElevated,
                          borderRadius: BBRadius.pill,
                        ),
                        child: Text(
                          spec,
                          style: BBTypography.caption.copyWith(color: colors.textSecondary),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: BBSpacing.px8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: colors.textSecondary),
                      const SizedBox(width: BBSpacing.px4),
                      Text(
                        'Next: ${barber.nextAvailableTime}',
                        style: BBTypography.caption.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: BBColors.brandPrimary, size: 24),
          ],
        ),
      ),
    );
  }
}
