import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../widgets/booking_step_indicator.dart';
import '../providers/booking_form_provider.dart';

class ConfirmBookingStep extends ConsumerWidget {
  const ConfirmBookingStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final formState = ref.watch(bookingFormProvider);

    return Column(
      children: [
        const BookingStepIndicator(currentStep: 4),
        const SizedBox(height: BBSpacing.px24),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(BBSpacing.px20),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BBRadius.card,
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formState.shopName,
                        style: BBTypography.headingS.copyWith(color: colors.textPrimary),
                      ),
                      const SizedBox(height: BBSpacing.px4),
                      Text(
                        '123 Main Street, Ludhiana',
                        style: BBTypography.bodyS.copyWith(color: colors.textSecondary),
                      ),
                      const SizedBox(height: BBSpacing.px16),
                      Divider(color: colors.borderSubtle),
                      const SizedBox(height: BBSpacing.px16),

                      Text(
                        'Services',
                        style: BBTypography.labelL.copyWith(color: colors.textPrimary),
                      ),
                      const SizedBox(height: BBSpacing.px12),
                      ...List.generate(formState.selectedServiceIds.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: BBSpacing.px8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Service ${index + 1}',
                                style: BBTypography.bodyM.copyWith(color: colors.textPrimary),
                              ),
                              Text(
                                '₹150',
                                style: BBTypography.labelM.copyWith(color: colors.textPrimary),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: BBSpacing.px16),
                      Divider(color: colors.borderSubtle),
                      const SizedBox(height: BBSpacing.px16),

                      Text(
                        'Barber',
                        style: BBTypography.labelL.copyWith(color: colors.textPrimary),
                      ),
                      const SizedBox(height: BBSpacing.px8),
                      Text(
                        formState.anyBarber ? 'Any available barber' : 'Selected barber',
                        style: BBTypography.bodyM.copyWith(color: colors.textPrimary),
                      ),
                      const SizedBox(height: BBSpacing.px16),
                      Divider(color: colors.borderSubtle),
                      const SizedBox(height: BBSpacing.px16),

                      Text(
                        'Date & Time',
                        style: BBTypography.labelL.copyWith(color: colors.textPrimary),
                      ),
                      const SizedBox(height: BBSpacing.px8),
                      if (formState.isJoinQueue)
                        Text(
                          'Join Queue',
                          style: BBTypography.bodyM.copyWith(color: colors.textPrimary),
                        )
                      else
                        Text(
                          formState.selectedDate != null
                              ? '${_formatDate(formState.selectedDate!)} at ${formState.selectedTimeSlot ?? ''}'
                              : 'Not selected',
                          style: BBTypography.bodyM.copyWith(color: colors.textPrimary),
                        ),
                      const SizedBox(height: BBSpacing.px16),
                      Divider(color: colors.borderSubtle),
                      const SizedBox(height: BBSpacing.px16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal',
                            style: BBTypography.bodyM.copyWith(color: colors.textSecondary),
                          ),
                          Text(
                            '₹${formState.totalPrice}',
                            style: BBTypography.labelM.copyWith(color: colors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: BBSpacing.px8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'BookBer discount',
                            style: BBTypography.bodyM.copyWith(color: BBColors.brandPrimary),
                          ),
                          Text(
                            '-₹50',
                            style: BBTypography.labelM.copyWith(color: BBColors.brandPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: BBSpacing.px12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: BBTypography.headingS.copyWith(color: colors.textPrimary),
                          ),
                          Text(
                            '₹${formState.totalPrice - 50}',
                            style: BBTypography.headingM.copyWith(color: BBColors.brandPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BBSpacing.px24),

                Container(
                  padding: const EdgeInsets.all(BBSpacing.px16),
                  decoration: BoxDecoration(
                    color: BBColors.brandPrimaryDim,
                    borderRadius: BBRadius.md,
                    border: Border(
                      left: BorderSide(color: BBColors.brandPrimary, width: 4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: BBSpacing.px12),
                      Expanded(
                        child: Text(
                          'BookBer Members Save ₹50 on this booking',
                          style: BBTypography.bodyM.copyWith(color: colors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BBSpacing.px24),

                Text(
                  'Payment Method',
                  style: BBTypography.headingS.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: BBSpacing.px12),
                Row(
                  children: [
                    _PaymentMethodPill(
                      label: 'Pay at Shop',
                      icon: Icons.payments_outlined,
                      isSelected: formState.paymentMethod == 'pay_at_shop',
                      onTap: () => ref
                          .read(bookingFormProvider.notifier)
                          .setPaymentMethod('pay_at_shop'),
                    ),
                    const SizedBox(width: BBSpacing.px12),
                    _PaymentMethodPill(
                      label: 'Pay Online',
                      icon: Icons.credit_card_outlined,
                      isSelected: formState.paymentMethod == 'pay_online',
                      onTap: () => ref
                          .read(bookingFormProvider.notifier)
                          .setPaymentMethod('pay_online'),
                    ),
                  ],
                ),
                const SizedBox(height: BBSpacing.px24),

                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'By confirming, you agree to our cancellation policy',
                    style: BBTypography.caption.copyWith(
                      color: colors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: BBSpacing.px24),
              ],
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
                    onPressed: () => _handleConfirmBooking(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BBColors.brandPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BBRadius.pill),
                      elevation: 0,
                    ),
                    child: Text('Confirm Booking', style: BBTypography.button),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleConfirmBooking(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pushReplacementNamed('/booking-success');
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _PaymentMethodPill extends StatelessWidget {
  const _PaymentMethodPill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: BBSpacing.px14),
          decoration: BoxDecoration(
            color: isSelected ? BBColors.brandPrimaryDim : colors.bgElevated,
            borderRadius: BBRadius.md,
            border: Border.all(
              color: isSelected ? BBColors.brandPrimary : colors.borderSubtle,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? BBColors.brandPrimary : colors.textSecondary,
              ),
              const SizedBox(width: BBSpacing.px8),
              Text(
                label,
                style: BBTypography.labelM.copyWith(
                  color: isSelected ? BBColors.brandPrimary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
