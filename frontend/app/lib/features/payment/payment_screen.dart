import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../../../core/models/bookber_models.dart';
import '../../../core/network/api_result.dart';
import 'providers/payment_providers.dart';
import 'widgets/payment_method_card.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _upiController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(paymentControllerProvider.notifier).init(widget.bookingId));
  }

  @override
  void dispose() {
    _upiController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final formState = ref.watch(paymentFormProvider);
    final bookingAsync = ref.watch(bookingDetailsProvider(widget.bookingId));
    final paymentAsync = ref.watch(paymentControllerProvider);
    final isPaying = paymentAsync.isLoading;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        backgroundColor: colors.bgCanvas,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: BBIconSize.md, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Payment',
            style: BBTypography.headingL.copyWith(color: colors.textPrimary)),
      ),
      body: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: BBSpacing.pagePadding,
            child: Text(error.toString(),
                textAlign: TextAlign.center,
                style: BBTypography.bodyM.copyWith(color: colors.textSecondary)),
          ),
        ),
        data: (booking) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: BBSpacing.px8),
                _Header(booking: booking),
                const SizedBox(height: BBSpacing.px24),
                _ReceiptCard(booking: booking),
                const SizedBox(height: BBSpacing.px24),
                Text('Payment Method',
                    style: BBTypography.headingM
                        .copyWith(color: colors.textPrimary)),
                const SizedBox(height: BBSpacing.px12),
                const PaymentMethodCard(
                  method: PaymentMethod.cash,
                  title: 'Cash',
                  subtitle: 'Pay the barber directly',
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: BBSpacing.px10),
                const PaymentMethodCard(
                  method: PaymentMethod.upi,
                  title: 'UPI',
                  subtitle: 'Pay using UPI ID or QR code',
                  icon: Icons.qr_code_scanner_outlined,
                ),
                if (formState.selectedMethod == PaymentMethod.upi) ...[
                  const SizedBox(height: BBSpacing.px12),
                  TextField(
                    controller: _upiController,
                    decoration: const InputDecoration(labelText: 'UPI ID'),
                  ),
                ],
                const SizedBox(height: BBSpacing.px10),
                const PaymentMethodCard(
                  method: PaymentMethod.card,
                  title: 'Card',
                  subtitle: 'Credit or debit card',
                  icon: Icons.credit_card_outlined,
                ),
                if (formState.selectedMethod == PaymentMethod.card) ...[
                  const SizedBox(height: BBSpacing.px12),
                  TextField(
                    controller: _cardNumberController,
                    decoration: const InputDecoration(labelText: 'Card number'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: BBSpacing.px10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cardExpiryController,
                          decoration: const InputDecoration(labelText: 'MM/YY'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: BBSpacing.px12),
                      Expanded(
                        child: TextField(
                          controller: _cardCvvController,
                          decoration: const InputDecoration(labelText: 'CVV'),
                          keyboardType: TextInputType.number,
                          obscureText: true,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: BBSpacing.px10),
                const PaymentMethodCard(
                  method: PaymentMethod.wallet,
                  title: 'Wallet',
                  subtitle: 'Pay from BookBer Wallet',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                const SizedBox(height: 120),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: bookingAsync.maybeWhen(
        data: (booking) => _PayButton(
          amount: booking.finalAmount > 0
              ? booking.finalAmount
              : booking.totalAmount,
          isLoading: isPaying,
          onPressed: isPaying ? null : () => _handlePayment(context),
        ),
        orElse: () => null,
      ),
    );
  }

  Future<void> _handlePayment(BuildContext context) async {
    final method = ref.read(paymentFormProvider).selectedMethod.apiValue;
    final result = await ref
        .read(paymentControllerProvider.notifier)
        .confirmPayment(widget.bookingId, method);

    if (!mounted) return;
    if (result case ApiError<Payment>(:final message)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $message')),
      );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: BBSpacing.px12, vertical: BBSpacing.px6),
          decoration: BoxDecoration(
            color: BBColors.successDim,
            borderRadius: BBRadius.pill,
          ),
          child: Text('Service Complete',
              style: BBTypography.labelS.copyWith(color: BBColors.success)),
        ),
        const SizedBox(height: BBSpacing.px12),
        Text(booking.shopName,
            style: BBTypography.displayS.copyWith(color: colors.textPrimary)),
        const SizedBox(height: BBSpacing.px4),
        Text('with ${booking.barberName}',
            style: BBTypography.bodyM.copyWith(color: colors.textSecondary)),
      ],
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final total = booking.totalAmount;
    final discount = booking.discountAmount;
    final finalAmount =
        booking.finalAmount > 0 ? booking.finalAmount : total - discount;

    return Container(
      padding: BBSpacing.cardPadding,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BBRadius.card,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Receipt',
              style: BBTypography.headingM.copyWith(color: colors.textPrimary)),
          const SizedBox(height: BBSpacing.px12),
          ...booking.services.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: BBSpacing.px8),
                child: _ReceiptRow(label: s.name, value: ''),
              )),
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: BBSpacing.px8),
          _ReceiptRow(label: 'Subtotal', value: _money(total)),
          if (discount > 0)
            _ReceiptRow(
                label: 'Discount', value: '−${_money(discount)}'),
          const SizedBox(height: BBSpacing.px8),
          _ReceiptRow(
              label: 'Total', value: _money(finalAmount), isTotal: true),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final style = isTotal
        ? BBTypography.headingS.copyWith(color: colors.textPrimary)
        : BBTypography.bodyM.copyWith(color: colors.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BBSpacing.px4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _PayButton extends StatelessWidget {
  const _PayButton({
    required this.amount,
    required this.isLoading,
    required this.onPressed,
  });

  final double amount;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.px20),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: BBTouchTarget.button,
          child: ElevatedButton(
            onPressed: onPressed,
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('Pay ${_money(amount)}'),
          ),
        ),
      ),
    );
  }
}

String _money(double value) => '₹${value.toStringAsFixed(0)}';
