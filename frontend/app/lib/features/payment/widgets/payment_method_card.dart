import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import '../providers/payment_providers.dart';

class PaymentMethodCard extends ConsumerWidget {
  const PaymentMethodCard({
    super.key,
    required this.method,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final PaymentMethod method;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(paymentFormProvider);
    final isSelected = formState.selectedMethod == method;

    return GestureDetector(
      onTap: () => ref.read(paymentFormProvider.notifier).selectPaymentMethod(method),
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
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? BookBerPalette.primaryAccent.withValues(alpha: 0.12)
                    : BookBerPalette.bgElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? BookBerPalette.primaryAccent
                    : BookBerPalette.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: BookBerPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: BookBerPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Radio
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? BookBerPalette.primaryAccent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? BookBerPalette.primaryAccent
                      : BookBerPalette.textMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: BookBerPalette.bgPrimary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
