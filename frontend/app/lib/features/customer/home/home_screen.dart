import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/widgets/bb_empty_state.dart';
import '../../../core/widgets/bb_error_widget.dart';
import '../../../core/widgets/bb_loading.dart';
import '../../auth/data/auth_provider.dart';
import '../../shared/domain/shop_models.dart';
import 'home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final homeState = ref.watch(homeProvider);
    final colors = context.bbColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: BBColors.amber,
          backgroundColor: colors.surface,
          onRefresh: () => ref.read(homeProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BBSpacing.pageHorizontal,
                    BBSpacing.base,
                    BBSpacing.pageHorizontal,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(userName: user?.name),
                      const SizedBox(height: BBSpacing.xl),
                      _SearchBar(),
                      const SizedBox(height: BBSpacing.base),
                    ],
                  ),
                ),
              ),

              // Location permission nudge
              _LocationNudge(),

              // Active booking banner
              _ActiveBookingBanner(),

              if (homeState.isLoading)
                const SliverFillRemaining(
                  child: Center(child: BBLoader()),
                )
              else if (homeState.error != null)
                SliverFillRemaining(
                  child: BBErrorWidget(
                    error: homeState.error!,
                    onRetry: () =>
                        ref.read(homeProvider.notifier).refresh(),
                  ),
                )
              else ...[
                if (homeState.shops.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BBSpacing.pageHorizontal,
                      ),
                      child: _SectionHeader(
                        title: 'Nearby Shops',
                        onSeeAll: () => context.go('/shops'),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: BBSpacing.md)),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BBSpacing.pageHorizontal,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: homeState.shops.take(8).length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: BBSpacing.md),
                        itemBuilder: (ctx, i) =>
                            _ShopCard(shop: homeState.shops[i]),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: BBSpacing.xl)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BBSpacing.pageHorizontal,
                      ),
                      child: _SectionHeader(title: 'All Shops'),
                    ),
                  ),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: BBSpacing.md)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BBSpacing.pageHorizontal,
                    ),
                    sliver: SliverList.separated(
                      itemCount: homeState.shops.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: BBSpacing.sm),
                      itemBuilder: (ctx, i) =>
                          _ShopListTile(shop: homeState.shops[i]),
                    ),
                  ),
                ] else
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: const BBEmptyState(
                      title: 'No shops nearby',
                      subtitle:
                          'We couldn\'t find any barber shops in your area.',
                      icon: Icons.store_outlined,
                    ),
                  ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: BBSpacing.xxl)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.userName});
  final String? userName;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final first = userName?.split(' ').first ?? 'there';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good ${_greeting()},',
                style: BBTypography.textTheme.bodyLarge?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              Text(
                first,
                style: BBTypography.textTheme.displaySmall?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: BBColors.amber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: BBColors.amber.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(
                (userName?.isNotEmpty == true)
                    ? userName![0].toUpperCase()
                    : '?',
                style: BBTypography.textTheme.titleLarge?.copyWith(
                  color: BBColors.amber,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return GestureDetector(
      onTap: () => context.push('/shops'),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: BBSpacing.base),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(BBRadius.md),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                size: 20, color: colors.textTertiary),
            const SizedBox(width: BBSpacing.sm),
            Expanded(
              child: Text(
                'Search barber shops...',
                style: BBTypography.textTheme.bodyLarge?.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(BBRadius.sm),
              ),
              child: Text(
                'Search',
                style: BBTypography.textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationNudge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationProvider);
    // Only show nudge when we know location is unavailable (not loading)
    if (locationAsync.isLoading || locationAsync.valueOrNull != null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BBSpacing.pageHorizontal,
          0,
          BBSpacing.pageHorizontal,
          BBSpacing.md,
        ),
        child: GestureDetector(
          onTap: () => ref.read(locationProvider.notifier).refresh(),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: BBSpacing.base,
              vertical: BBSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: BBColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(BBRadius.md),
              border: Border.all(
                  color: BBColors.info.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_off_rounded,
                    size: 16, color: BBColors.info),
                const SizedBox(width: BBSpacing.sm),
                Expanded(
                  child: Text(
                    'Enable location to see nearby shops',
                    style: BBTypography.textTheme.bodySmall?.copyWith(
                      color: BBColors.info,
                    ),
                  ),
                ),
                Text(
                  'Enable',
                  style: BBTypography.textTheme.labelSmall?.copyWith(
                    color: BBColors.info,
                    fontWeight: FontWeight.w700,
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

class _ActiveBookingBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeBookingsProvider);
    final bookings = async.valueOrNull ?? [];
    if (bookings.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final booking = bookings.first;
    final colors = context.bbColors;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BBSpacing.pageHorizontal,
          0,
          BBSpacing.pageHorizontal,
          BBSpacing.base,
        ),
        child: GestureDetector(
          onTap: () => context.push('/queue/${booking.id}'),
          child: Container(
            padding: const EdgeInsets.all(BBSpacing.base),
            decoration: BoxDecoration(
              color: BBColors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(BBRadius.lg),
              border: Border.all(
                  color: BBColors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: BBColors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.queue_rounded,
                    size: 18,
                    color: BBColors.amber,
                  ),
                ),
                const SizedBox(width: BBSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active booking at ${booking.shopName}',
                        style: BBTypography.textTheme.labelLarge?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Tap to track your queue position',
                        style: BBTypography.textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: BBColors.amber,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: BBTypography.textTheme.titleLarge?.copyWith(
            color: colors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See all',
              style: BBTypography.textTheme.labelMedium?.copyWith(
                color: BBColors.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return GestureDetector(
      onTap: () => context.push('/shops/${shop.id}'),
      child: Container(
        width: 190,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(BBRadius.lg),
          border: Border.all(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              color: colors.surfaceVariant,
              child: Center(
                child: Icon(
                  Icons.content_cut_rounded,
                  size: 40,
                  color: colors.textTertiary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(BBSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    style: BBTypography.textTheme.titleMedium?.copyWith(
                      color: colors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: BBColors.amber),
                      const SizedBox(width: 3),
                      Text(
                        '${shop.rating.toStringAsFixed(1)} · ${shop.waitLabel}',
                        style: BBTypography.textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: shop.isOpen
                              ? BBColors.success.withValues(alpha: 0.12)
                              : BBColors.error.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(BBRadius.full),
                        ),
                        child: Text(
                          shop.isOpen ? 'Open' : 'Closed',
                          style: BBTypography.textTheme.labelSmall?.copyWith(
                            color: shop.isOpen
                                ? BBColors.success
                                : BBColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (shop.distanceKm != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          shop.distanceLabel,
                          style:
                              BBTypography.textTheme.labelSmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopListTile extends StatelessWidget {
  const _ShopListTile({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return GestureDetector(
      onTap: () => context.push('/shops/${shop.id}'),
      child: Container(
        padding: const EdgeInsets.all(BBSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(BBRadius.lg),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(BBRadius.md),
              ),
              child: Center(
                child: Icon(
                  Icons.content_cut_rounded,
                  size: 22,
                  color: colors.textTertiary,
                ),
              ),
            ),
            const SizedBox(width: BBSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    style: BBTypography.textTheme.titleMedium?.copyWith(
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shop.address,
                    style: BBTypography.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: BBColors.amber),
                      const SizedBox(width: 3),
                      Text(
                        shop.rating.toStringAsFixed(1),
                        style: BBTypography.textTheme.labelSmall?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: BBSpacing.sm),
                      Icon(Icons.timer_outlined,
                          size: 13, color: colors.textTertiary),
                      const SizedBox(width: 3),
                      Text(
                        shop.waitLabel,
                        style: BBTypography.textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      if (shop.distanceKm != null) ...[
                        const SizedBox(width: BBSpacing.sm),
                        Icon(Icons.near_me_outlined,
                            size: 13, color: colors.textTertiary),
                        const SizedBox(width: 3),
                        Text(
                          shop.distanceLabel,
                          style:
                              BBTypography.textTheme.labelSmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: BBSpacing.sm),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
