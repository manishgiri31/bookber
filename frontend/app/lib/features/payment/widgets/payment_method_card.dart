import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
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
    final colors = context.bbColors;
    final formState = ref.watch(paymentFormProvider);
    final isSelected = formState.selectedMethod == method;

    return GestureDetector(
      onTap: () => ref.read(paymentFormProvider.notifier).selectPaymentMethod(method),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? BBColors.brandPrimaryDim : colors.bgElevated,
                borderRadius: BBRadius.md,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? BBColors.brandPrimary : colors.textSecondary,
              ),
            ),
            const SizedBox(width: BBSpacing.px16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: BBTypography.bodyL.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: BBSpacing.px4),
                  Text(
                    subtitle,
                    style: BBTypography.bodyS.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? BBColors.brandPrimary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? BBColors.brandPrimary : colors.textDisabled,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
