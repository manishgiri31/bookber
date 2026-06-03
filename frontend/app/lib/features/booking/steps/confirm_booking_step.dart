import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import '../widgets/booking_step_indicator.dart';
import '../providers/booking_form_provider.dart';

class ConfirmBookingStep extends ConsumerWidget {
  const ConfirmBookingStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(bookingFormProvider);

    return Column(
      children: [
        // Step indicator
        const BookingStepIndicator(currentStep: 4),
        const SizedBox(height: 24),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0x0AFFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0x0FFFFFFF),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shop name
                      Text(
                        formState.shopName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: BookBerPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '123 Main Street, Ludhiana',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: BookBerPalette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0x0FFFFFFF)),
                      const SizedBox(height: 16),

                      // Services
                      Text(
                        'Services',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: BookBerPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(formState.selectedServiceIds.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Service ${index + 1}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: BookBerPalette.textPrimary,
                                ),
                              ),
                              Text(
                                '₹150',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: BookBerPalette.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0x0FFFFFFF)),
                      const SizedBox(height: 16),

                      // Barber
                      Text(
                        'Barber',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: BookBerPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formState.anyBarber ? 'Any available barber' : 'Selected barber',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: BookBerPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0x0FFFFFFF)),
                      const SizedBox(height: 16),

                      // Date & Time
                      Text(
                        'Date & Time',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: BookBerPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (formState.isJoinQueue)
                        Text(
                          'Join Queue',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: BookBerPalette.textPrimary,
                          ),
                        )
                      else
                        Text(
                          formState.selectedDate != null
                              ? '${_formatDate(formState.selectedDate!)} at ${formState.selectedTimeSlot ?? ''}'
                              : 'Not selected',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: BookBerPalette.textPrimary,
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0x0FFFFFFF)),
                      const SizedBox(height: 16),

                      // Price breakdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: BookBerPalette.textSecondary,
                            ),
                          ),
                          Text(
                            '₹${formState.totalPrice}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: BookBerPalette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'BookBer discount',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: BookBerPalette.primaryAccent,
                            ),
                          ),
                          Text(
                            '-₹50',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: BookBerPalette.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: BookBerPalette.textPrimary,
                            ),
                          ),
                          Text(
                            '₹${formState.totalPrice - 50}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: BookBerPalette.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // BookBer perks box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BookBerPalette.primaryAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(
                        color: BookBerPalette.primaryAccent,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '🎉',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'BookBer Members Save ₹50 on this booking',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: BookBerPalette.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Payment method
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: BookBerPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
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
                    const SizedBox(width: 12),
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
                const SizedBox(height: 24),

                // Terms
                GestureDetector(
                  onTap: () {
                    // TODO: Show cancellation policy
                  },
                  child: Text(
                    'By confirming, you agree to our cancellation policy',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: BookBerPalette.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
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
              // Confirm button
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _handleConfirmBooking(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BookBerPalette.primaryAccent,
                      foregroundColor: BookBerPalette.bgPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm Booking',
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

  void _handleConfirmBooking(BuildContext context, WidgetRef ref) {
    // TODO: Implement actual booking creation
    // For now, just navigate to success screen
    Navigator.of(context).pushReplacementNamed('/booking-success');
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? BookBerPalette.primaryAccent.withValues(alpha: 0.12)
                : BookBerPalette.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? BookBerPalette.primaryAccent
                  : const Color(0x0FFFFFFF),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? BookBerPalette.primaryAccent
                    : BookBerPalette.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? BookBerPalette.primaryAccent
                      : BookBerPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
