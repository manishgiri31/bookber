import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/providers/providers.dart';

/// Customer-side QR scanner. Scans the barber's permanent QR code,
/// POSTs the token to /bookings/check-in/scan, and on success pops
/// back to the queue tracker (which will reflect the updated status).
class ScanCheckInScreen extends ConsumerStatefulWidget {
  const ScanCheckInScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<ScanCheckInScreen> createState() => _ScanCheckInScreenState();
}

class _ScanCheckInScreenState extends ConsumerState<ScanCheckInScreen> {
  final _controller = MobileScannerController();
  bool _processing = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || _done) return;
    final barcode = capture.barcodes.firstOrNull;
    final token = barcode?.rawValue;
    if (token == null || token.isEmpty) return;

    setState(() {
      _processing = true;
      _error = null;
    });
    await _controller.stop();

    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        ApiEndpoints.checkInScan,
        body: {'token': token},
      );
      if (!mounted) return;
      setState(() {
        _done = true;
        _processing = false;
      });
      // Small delay to show the success state before navigating back.
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e.toString());
        _processing = false;
      });
      // Resume scanning so the user can try again.
      await _controller.start();
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('403') || raw.contains('FORBIDDEN')) {
      return 'Wrong barber QR — please scan your assigned barber\'s code.';
    }
    if (raw.contains('404') || raw.contains('NOT_FOUND')) {
      return 'QR code not recognised. Ask your barber for the correct code.';
    }
    if (raw.contains('409') || raw.contains('CONFLICT')) {
      return 'You\'re already checked in or your booking has ended.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barber QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.bolt),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Toggle torch',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // Bottom status panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                BBSpacing.pageHorizontal,
                BBSpacing.xl,
                BBSpacing.pageHorizontal,
                BBSpacing.xxl,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
              ),
              child: _done
                  ? _SuccessPanel()
                  : _processing
                      ? _ProcessingPanel()
                      : _error != null
                          ? _ErrorPanel(
                              error: _error!,
                              onRetry: () => setState(() => _error = null),
                            )
                          : _InstructionPanel(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── Overlay painter ───────────────

class _ScannerOverlayPainter extends CustomPainter {
  static const _cutoutSize = 240.0;
  static const _cornerLength = 28.0;
  static const _cornerRadius = 6.0;
  static const _cornerWidth = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final cutoutLeft = (size.width - _cutoutSize) / 2;
    final cutoutTop = (size.height - _cutoutSize) / 2 - 60;
    final cutout = Rect.fromLTWH(cutoutLeft, cutoutTop, _cutoutSize, _cutoutSize);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(
              cutout, const Radius.circular(_cornerRadius))),
      ),
      paint,
    );

    // Corner accents
    final accent = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cornerWidth
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(cutoutLeft, cutoutTop + _cornerLength),
        Offset(cutoutLeft, cutoutTop + _cornerRadius), accent);
    canvas.drawLine(Offset(cutoutLeft + _cornerRadius, cutoutTop),
        Offset(cutoutLeft + _cornerLength, cutoutTop), accent);
    // Top-right
    canvas.drawLine(
        Offset(cutoutLeft + _cutoutSize, cutoutTop + _cornerLength),
        Offset(cutoutLeft + _cutoutSize, cutoutTop + _cornerRadius), accent);
    canvas.drawLine(
        Offset(cutoutLeft + _cutoutSize - _cornerRadius, cutoutTop),
        Offset(cutoutLeft + _cutoutSize - _cornerLength, cutoutTop), accent);
    // Bottom-left
    canvas.drawLine(
        Offset(cutoutLeft, cutoutTop + _cutoutSize - _cornerLength),
        Offset(cutoutLeft, cutoutTop + _cutoutSize - _cornerRadius), accent);
    canvas.drawLine(
        Offset(cutoutLeft + _cornerRadius, cutoutTop + _cutoutSize),
        Offset(cutoutLeft + _cornerLength, cutoutTop + _cutoutSize), accent);
    // Bottom-right
    canvas.drawLine(
        Offset(cutoutLeft + _cutoutSize,
            cutoutTop + _cutoutSize - _cornerLength),
        Offset(
            cutoutLeft + _cutoutSize, cutoutTop + _cutoutSize - _cornerRadius),
        accent);
    canvas.drawLine(
        Offset(cutoutLeft + _cutoutSize - _cornerRadius,
            cutoutTop + _cutoutSize),
        Offset(cutoutLeft + _cutoutSize - _cornerLength,
            cutoutTop + _cutoutSize),
        accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────── Status panels ───────────────

class _InstructionPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(AppIcons.qrCode, color: Colors.white70, size: 32),
        const SizedBox(height: 12),
        const Text(
          'Point your camera at the QR code\ndisplayed at your barber\'s workstation.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ProcessingPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            color: BBColors.amber,
            strokeWidth: 3,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Checking in…',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }
}

class _SuccessPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(AppIcons.checkCircleFill,
            color: BBColors.success, size: 48),
        const SizedBox(height: 12),
        Text(
          'Checked in!',
          style: BBTypography.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your service has started. Enjoy!',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(AppIcons.error, color: BBColors.error, size: 40),
        const SizedBox(height: 12),
        Text(
          error,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: onRetry,
          child: const Text(
            'Try again',
            style: TextStyle(color: BBColors.amber, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
