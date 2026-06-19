import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';

class BookingSuccessScreen extends ConsumerStatefulWidget {
  const BookingSuccessScreen({super.key});

  @override
  ConsumerState<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends ConsumerState<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _circleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _circleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

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
                        painter: _CheckmarkPainter(
                          circleProgress: _circleAnimation.value,
                          checkProgress: _checkAnimation.value,
                          color: BBColors.brandPrimary,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: BBSpacing.px32),

                Text(
                  'Booking Confirmed!',
                  style: BBTypography.displayS.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: BBSpacing.px8),

                Text(
                  'BK-2024-001234',
                  style: BBTypography.labelL.copyWith(
                    color: BBColors.brandPrimary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: BBSpacing.px48),

                Container(
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
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colors.bgElevated,
                              borderRadius: BBRadius.md,
                            ),
                          ),
                          const SizedBox(width: BBSpacing.px12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Style Studio',
                                  style: BBTypography.bodyL.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '123 Main Street, Ludhiana',
                                  style: BBTypography.bodyS.copyWith(
                                      color: colors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: BBSpacing.px16),
                      Divider(color: colors.borderSubtle),
                      const SizedBox(height: BBSpacing.px16),

                      Text(
                        'Services',
                        style: BBTypography.labelS.copyWith(color: colors.textSecondary),
                      ),
                      const SizedBox(height: BBSpacing.px8),
                      Text(
                        'Haircut, Beard Trim',
                        style: BBTypography.bodyM.copyWith(color: colors.textPrimary),
                      ),
                      const SizedBox(height: BBSpacing.px16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: BBTypography.labelS.copyWith(
                                      color: colors.textSecondary),
                                ),
                                const SizedBox(height: BBSpacing.px4),
                                Text(
                                  'Jun 5, 2024',
                                  style: BBTypography.bodyM.copyWith(
                                      color: colors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Time',
                                  style: BBTypography.labelS.copyWith(
                                      color: colors.textSecondary),
                                ),
                                const SizedBox(height: BBSpacing.px4),
                                Text(
                                  '2:30 PM',
                                  style: BBTypography.bodyM.copyWith(
                                      color: colors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BBSpacing.px32),

                SizedBox(
                  width: double.infinity,
                  height: BBTouchTarget.button,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Calendar integration coming soon!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text('Add to Calendar', style: BBTypography.button),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BBColors.brandPrimary,
                      side: const BorderSide(color: BBColors.brandPrimary),
                      shape: RoundedRectangleBorder(borderRadius: BBRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: BBSpacing.px16),

                SizedBox(
                  width: double.infinity,
                  height: BBTouchTarget.button,
                  child: ElevatedButton(
                    onPressed: () => context.go('/queue/BK-2024-001234'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BBColors.brandPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BBRadius.pill),
                      elevation: 0,
                    ),
                    child: Text('Track Queue', style: BBTypography.button),
                  ),
                ),
                const SizedBox(height: BBSpacing.px16),

                TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'Back to Home',
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
}

class _CheckmarkPainter extends CustomPainter {
  _CheckmarkPainter({
    required this.circleProgress,
    required this.checkProgress,
    required this.color,
  });

  final double circleProgress;
  final double checkProgress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    if (circleProgress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.5708,
        6.28318 * circleProgress,
        false,
        circlePaint,
      );
    }

    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      final checkSize = radius * 0.6;
      final scale = checkProgress;

      final path = Path()
        ..moveTo(center.dx - checkSize * 0.3 * scale, center.dy)
        ..lineTo(center.dx - checkSize * 0.1 * scale, center.dy + checkSize * 0.2 * scale)
        ..lineTo(center.dx + checkSize * 0.3 * scale, center.dy - checkSize * 0.2 * scale);

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return oldDelegate.circleProgress != circleProgress ||
        oldDelegate.checkProgress != checkProgress;
  }
}
