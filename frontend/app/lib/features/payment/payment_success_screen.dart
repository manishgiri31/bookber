import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/design_system.dart';
import '../../../core/network/api_result.dart';
import '../../../core/providers/auth_provider.dart';
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
    final payment = ref.watch(paymentControllerProvider).valueOrNull;
    final paymentId = widget.paymentId ?? payment?.id;

    return Scaffold(
      backgroundColor: BookBerPalette.bgPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
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
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Payment Successful',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: BookBerPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  payment?.transactionId.isNotEmpty == true ? payment!.transactionId : paymentId ?? '',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: BookBerPalette.primaryAccent,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: paymentId == null || paymentId.isEmpty
                        ? null
                        : () => _downloadReceipt(context, paymentId),
                    icon: const Icon(Icons.download_outlined),
                    label: Text(
                      'Download Receipt',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BookBerPalette.primaryAccent,
                      side: const BorderSide(color: BookBerPalette.primaryAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _goToReview,
                  child: Text(
                    'Continue',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: BookBerPalette.textSecondary,
                    ),
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
  });

  final double receiptProgress;
  final double checkProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final receiptPaint = Paint()
      ..color = BookBerPalette.primaryAccent
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
        ..color = BookBerPalette.primaryAccent
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
