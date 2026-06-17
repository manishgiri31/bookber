import 'package:flutter/material.dart';
import '../design/tokens.dart';

// ─────────────────────────────────────────────────────────────
// BB SHIMMER SKELETON — no external shimmer dependency needed
// ─────────────────────────────────────────────────────────────

class BBSkeleton extends StatefulWidget {
  const BBSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = BBRadius.sm,
  });

  const BBSkeleton.text({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = BBRadius.xs,
  });

  const BBSkeleton.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = const BorderRadius.all(Radius.circular(999));

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<BBSkeleton> createState() => _BBSkeletonState();
}

class _BBSkeletonState extends State<BBSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? BBColors.bgElevated : BBColors.bgElevatedLight;
    final highlightColor = isDark
        ? BBColorPrimitives.neutral300.withValues(alpha: 0.5)
        : BBColorPrimitives.neutral800.withValues(alpha: 0.6);

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.5, 1.0],
              colors: [baseColor, highlightColor, baseColor],
              transform: _SlidingGradientTransform(_shimmer.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);
  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

// ─────────────────────────────────────────────────────────────
// SHOP CARD SKELETON
// ─────────────────────────────────────────────────────────────

class ShopCardSkeleton extends StatelessWidget {
  const ShopCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: BBColors.bgSurface,
        borderRadius: BBRadius.card,
        border: Border.all(color: BBColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BBSkeleton(
            width: double.infinity,
            height: 120,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(BBRadius.r20),
              topRight: Radius.circular(BBRadius.r20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(BBSpacing.px14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                BBSkeleton.text(width: 140, height: 16),
                SizedBox(height: BBSpacing.px8),
                BBSkeleton.text(width: 100, height: 12),
                SizedBox(height: BBSpacing.px12),
                BBSkeleton.text(width: double.infinity, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LIST ITEM SKELETON
// ─────────────────────────────────────────────────────────────

class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key, this.hasAvatar = true});

  final bool hasAvatar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpacing.px20,
        vertical: BBSpacing.px10,
      ),
      child: Row(
        children: [
          if (hasAvatar) ...[
            const BBSkeleton.circle(size: 48),
            const SizedBox(width: BBSpacing.px14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                BBSkeleton.text(height: 14),
                SizedBox(height: BBSpacing.px6),
                BBSkeleton.text(width: 160, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// QUEUE CARD SKELETON
// ─────────────────────────────────────────────────────────────

class QueueCardSkeleton extends StatelessWidget {
  const QueueCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
      padding: const EdgeInsets.all(BBSpacing.px24),
      decoration: BoxDecoration(
        color: BBColors.bgSurface,
        borderRadius: BBRadius.xxl,
        border: Border.all(color: BBColors.borderSubtle, width: 1),
      ),
      child: Column(
        children: const [
          BBSkeleton.circle(size: 80),
          SizedBox(height: BBSpacing.px16),
          BBSkeleton.text(width: 120, height: 14),
          SizedBox(height: BBSpacing.px8),
          BBSkeleton.text(width: 180, height: 24),
          SizedBox(height: BBSpacing.px20),
          BBSkeleton.text(height: 12),
          SizedBox(height: BBSpacing.px6),
          BBSkeleton.text(width: 200, height: 12),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SKELETON PAGE WRAPPER — shows N items with stagger
// ─────────────────────────────────────────────────────────────

class BBSkeletonList extends StatelessWidget {
  const BBSkeletonList({
    super.key,
    required this.itemBuilder,
    this.itemCount = 5,
  });

  final Widget Function(int index) itemBuilder;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (i) => AnimatedOpacity(
          opacity: 1.0,
          duration: Duration(milliseconds: 200 + i * 40),
          child: itemBuilder(i),
        ),
      ),
    );
  }
}
