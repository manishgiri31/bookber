import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../../../core/network/api_result.dart';
import '../../../core/storage/app_storage.dart';
import 'providers/payment_providers.dart';

class PaymentSuccessScreen extends ConsumerStatefulWidget {
  const PaymentSuccessScreen({super.key, this.paymentId});

  final String? paymentId;

  @override
  ConsumerState<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends ConsumerState<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _receiptAnimation;
  late final Animation<double> _checkAnimation;
  Timer? _reviewTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _receiptAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();
    _reviewTimer = Timer(const Duration(milliseconds: 2500), _goToReview);
  }

  @override
  void dispose() {
    _reviewTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final payment = ref.watch(paymentControllerProvider).valueOrNull;
    final paymentId = widget.paymentId ?? payment?.id;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _ReceiptCheckmarkPainter(
                          receiptProgress: _receiptAnimation.value,
                          checkProgress: _checkAnimation.value,
                          color: BBColors.brandPrimary,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: BBSpacing.px32),
                Text(
                  'Payment Successful',
                  style: BBTypography.displayS.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: BBSpacing.px8),
                Text(
                  payment?.transactionId.isNotEmpty == true
                      ? payment!.transactionId
                      : paymentId ?? '',
                  style: BBTypography.labelL.copyWith(
                    color: BBColors.brandPrimary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: BBSpacing.px48),
                SizedBox(
                  width: double.infinity,
                  height: BBTouchTarget.button,
                  child: OutlinedButton.icon(
                    onPressed: paymentId == null || paymentId.isEmpty
                        ? null
                        : () => _downloadReceipt(context, paymentId),
                    icon: const Icon(Icons.download_outlined),
                    label: Text('Download Receipt', style: BBTypography.button),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BBColors.brandPrimary,
                      side: const BorderSide(color: BBColors.brandPrimary),
                      shape: RoundedRectangleBorder(borderRadius: BBRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: BBSpacing.px16),
                TextButton(
                  onPressed: _goToReview,
                  child: Text(
                    'Continue',
                    style: BBTypography.labelM.copyWith(color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadReceipt(BuildContext context, String paymentId) async {
    final result = await ref.read(paymentRepositoryProvider).getReceiptUrl(paymentId);
    if (!mounted) return;

    switch (result) {
      case ApiSuccess<String>(:final data):
        final uri = Uri.tryParse(data);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      case ApiError<String>(:final message, :final code):
        if (code == 'SESSION_EXPIRED' || code == '401') {
          await ref.read(appStorageProvider).clearTokens();
          if (mounted) context.go(RoutePaths.login);
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open receipt: $message')),
        );
    }
  }

  void _goToReview() {
    if (!mounted) return;
    final bookingId = ref.read(paymentControllerProvider).valueOrNull?.bookingId;
    if (bookingId != null && bookingId.isNotEmpty) {
      context.go(RoutePaths.review.replaceFirst(':bookingId', bookingId));
    } else {
      context.go(RoutePaths.home);
    }
  }
}

class _ReceiptCheckmarkPainter extends CustomPainter {
  _ReceiptCheckmarkPainter({
    required this.receiptProgress,
    required this.checkProgress,
    required this.color,
  });

  final double receiptProgress;
  final double checkProgress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final receiptPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    if (receiptProgress > 0) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromCircle(center: center, radius: radius * 0.7),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, receiptPaint);
    }

    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      final checkSize = radius * 0.5;
      final scale = checkProgress;
      final path = Path()
        ..moveTo(center.dx - checkSize * 0.3 * scale, center.dy)
        ..lineTo(center.dx - checkSize * 0.1 * scale, center.dy + checkSize * 0.2 * scale)
        ..lineTo(center.dx + checkSize * 0.3 * scale, center.dy - checkSize * 0.2 * scale);

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(_ReceiptCheckmarkPainter oldDelegate) {
    return oldDelegate.receiptProgress != receiptProgress ||
        oldDelegate.checkProgress != checkProgress;
  }
}
