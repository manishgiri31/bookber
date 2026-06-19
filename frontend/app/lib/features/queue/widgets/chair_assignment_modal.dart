import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';

class ChairAssignmentModal extends ConsumerStatefulWidget {
  const ChairAssignmentModal({super.key});

  @override
  ConsumerState<ChairAssignmentModal> createState() =>
      _ChairAssignmentModalState();
}

class _ChairAssignmentModalState extends ConsumerState<ChairAssignmentModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(opacity: _controller, child: child),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(BBSpacing.px32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: BBSpacing.px32),
                  decoration: BoxDecoration(
                    color: colors.textDisabled,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: BBColors.brandPrimaryDim,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_downward,
                          size: 40,
                          color: BBColors.brandPrimary,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: BBSpacing.px24),

                Text(
                  "You're Next! 🎉",
                  style: BBTypography.displayS.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: BBSpacing.px16),

                Text(
                  'Proceed to Chair 2',
                  style: BBTypography.headingS.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: BBSpacing.px32),

                _ChairVisualization(chairNumber: 2),
                const SizedBox(height: BBSpacing.px32),

                SizedBox(
                  width: double.infinity,
                  height: BBTouchTarget.button,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BBColors.brandPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BBRadius.pill),
                      elevation: 0,
                    ),
                    child: Text("I'm Here", style: BBTypography.button),
                  ),
                ),
                const SizedBox(height: BBSpacing.px16),

                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
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

class _ChairVisualization extends StatelessWidget {
  const _ChairVisualization({required this.chairNumber});

  final int chairNumber;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BBRadius.card,
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_seat, size: 48, color: BBColors.brandPrimary),
                const SizedBox(height: BBSpacing.px8),
                Text(
                  'Chair $chairNumber',
                  style: BBTypography.headingS.copyWith(color: colors.textPrimary),
                ),
              ],
            ),
          ),
          Positioned.fill(child: Center(child: _PulsingGlow())),
        ],
      ),
    );
  }
}

class _PulsingGlow extends StatefulWidget {
  @override
  State<_PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<_PulsingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 80 * _animation.value,
          height: 80 * _animation.value,
          decoration: BoxDecoration(
            color: BBColors.brandPrimary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
