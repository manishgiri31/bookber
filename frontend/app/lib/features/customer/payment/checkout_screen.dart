import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_button.dart';
import '../../../core/widgets/bb_loading.dart';
import '../../../core/widgets/bb_snackbar.dart';
import 'payment_provider.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.shopName,
    required this.serviceName,
  });

  final String bookingId;
  final double amount;
  final String shopName;
  final String serviceName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final checkoutState = ref.watch(checkoutProvider);

    ref.listen(checkoutProvider, (_, next) {
      if (next is CheckoutSuccess) {
        showBBSnackbar(context,
            message: 'Payment confirmed!', isSuccess: true);
        context.pop(true);
      } else if (next is CheckoutError) {
        showBBSnackbar(context, message: next.message, isError: true);
      }
    });

    if (checkoutState is CheckoutLoading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const BBLoadingScreen(),
      );
    }

    if (checkoutState is CheckoutSuccess) {
      return Scaffold(
        backgroundColor: colors.background,
        body: _SuccessView(payment: checkoutState.payment),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Checkout',
          style: BBTypography.textTheme.titleLarge?.copyWith(
            color: colors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order summary
            Container(
              padding: const EdgeInsets.all(BBSpacing.base),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(BBRadius.lg),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: BBTypography.textTheme.titleMedium?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: BBSpacing.base),
                  _SummaryRow(label: 'Shop', value: shopName),
                  _SummaryRow(label: 'Service', value: serviceName),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: 'Total',
                    value: '₹${amount.toStringAsFixed(0)}',
                    bold: true,
                    valueColor: BBColors.amber,
                  ),
                ],
              ),
            ),
            const SizedBox(height: BBSpacing.xl),

            Text(
              'Choose payment method',
              style: BBTypography.textTheme.titleMedium?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: BBSpacing.md),

            // Razorpay (UPI/Card)
            _PaymentOption(
              icon: Icons.payment_rounded,
              title: 'UPI / Card',
              subtitle: 'Pay securely with Razorpay',
              color: BBColors.info,
              onTap: () => _payWithRazorpay(context, ref),
            ),
            const SizedBox(height: BBSpacing.sm),

            // Cash at shop
            _PaymentOption(
              icon: Icons.money_rounded,
              title: 'Pay at Shop',
              subtitle: 'Cash payment after service',
              color: BBColors.success,
              onTap: () => _payAtShop(context, ref),
            ),

            const Spacer(),

            if (checkoutState is CheckoutError) ...[
              Container(
                padding: const EdgeInsets.all(BBSpacing.md),
                decoration: BoxDecoration(
                  color: BBColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(BBRadius.md),
                  border:
                      Border.all(color: BBColors.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  (checkoutState as CheckoutError).message,
                  style: BBTypography.textTheme.bodySmall
                      ?.copyWith(color: BBColors.error),
                ),
              ),
              const SizedBox(height: BBSpacing.md),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _payWithRazorpay(
      BuildContext context, WidgetRef ref) async {
    final order = await ref
        .read(checkoutProvider.notifier)
        .createOrder(bookingId, amount);

    if (order == null || !context.mounted) return;

    if (order.isStub || order.keyId.isEmpty || order.keyId == 'placeholder') {
      // Razorpay not configured — simulate success
      if (context.mounted) {
        showBBSnackbar(
          context,
          message:
              'Razorpay not configured. Add RAZORPAY_KEY_ID to backend .env to enable real payments. Marking as paid.',
          isSuccess: false,
        );
      }
      await ref.read(checkoutProvider.notifier).verifyPayment(
            bookingId: bookingId,
            razorpayOrderId: order.razorpayOrderId,
            razorpayPaymentId: 'stub_pay_${DateTime.now().millisecondsSinceEpoch}',
            razorpaySignature: 'stub_sig',
          );
      return;
    }

    // TODO: When razorpay_flutter package is installed, launch the Razorpay checkout:
    //
    // final razorpay = Razorpay();
    // razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) async {
    //   await ref.read(checkoutProvider.notifier).verifyPayment(
    //     bookingId: bookingId,
    //     razorpayOrderId: order.razorpayOrderId,
    //     razorpayPaymentId: r.paymentId!,
    //     razorpaySignature: r.signature!,
    //   );
    // });
    // razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
    //   showBBSnackbar(context, message: r.message ?? 'Payment failed', isError: true);
    // });
    // razorpay.open({
    //   'key': order.keyId,
    //   'amount': (order.amount * 100).toInt(),
    //   'currency': order.currency,
    //   'order_id': order.razorpayOrderId,
    //   'name': 'BookBer',
    //   'description': '$serviceName at $shopName',
    // });

    // Placeholder until razorpay_flutter is added to pubspec:
    if (context.mounted) {
      showBBSnackbar(
        context,
        message: 'Add razorpay_flutter to pubspec.yaml to enable payment sheet.',
      );
    }
  }

  Future<void> _payAtShop(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pay at Shop'),
        content: const Text(
            'Confirm cash payment at the shop after your service?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(checkoutProvider.notifier).payAtShop(bookingId, amount);
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: BBTypography.textTheme.bodyMedium
                ?.copyWith(color: colors.textSecondary),
          ),
          Text(
            value,
            style: BBTypography.textTheme.bodyMedium?.copyWith(
              color: valueColor ?? colors.text,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(BBSpacing.base),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(BBRadius.lg),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: BBSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: BBTypography.textTheme.titleMedium?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: BBTypography.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ─── Success view ─────────────────────────────────────────────────────────────

class _SuccessView extends ConsumerWidget {
  const _SuccessView({required this.payment});
  final PaymentRecord payment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: BBColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: BBSpacing.xl),
            Text(
              'Payment Confirmed',
              style: BBTypography.textTheme.headlineSmall?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BBSpacing.sm),
            Text(
              '₹${payment.amount.toStringAsFixed(0)} via ${payment.method}',
              style: BBTypography.textTheme.bodyLarge?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: BBSpacing.xxl),
            BBButton(
              label: 'Done',
              onPressed: () => context.pop(true),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Payment history screen ───────────────────────────────────────────────────

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final async = ref.watch(paymentHistoryProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Payment History',
          style: BBTypography.textTheme.titleLarge?.copyWith(
            color: colors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: async.when(
        loading: () => const BBLoadingScreen(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (payments) => payments.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 48, color: colors.textTertiary),
                    const SizedBox(height: BBSpacing.md),
                    Text(
                      'No payments yet',
                      style: BBTypography.textTheme.titleMedium
                          ?.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                color: BBColors.amber,
                onRefresh: () async =>
                    ref.invalidate(paymentHistoryProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BBSpacing.pageHorizontal,
                    vertical: BBSpacing.base,
                  ),
                  itemCount: payments.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: BBSpacing.sm),
                  itemBuilder: (_, i) => _PaymentCard(payment: payments[i]),
                ),
              ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});
  final PaymentRecord payment;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final statusColor = payment.isPaid
        ? BBColors.success
        : payment.isRefunded
            ? BBColors.info
            : BBColors.warning;

    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              payment.isPaid
                  ? Icons.check_circle_rounded
                  : payment.isRefunded
                      ? Icons.replay_rounded
                      : Icons.pending_rounded,
              size: 20,
              color: statusColor,
            ),
          ),
          const SizedBox(width: BBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.method,
                  style: BBTypography.textTheme.titleSmall?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${payment.createdAt.day}/${payment.createdAt.month}/${payment.createdAt.year}',
                  style: BBTypography.textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${payment.amount.toStringAsFixed(0)}',
                style: BBTypography.textTheme.titleMedium?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(BBRadius.full),
                ),
                child: Text(
                  payment.status,
                  style: BBTypography.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
