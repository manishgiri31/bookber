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

/// Barber dashboard skeleton — header, revenue card, stats row, action grid, queue cards.
class BBSkeletonBarberDashboard extends StatelessWidget {
  const BBSkeletonBarberDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: BBSpacing.pageHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: BBSpacing.base),
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BBShimmerBox(width: 110, height: 14),
                      const SizedBox(height: 6),
                      BBShimmerBox(width: 180, height: 28),
                      const SizedBox(height: 6),
                      BBShimmerBox(width: 130, height: 12),
                    ],
                  ),
                ),
                BBShimmerBox(width: 90, height: 32, radius: BBRadius.full),
              ],
            ),
            const SizedBox(height: BBSpacing.xl),
            // Revenue card
            BBShimmerBox(width: double.infinity, height: 88, radius: BBRadius.xl),
            const SizedBox(height: BBSpacing.md),
            // Stats row — 3 cards
            Row(
              children: [
                Expanded(child: BBShimmerBox(width: double.infinity, height: 80, radius: BBRadius.lg)),
                const SizedBox(width: BBSpacing.sm),
                Expanded(child: BBShimmerBox(width: double.infinity, height: 80, radius: BBRadius.lg)),
                const SizedBox(width: BBSpacing.sm),
                Expanded(child: BBShimmerBox(width: double.infinity, height: 80, radius: BBRadius.lg)),
              ],
            ),
            const SizedBox(height: BBSpacing.xl),
            // Quick actions title
            BBShimmerBox(width: 130, height: 20),
            const SizedBox(height: BBSpacing.md),
            // Action grid — 3 rows of 3
            for (int r = 0; r < 3; r++) ...[
              Row(
                children: [
                  Expanded(child: BBShimmerBox(width: double.infinity, height: 48, radius: BBRadius.lg)),
                  const SizedBox(width: BBSpacing.sm),
                  Expanded(child: BBShimmerBox(width: double.infinity, height: 48, radius: BBRadius.lg)),
                  const SizedBox(width: BBSpacing.sm),
                  Expanded(child: BBShimmerBox(width: double.infinity, height: 48, radius: BBRadius.lg)),
                ],
              ),
              const SizedBox(height: BBSpacing.sm),
            ],
            const SizedBox(height: BBSpacing.md),
            // Live Queue header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BBShimmerBox(width: 100, height: 20),
                BBShimmerBox(width: 70, height: 24, radius: BBRadius.full),
              ],
            ),
            const SizedBox(height: BBSpacing.md),
            // Queue cards
            for (int i = 0; i < 3; i++) ...[
              BBShimmerBox(width: double.infinity, height: 80, radius: BBRadius.lg),
              const SizedBox(height: BBSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

/// Analytics skeleton — insight 2×2 grid, today stats, chart boxes, services list.
class BBSkeletonAnalytics extends StatelessWidget {
  const BBSkeletonAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpacing.pageHorizontal,
        vertical: BBSpacing.base,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          BBShimmerBox(width: 100, height: 20),
          const SizedBox(height: BBSpacing.md),
          // 2×2 insight cards
          Row(
            children: [
              Expanded(child: BBShimmerBox(width: double.infinity, height: 90, radius: BBRadius.lg)),
              const SizedBox(width: BBSpacing.sm),
              Expanded(child: BBShimmerBox(width: double.infinity, height: 90, radius: BBRadius.lg)),
            ],
          ),
          const SizedBox(height: BBSpacing.sm),
          Row(
            children: [
              Expanded(child: BBShimmerBox(width: double.infinity, height: 90, radius: BBRadius.lg)),
              const SizedBox(width: BBSpacing.sm),
              Expanded(child: BBShimmerBox(width: double.infinity, height: 90, radius: BBRadius.lg)),
            ],
          ),
          const SizedBox(height: BBSpacing.xl),
          // Today section
          BBShimmerBox(width: 70, height: 20),
          const SizedBox(height: BBSpacing.md),
          Row(
            children: List.generate(4, (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 3 ? BBSpacing.sm : 0),
                child: BBShimmerBox(width: double.infinity, height: 56, radius: BBRadius.md),
              ),
            )),
          ),
          const SizedBox(height: BBSpacing.md),
          BBShimmerBox(width: double.infinity, height: 72, radius: BBRadius.lg),
          const SizedBox(height: BBSpacing.xl),
          // Peak hours chart
          BBShimmerBox(width: 180, height: 20),
          const SizedBox(height: BBSpacing.md),
          BBShimmerBox(width: double.infinity, height: 180, radius: BBRadius.lg),
          const SizedBox(height: BBSpacing.xl),
          // Revenue chart
          BBShimmerBox(width: 120, height: 20),
          const SizedBox(height: BBSpacing.md),
          BBShimmerBox(width: double.infinity, height: 180, radius: BBRadius.lg),
          const SizedBox(height: BBSpacing.xl),
          // Popular services
          BBShimmerBox(width: 150, height: 20),
          const SizedBox(height: BBSpacing.md),
          BBShimmerBox(width: double.infinity, height: 220, radius: BBRadius.lg),
          const SizedBox(height: BBSpacing.xxl),
        ],
      ),
    );
  }
}

/// Shop management skeleton — tab content placeholder.
class BBSkeletonShopManagement extends StatelessWidget {
  const BBSkeletonShopManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      children: [
        BBShimmerBox(width: double.infinity, height: 48, radius: BBRadius.lg),
        const SizedBox(height: BBSpacing.md),
        for (int i = 0; i < 5; i++) ...[
          BBShimmerBox(width: double.infinity, height: 68, radius: BBRadius.lg),
          const SizedBox(height: BBSpacing.sm),
        ],
        const SizedBox(height: BBSpacing.md),
        BBShimmerBox(width: double.infinity, height: 44, radius: BBRadius.lg),
      ],
    );
  }
}

/// Wallet skeleton — balance card + transaction list.
class BBSkeletonWallet extends StatelessWidget {
  const BBSkeletonWallet({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bbColors.background,
      appBar: AppBar(
        backgroundColor: context.bbColors.background,
        title: BBShimmerBox(width: 80, height: 18),
      ),
      body: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.pageHorizontal,
          vertical: BBSpacing.pageVertical,
        ),
        children: [
          BBShimmerBox(width: double.infinity, height: 130, radius: BBRadius.xl),
          const SizedBox(height: BBSpacing.lg),
          BBShimmerBox(width: double.infinity, height: 48, radius: BBRadius.lg),
          const SizedBox(height: BBSpacing.xl),
          BBShimmerBox(width: 160, height: 12),
          const SizedBox(height: BBSpacing.sm),
          for (int i = 0; i < 5; i++) ...[
            BBShimmerBox(width: double.infinity, height: 64, radius: BBRadius.lg),
            const SizedBox(height: BBSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Shop detail skeleton — hero image, name block, tab bar, content.
class BBSkeletonShopDetail extends StatelessWidget {
  const BBSkeletonShopDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          BBShimmerBox(width: double.infinity, height: 260, radius: 0),
          Padding(
            padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: BBSpacing.md),
                BBShimmerBox(width: 200, height: 22),
                const SizedBox(height: BBSpacing.sm),
                BBShimmerBox(width: 260, height: 14),
                const SizedBox(height: BBSpacing.sm),
                BBShimmerBox(width: 140, height: 14),
                const SizedBox(height: BBSpacing.xl),
                Row(
                  children: List.generate(4, (i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 3 ? 8.0 : 0),
                      child: BBShimmerBox(width: double.infinity, height: 36, radius: BBRadius.full),
                    ),
                  )),
                ),
                const SizedBox(height: BBSpacing.xl),
                for (int i = 0; i < 4; i++) ...[
                  BBShimmerBox(width: double.infinity, height: 68, radius: BBRadius.lg),
                  const SizedBox(height: BBSpacing.sm),
                ],
              ],
            ),
          ),
        ],
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
