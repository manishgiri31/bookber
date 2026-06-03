import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/design_system.dart';
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
    Future.microtask(() {
      ref.read(paymentControllerProvider.notifier).init(widget.bookingId);
    });
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
    final formState = ref.watch(paymentFormProvider);
    final bookingAsync = ref.watch(bookingDetailsProvider(widget.bookingId));
    final paymentAsync = ref.watch(paymentControllerProvider);
    final isPaying = paymentAsync.isLoading;

    return Scaffold(
      backgroundColor: BookBerPalette.bgPrimary,
      appBar: AppBar(
        backgroundColor: BookBerPalette.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BookBerPalette.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorState(message: error.toString()),
        data: (booking) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(booking: booking),
                const SizedBox(height: 32),
                _ReceiptCard(booking: booking),
                const SizedBox(height: 32),
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: BookBerPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const PaymentMethodCard(
                  method: PaymentMethod.cash,
                  title: 'Cash',
                  subtitle: 'Pay the barber directly',
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: 12),
                const PaymentMethodCard(
                  method: PaymentMethod.upi,
                  title: 'UPI',
                  subtitle: 'Pay using UPI ID or QR code',
                  icon: Icons.qr_code_scanner_outlined,
                ),
                if (formState.selectedMethod == PaymentMethod.upi) ...[
                  const SizedBox(height: 16),
                  _TextInput(controller: _upiController, hintText: 'Enter UPI ID'),
                ],
                const SizedBox(height: 12),
                const PaymentMethodCard(
                  method: PaymentMethod.card,
                  title: 'Card',
                  subtitle: 'Credit or debit card',
                  icon: Icons.credit_card_outlined,
                ),
                if (formState.selectedMethod == PaymentMethod.card) ...[
                  const SizedBox(height: 16),
                  _TextInput(
                    controller: _cardNumberController,
                    hintText: 'Card number',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _TextInput(
                          controller: _cardExpiryController,
                          hintText: 'MM/YY',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TextInput(
                          controller: _cardCvvController,
                          hintText: 'CVV',
                          keyboardType: TextInputType.number,
                          obscureText: true,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                const PaymentMethodCard(
                  method: PaymentMethod.wallet,
                  title: 'Wallet',
                  subtitle: 'Pay from BookBer Wallet',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: bookingAsync.maybeWhen(
        data: (booking) => _PayButton(
          amount: booking.finalAmount > 0 ? booking.finalAmount : booking.totalAmount,
          isLoading: isPaying,
          onPressed: isPaying ? null : () => _handlePayment(context),
        ),
        orElse: () => null,
      ),
    );
  }

  Future<void> _handlePayment(BuildContext context) async {
    final method = ref.read(paymentFormProvider).selectedMethod.apiValue;
    final result = await ref.read(paymentControllerProvider.notifier).confirmPayment(
          widget.bookingId,
          method,
        );

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: BookBerPalette.queueSafe.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Service Complete',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: BookBerPalette.queueSafe,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          booking.shopName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: BookBerPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'with ${booking.barberName}',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: BookBerPalette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final total = booking.totalAmount;
    final discount = booking.discountAmount;
    final finalAmount = booking.finalAmount > 0 ? booking.finalAmount : total - discount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Receipt',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: BookBerPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...booking.services.map((service) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReceiptRow(label: service.name, value: ''),
            );
          }),
          const Divider(color: BookBerPalette.bgElevated),
          _ReceiptRow(label: 'Subtotal', value: _money(total)),
          if (discount > 0) _ReceiptRow(label: 'BookBer discount', value: '-${_money(discount)}'),
          const SizedBox(height: 8),
          _ReceiptRow(label: 'Total', value: _money(finalAmount), isTotal: true),
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
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              color: isTotal ? BookBerPalette.textPrimary : BookBerPalette.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? BookBerPalette.textPrimary : BookBerPalette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: GoogleFonts.dmSans(fontSize: 14, color: BookBerPalette.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.dmSans(fontSize: 14, color: BookBerPalette.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: BookBerPalette.bgSurface,
        border: Border(top: BorderSide(color: Color(0x0FFFFFFF))),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: BookBerPalette.primaryAccent,
              foregroundColor: BookBerPalette.bgPrimary,
              disabledBackgroundColor: BookBerPalette.bgElevated,
              disabledForegroundColor: BookBerPalette.textMuted,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: BookBerPalette.bgPrimary,
                    ),
                  )
                : Text(
                    'Pay ${_money(amount)}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(color: BookBerPalette.textSecondary),
        ),
      ),
    );
  }
}

String _money(double value) => 'Rs ${value.toStringAsFixed(0)}';
