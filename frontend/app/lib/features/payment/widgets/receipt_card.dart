import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import '../providers/payment_providers.dart';

class ReceiptCard extends ConsumerWidget {
  const ReceiptCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(paymentFormProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          // Services breakdown
          ...formState.services.map((service) {
            return Column(
              children: [
                _ReceiptRow(
                  label: service.name,
                  value: '₹${service.price}',
                ),
                const SizedBox(height: 8),
                const _DottedDivider(),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),
          const SizedBox(height: 8),
          const Divider(color: Color(0x0FFFFFFF)),
          const SizedBox(height: 16),

          // Subtotal
          _ReceiptRow(
            label: 'Subtotal',
            value: '₹${formState.subtotal}',
          ),
          const SizedBox(height: 12),

          // Discount
          _ReceiptRow(
            label: 'BookBer Discount',
            value: '-₹${formState.discount}',
            valueColor: BookBerPalette.primaryAccent,
          ),
          const SizedBox(height: 16),

          const Divider(color: Color(0x0FFFFFFF)),
          const SizedBox(height: 16),

          // Total
          _ReceiptRow(
            label: 'Total',
            value: '₹${formState.total}',
            labelStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: BookBerPalette.textPrimary,
            ),
            valueStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: BookBerPalette.textPrimary,
            ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: labelStyle ??
              GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: BookBerPalette.textSecondary,
              ),
        ),
        Text(
          value,
          style: valueStyle ??
              TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: valueColor ?? BookBerPalette.textPrimary,
              ),
        ),
      ],
    );
  }
}

class _DottedDivider extends StatelessWidget {
  const _DottedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashWidth = 4.0;
        final dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: BookBerPalette.textMuted),
              ),
            );
          }),
        );
      },
    );
  }
}
