import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/design_system.dart';
import '../../payment/providers/payment_providers.dart';

class StarRatingWidget extends ConsumerWidget {
  const StarRatingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(reviewFormProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isSelected = starValue <= formState.rating;
        final isPartiallyFilled = starValue == formState.rating + 0.5;

        return GestureDetector(
          onTap: () => ref.read(reviewFormProvider.notifier).setRating(starValue),
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _AnimatedStar(
              isSelected: isSelected,
              isPartiallyFilled: isPartiallyFilled,
              starValue: starValue,
            ),
          ),
        );
      }),
    );
  }
}

class _AnimatedStar extends StatefulWidget {
  const _AnimatedStar({
    required this.isSelected,
    required this.isPartiallyFilled,
    required this.starValue,
  });

  final bool isSelected;
  final bool isPartiallyFilled;
  final int starValue;

  @override
  State<_AnimatedStar> createState() => _AnimatedStarState();
}

class _AnimatedStarState extends State<_AnimatedStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    if (widget.isSelected) {
      _controller.forward().then((_) {
        _controller.reverse();
      });
    }
  }

  @override
  void didUpdateWidget(_AnimatedStar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected && widget.isSelected) {
      _controller.forward().then((_) {
        _controller.reverse();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                  : BookBerPalette.bgElevated,
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isSelected
                    ? const Color(0xFFF59E0B)
                    : BookBerPalette.textMuted,
                width: 2,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.star,
              size: 24,
              color: widget.isSelected
                  ? const Color(0xFFF59E0B)
                  : BookBerPalette.textMuted,
            ),
          ),
        );
      },
    );
  }
}
