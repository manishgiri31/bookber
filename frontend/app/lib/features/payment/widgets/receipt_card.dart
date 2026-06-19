import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../providers/payment_providers.dart';

class ReceiptCard extends ConsumerWidget {
  const ReceiptCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final formState = ref.watch(paymentFormProvider);

    return Container(
      width: double.infinity,
      padding: BBSpacing.cardPadding,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BBRadius.card,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...formState.services.map((service) {
            return Column(
              children: [
                _ReceiptRow(label: service.name, value: '₹${service.price}'),
                const SizedBox(height: BBSpacing.px8),
                _DottedDivider(color: colors.borderSubtle),
                const SizedBox(height: BBSpacing.px8),
              ],
            );
          }),
          const SizedBox(height: BBSpacing.px8),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: BBSpacing.px16),

          _ReceiptRow(label: 'Subtotal', value: '₹${formState.subtotal}'),
          const SizedBox(height: BBSpacing.px12),

          _ReceiptRow(
            label: 'BookBer Discount',
            value: '-₹${formState.discount}',
            valueColor: BBColors.brandPrimary,
          ),
          const SizedBox(height: BBSpacing.px16),

          Divider(color: colors.borderSubtle),
          const SizedBox(height: BBSpacing.px16),

          _ReceiptRow(
            label: 'Total',
            value: '₹${formState.total}',
            labelStyle: BBTypography.headingS.copyWith(color: colors.textPrimary),
            valueStyle: BBTypography.headingS.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    this.valueColor,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: labelStyle ?? BBTypography.bodyM.copyWith(color: colors.textSecondary),
        ),
        Text(
          value,
          style: valueStyle ??
              BBTypography.labelM.copyWith(color: valueColor ?? colors.textPrimary),
        ),
      ],
    );
  }
}

class _DottedDivider extends StatelessWidget {
  const _DottedDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (constraints.constrainWidth() / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}
