import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../design/bb_colors.dart';
import '../design/bb_tokens.dart';

class BBLoader extends StatelessWidget {
  const BBLoader({super.key, this.size = 24, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? context.bbColors.accent,
        ),
      ),
    );
  }
}

class BBLoadingScreen extends StatelessWidget {
  const BBLoadingScreen({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BBLoader(size: 32),
            if (message != null) ...[
              const SizedBox(height: BBSpacing.base),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BBShimmerBox extends StatelessWidget {
  const BBShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = BBRadius.md,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1A1A1C) : const Color(0xFFE5E5E5),
      highlightColor: isDark ? const Color(0xFF2A2A2C) : const Color(0xFFF5F5F5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1C) : const Color(0xFFE5E5E5),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class BBShimmerList extends StatelessWidget {
  const BBShimmerList({super.key, this.itemCount = 4, this.itemHeight = 80});
  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: BBSpacing.md),
      itemBuilder: (_, _) => BBShimmerBox(
        width: double.infinity,
        height: itemHeight,
        radius: BBRadius.lg,
      ),
    );
  }
}

/// Generic skeleton for list screens. Shows [itemCount] placeholder card items
/// (icon box + two text lines) while data is loading.
class BBSkeletonListView extends StatelessWidget {
  const BBSkeletonListView({
    super.key,
    this.itemCount = 4,
    this.padding,
  });
  final int itemCount;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return ListView.separated(
      padding: padding ?? const EdgeInsets.all(BBSpacing.pageHorizontal),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: BBSpacing.sm),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(BBSpacing.base),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(BBRadius.lg),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BBShimmerBox(width: 44, height: 44, radius: BBRadius.md),
            const SizedBox(width: BBSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  BBShimmerBox(width: double.infinity, height: 14),
                  const SizedBox(height: 8),
                  BBShimmerBox(width: 160, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile skeleton — avatar, name, stats row, section blocks.
class BBSkeletonProfile extends StatelessWidget {
  const BBSkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpacing.pageHorizontal,
        vertical: BBSpacing.pageVertical,
      ),
      children: [
        Center(
          child: Column(
            children: [
              BBShimmerBox(width: 80, height: 80, radius: 40),
              const SizedBox(height: BBSpacing.md),
              BBShimmerBox(width: 140, height: 18),
              const SizedBox(height: BBSpacing.xs),
              BBShimmerBox(width: 100, height: 14),
            ],
          ),
        ),
        const SizedBox(height: BBSpacing.xl),
        Row(
          children: [
            Expanded(
              child: BBShimmerBox(
                  width: double.infinity, height: 80, radius: BBRadius.lg),
            ),
            const SizedBox(width: BBSpacing.sm),
            Expanded(
              child: BBShimmerBox(
                  width: double.infinity, height: 80, radius: BBRadius.lg),
            ),
            const SizedBox(width: BBSpacing.sm),
            Expanded(
              child: BBShimmerBox(
                  width: double.infinity, height: 80, radius: BBRadius.lg),
            ),
          ],
        ),
        const SizedBox(height: BBSpacing.xl),
        BBShimmerBox(
            width: double.infinity, height: 110, radius: BBRadius.lg),
        const SizedBox(height: BBSpacing.base),
        BBShimmerBox(width: double.infinity, height: 60, radius: BBRadius.lg),
        const SizedBox(height: BBSpacing.base),
        BBShimmerBox(width: double.infinity, height: 60, radius: BBRadius.lg),
      ],
    );
  }
}
