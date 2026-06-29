import 'package:flutter/material.dart';
import '../../../core/design/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/notifications_provider.dart';
import '../../../core/widgets/bb_empty_state.dart';
import '../../../core/widgets/bb_error_widget.dart';
import '../../../core/widgets/bb_loading.dart';
import '../../auth/data/auth_provider.dart';
import '../../shared/domain/shop_models.dart';
import '../booking/booking_provider.dart';
import 'discovery_provider.dart';
import 'home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final homeState = ref.watch(homeProvider);
    final colors = context.bbColors;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        color: colors.accent,
        backgroundColor: colors.surface,
        onRefresh: () => ref.read(homeProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Hero header with gradient ──────────────────────────────────
            SliverToBoxAdapter(
              child: _HeroHeader(userName: user?.name, isDark: isDark),
            ),

            // Location permission nudge
            _LocationNudge(),

            // Active booking banner
            _ActiveBookingBanner(),

            // Quick rebook (last completed booking)
            _QuickRebookCard(),

            // Service category chips
            const SliverToBoxAdapter(child: _ServiceCategoriesSection()),

            // Quick actions row
            const SliverToBoxAdapter(child: _QuickActions()),

            // Discovery: nearby shops (with skeleton)
            _NearbySection(),

            // Discovery: top-rated shops (with skeleton)
            _TopRatedSection(),

            // Trending barbers
            const SliverToBoxAdapter(child: _TrendingBarbersSection()),

            // Recently visited
            _RecentlyVisitedSection(),

            // All shops list
            if (homeState.isLoading)
              const SliverToBoxAdapter(child: SizedBox(height: BBSpacing.md))
            else if (homeState.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: BBSpacing.pageHorizontal),
                  child: BBErrorWidget(
                    error: homeState.error!,
                    onRetry: () => ref.read(homeProvider.notifier).refresh(),
                  ),
                ),
              )
            else if (homeState.shops.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BBSpacing.pageHorizontal, 0, BBSpacing.pageHorizontal, BBSpacing.md),
                  child: _SectionHeader(
                    title: 'All Shops',
                    onSeeAll: () => context.go('/shops'),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: BBSpacing.pageHorizontal),
                sliver: SliverList.separated(
                  itemCount: homeState.shops.length,
                  separatorBuilder: (_, _) => const SizedBox(height: BBSpacing.sm),
                  itemBuilder: (ctx, i) => _ShopListTile(shop: homeState.shops[i]),
                ),
              ),
            ] else if (!homeState.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: BBSpacing.pageHorizontal),
                  child: BBEmptyState(
                    title: 'No shops yet',
                    subtitle: 'Check back soon — shops are being added.',
                    icon: AppIcons.store,
                  ),
                ),
              ),

            // Bottom padding for floating nav
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Header ──────────────────────────────────────────────────────────────

class _HeroHeader extends ConsumerWidget {
  const _HeroHeader({this.userName, required this.isDark});
  final String? userName;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final first = userName?.split(' ').first ?? 'there';
    final unread = ref.watch(notificationsProvider.select((s) => s.unreadCount));
    final locationAsync = ref.watch(locationProvider);
    final cityName = locationAsync.valueOrNull?.cityName;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF1C0A00),
                  const Color(0xFF0A0000),
                  const Color(0xFF000000),
                ]
              : [
                  const Color(0xFFFFF0CC),
                  const Color(0xFFFFF8E8),
                  colors.background,
                ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BBSpacing.pageHorizontal,
            BBSpacing.base,
            BBSpacing.pageHorizontal,
            BBSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar: location + actions ──
              Row(
                children: [
                  GestureDetector(
                    onTap: () => ref.read(locationProvider.notifier).refresh(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.locationOnFill,
                            size: 16, color: BBColors.amber),
                        const SizedBox(width: 4),
                        locationAsync.isLoading
                            ? Container(
                                width: 80,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(BBRadius.xs),
                                ),
                              )
                            : Text(
                                cityName ?? 'Your Location',
                                style: BBTypography.textTheme.labelMedium?.copyWith(
                                  color: colors.text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        if (cityName != null) ...[
                          const SizedBox(width: 2),
                          Icon(AppIcons.arrowDown,
                              size: 16, color: colors.textSecondary),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Notification
                  _IconAction(
                    onTap: () {
                      ref.read(notificationsProvider.notifier).markAllRead();
                      context.push('/notifications');
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(AppIcons.bell,
                            size: 22, color: colors.textSecondary),
                        if (unread > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: BBColors.amber,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  unread > 9 ? '9+' : '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: BBSpacing.sm),
                  // Avatar
                  _IconAction(
                    onTap: () => context.push('/profile'),
                    accent: true,
                    child: Text(
                      (userName?.isNotEmpty == true) ? userName![0].toUpperCase() : '?',
                      style: BBTypography.textTheme.titleMedium?.copyWith(
                        color: BBColors.amber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: BBSpacing.lg),

              // ── Greeting ──
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
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  height: 1.1,
                ),
              ),

              const SizedBox(height: BBSpacing.lg),

              // ── Search bar ──
              _SearchBar(),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.onTap, required this.child, this.accent = false});
  final VoidCallback onTap;
  final Widget child;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: accent
              ? BBColors.amber.withValues(alpha: 0.15)
              : colors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return GestureDetector(
      onTap: () => context.push('/shops'),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: BBSpacing.base),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(BBRadius.full),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? 0.4 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(AppIcons.search, size: 20, color: colors.textTertiary),
            const SizedBox(width: BBSpacing.sm),
            Expanded(
              child: Text(
                'Search barbers, shops...',
                style: BBTypography.textTheme.bodyLarge?.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: BBColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BBRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.filter, size: 14, color: BBColors.amber),
                  const SizedBox(width: 4),
                  Text(
                    'Filter',
                    style: BBTypography.textTheme.labelSmall?.copyWith(
                      color: BBColors.amber,
                      fontWeight: FontWeight.w600,
                    ),
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

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BBSpacing.pageHorizontal, 0, BBSpacing.pageHorizontal, BBSpacing.xl),
      child: Row(
        children: [
          _QuickActionChip(
            icon: AppIcons.bolt,
            label: 'Book Now',
            color: BBColors.amber,
            onTap: () => context.go('/shops'),
          ),
          const SizedBox(width: BBSpacing.sm),
          _QuickActionChip(
            icon: AppIcons.nearMe,
            label: 'Nearby',
            color: BBColors.info,
            onTap: () => context.go('/shops'),
          ),
          const SizedBox(width: BBSpacing.sm),
          _QuickActionChip(
            icon: AppIcons.starFill,
            label: 'Top Rated',
            color: BBColors.warning,
            onTap: () => context.go('/shops'),
          ),
          const SizedBox(width: BBSpacing.sm),
          _QuickActionChip(
            icon: AppIcons.history,
            label: 'History',
            color: BBColors.success,
            onTap: () => context.go('/bookings'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: BBSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BBRadius.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, size: 18, color: color),
                ),
              ),
              const SizedBox(height: BBSpacing.xs),
              Text(
                label,
                style: BBTypography.textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Location Nudge ───────────────────────────────────────────────────────────

class _LocationNudge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationProvider);
    if (locationAsync.isLoading || locationAsync.valueOrNull != null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BBSpacing.pageHorizontal, 0, BBSpacing.pageHorizontal, BBSpacing.base),
        child: GestureDetector(
          onTap: () => ref.read(locationProvider.notifier).refresh(),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: BBSpacing.base, vertical: BBSpacing.sm),
            decoration: BoxDecoration(
              color: BBColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(BBRadius.xl),
            ),
            child: Row(
              children: [
                const Icon(AppIcons.locationOff, size: 16, color: BBColors.info),
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

// ─── Active Booking Banner ────────────────────────────────────────────────────

class _ActiveBookingBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeBookingsProvider);
    final bookings = async.valueOrNull ?? [];
    if (bookings.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    final booking = bookings.first;
    final colors = context.bbColors;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BBSpacing.pageHorizontal, 0, BBSpacing.pageHorizontal, BBSpacing.base),
        child: GestureDetector(
          onTap: () => context.push('/queue/${booking.id}'),
          child: Container(
            padding: const EdgeInsets.all(BBSpacing.base),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BBColors.amber.withValues(alpha: 0.15),
                  BBColors.amber.withValues(alpha: 0.05),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(BBRadius.xl),
              border: Border.all(color: BBColors.amber.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: BBColors.amber.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.queue,
                    size: 20,
                    color: BBColors.amber,
                  ),
                ),
                const SizedBox(width: BBSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active booking',
                        style: BBTypography.textTheme.labelSmall?.copyWith(
                          color: BBColors.amber,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        booking.shopName,
                        style: BBTypography.textTheme.titleMedium?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: BBColors.amber,
                    borderRadius: BorderRadius.circular(BBRadius.full),
                  ),
                  child: const Text(
                    'Track',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
}

// ─── Discovery Sections ───────────────────────────────────────────────────────

class _NearbySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearbyAsync = ref.watch(nearbyShopsProvider);
    final shops = nearbyAsync.valueOrNull ?? [];
    if (!nearbyAsync.isLoading && shops.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BBSpacing.pageHorizontal),
            child: _SectionHeader(title: 'Nearby'),
          ),
          const SizedBox(height: BBSpacing.md),
          if (nearbyAsync.isLoading)
            const _HorizontalShopsSkeleton()
          else
            SizedBox(
              height: 230,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: BBSpacing.pageHorizontal),
                scrollDirection: Axis.horizontal,
                itemCount: shops.length,
                separatorBuilder: (_, _) => const SizedBox(width: BBSpacing.md),
                itemBuilder: (ctx, i) => _ShopCard(shop: shops[i]),
              ),
            ),
          const SizedBox(height: BBSpacing.xl),
        ],
      ),
    );
  }
}

class _TopRatedSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topAsync = ref.watch(topRatedShopsProvider);
    final shops = topAsync.valueOrNull ?? [];
    if (!topAsync.isLoading && shops.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BBSpacing.pageHorizontal),
            child: _SectionHeader(
              title: 'Top Rated',
              onSeeAll: () => context.go('/shops'),
            ),
          ),
          const SizedBox(height: BBSpacing.md),
          if (topAsync.isLoading)
            const _HorizontalShopsSkeleton()
          else
            SizedBox(
              height: 230,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: BBSpacing.pageHorizontal),
                scrollDirection: Axis.horizontal,
                itemCount: shops.length,
                separatorBuilder: (_, _) => const SizedBox(width: BBSpacing.md),
                itemBuilder: (ctx, i) => _ShopCard(shop: shops[i]),
              ),
            ),
          const SizedBox(height: BBSpacing.xl),
        ],
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
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: BBColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BBRadius.full),
              ),
              child: Text(
                'See all',
                style: BBTypography.textTheme.labelSmall?.copyWith(
                  color: BBColors.amber,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Shop Card (horizontal scroll) ───────────────────────────────────────────

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final isDark = context.isDark;
    return GestureDetector(
      onTap: () => context.push('/shops/${shop.id}'),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(BBRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with gradient overlay
            Stack(
              children: [
                Container(
                  height: 120,
                  color: colors.surfaceVariant,
                  child: Center(
                    child: Icon(
                      AppIcons.scissors,
                      size: 42,
                      color: colors.textTertiary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                // Open/Closed pill on image
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: shop.isOpen
                          ? BBColors.success.withValues(alpha: 0.9)
                          : Colors.black54,
                      borderRadius: BorderRadius.circular(BBRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: shop.isOpen ? Colors.white : Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          shop.isOpen ? 'Open' : 'Closed',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (shop.distanceKm != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(BBRadius.full),
                      ),
                      child: Text(
                        shop.distanceLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
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
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(AppIcons.starFill, size: 13, color: BBColors.amber),
                      const SizedBox(width: 3),
                      Text(
                        shop.rating.toStringAsFixed(1),
                        style: BBTypography.textTheme.labelSmall?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ' · ',
                        style: BBTypography.textTheme.labelSmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                      Icon(AppIcons.timer, size: 12, color: colors.textTertiary),
                      const SizedBox(width: 3),
                      Text(
                        shop.waitLabel,
                        style: BBTypography.textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
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

// ─── Horizontal skeleton (3 shimmer cards) ───────────────────────────────────

class _HorizontalShopsSkeleton extends StatelessWidget {
  const _HorizontalShopsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: BBSpacing.pageHorizontal),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: BBSpacing.md),
        itemBuilder: (_, _) =>
            BBShimmerBox(width: 200, height: 230, radius: BBRadius.xl),
      ),
    );
  }
}

// ─── Service category chips ───────────────────────────────────────────────────

class _ServiceCategoriesSection extends StatelessWidget {
  const _ServiceCategoriesSection();

  static const _cats = [
    (icon: AppIcons.scissors, label: 'Haircut', color: Color(0xFFFF6B6B)),
    (icon: AppIcons.autoFix, label: 'Fade', color: Color(0xFF20BF6B)),
    (icon: AppIcons.face, label: 'Beard', color: BBColors.amber),
    (icon: AppIcons.spa, label: 'Facial', color: Color(0xFFFF8E53)),
    (icon: AppIcons.waterDrop, label: 'Hair Wash', color: BBColors.info),
    (icon: AppIcons.selfImprovement, label: 'Massage', color: Color(0xFF8B78E6)),
    (icon: AppIcons.childCare, label: 'Kids', color: BBColors.success),
    (icon: AppIcons.palette, label: 'Color', color: Color(0xFFE056FD)),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BBSpacing.pageHorizontal, 0, BBSpacing.pageHorizontal, BBSpacing.md),
          child: _SectionHeader(title: 'Services'),
        ),
        SizedBox(
          height: 92,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: BBSpacing.pageHorizontal),
            scrollDirection: Axis.horizontal,
            itemCount: _cats.length,
            separatorBuilder: (_, _) => const SizedBox(width: BBSpacing.md),
            itemBuilder: (ctx, i) {
              final cat = _cats[i];
              return GestureDetector(
                onTap: () => ctx.push('/shops'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: isDark ? 0.18 : 0.12),
                        borderRadius: BorderRadius.circular(BBRadius.xl),
                      ),
                      child: Center(
                        child: Icon(cat.icon, size: 24, color: cat.color),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.label,
                      style: BBTypography.textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: BBSpacing.xl),
      ],
    );
  }
}

// ─── Quick Rebook card ────────────────────────────────────────────────────────

class _QuickRebookCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);
    final last = bookingsAsync.valueOrNull
        ?.where((b) => b.status == 'COMPLETED' && b.shopId.isNotEmpty)
        .firstOrNull;
    if (last == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final colors = context.bbColors;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BBSpacing.pageHorizontal, 0, BBSpacing.pageHorizontal, BBSpacing.base),
        child: GestureDetector(
          onTap: () => context.push('/shops/${last.shopId}'),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: BBSpacing.base, vertical: BBSpacing.md),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(BBRadius.xl),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BBRadius.md),
                  ),
                  child:
                      Icon(AppIcons.replay, size: 18, color: colors.accent),
                ),
                const SizedBox(width: BBSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Rebook',
                        style: BBTypography.textTheme.labelSmall?.copyWith(
                          color: colors.textTertiary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        last.shopName.isNotEmpty ? last.shopName : 'Last shop',
                        style: BBTypography.textTheme.titleSmall?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (last.serviceNames.isNotEmpty)
                        Text(
                          last.serviceNames,
                          style: BBTypography.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: BBSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(BBRadius.full),
                  ),
                  child: Text(
                    'Rebook',
                    style: BBTypography.textTheme.labelSmall?.copyWith(
                      color: colors.accentForeground,
                      fontWeight: FontWeight.w700,
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
}

// ─── Trending Barbers ─────────────────────────────────────────────────────────

class _TrendingBarbersSection extends StatelessWidget {
  const _TrendingBarbersSection();

  static const _barbers = [
    ('Alex Silva', 'The Fade King', 4.9, 312),
    ('Sam Khan', 'Beard Specialist', 4.8, 289),
    ('Mike Patel', 'Classic Cuts', 4.7, 201),
    ('Raj Verma', 'Creative Styles', 4.9, 178),
    ('Arjun D.', 'Kids Expert', 4.6, 134),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BBSpacing.pageHorizontal, 0, BBSpacing.pageHorizontal, BBSpacing.md),
          child: _SectionHeader(
            title: 'Trending Barbers',
            onSeeAll: () => context.go('/shops'),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: BBSpacing.pageHorizontal),
            scrollDirection: Axis.horizontal,
            itemCount: _barbers.length,
            separatorBuilder: (_, _) => const SizedBox(width: BBSpacing.md),
            itemBuilder: (ctx, i) {
              final b = _barbers[i];
              return GestureDetector(
                onTap: () => ctx.go('/shops'),
                child: Container(
                  width: 90,
                  padding: const EdgeInsets.all(BBSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(BBRadius.xl),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: BBColors.amber.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            b.$1[0],
                            style: BBTypography.textTheme.titleLarge?.copyWith(
                              color: BBColors.amber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        b.$1.split(' ').first,
                        style: BBTypography.textTheme.labelMedium?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(AppIcons.starFill, size: 10, color: BBColors.amber),
                          const SizedBox(width: 2),
                          Text(
                            b.$3.toString(),
                            style: BBTypography.textTheme.labelSmall?.copyWith(
                              color: colors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: BBSpacing.xl),
      ],
    );
  }
}

// ─── Recently Visited ─────────────────────────────────────────────────────────

class _RecentlyVisitedSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);
    final colors = context.bbColors;

    final completed = bookingsAsync.valueOrNull
            ?.where((b) => b.status == 'COMPLETED' && b.shopName.isNotEmpty)
            .toList() ??
        [];

    final seen = <String>{};
    final unique = completed
        .where((b) => seen.add(b.shopId))
        .take(8)
        .toList();

    if (unique.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                BBSpacing.pageHorizontal, 0, BBSpacing.pageHorizontal, BBSpacing.md),
            child: Text(
              'Recently Visited',
              style: BBTypography.textTheme.titleLarge?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: BBSpacing.pageHorizontal),
              scrollDirection: Axis.horizontal,
              itemCount: unique.length,
              separatorBuilder: (_, _) => const SizedBox(width: BBSpacing.sm),
              itemBuilder: (ctx, i) {
                final b = unique[i];
                return GestureDetector(
                  onTap: () => ctx.push('/shops/${b.shopId}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(BBRadius.full),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.shops,
                            size: 14, color: colors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          b.shopName,
                          style: BBTypography.textTheme.labelMedium?.copyWith(
                            color: colors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: BBSpacing.xl),
        ],
      ),
    );
  }
}

// ─── Shop List Tile (vertical list) ──────────────────────────────────────────

class _ShopListTile extends StatelessWidget {
  const _ShopListTile({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final isDark = context.isDark;
    return GestureDetector(
      onTap: () => context.push('/shops/${shop.id}'),
      child: Container(
        padding: const EdgeInsets.all(BBSpacing.base),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(BBRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(BBRadius.lg),
              ),
              child: Center(
                child: Icon(
                  AppIcons.scissors,
                  size: 24,
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
                      fontWeight: FontWeight.w700,
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(AppIcons.starFill, size: 13, color: BBColors.amber),
                      const SizedBox(width: 3),
                      Text(
                        shop.rating.toStringAsFixed(1),
                        style: BBTypography.textTheme.labelSmall?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: BBSpacing.sm),
                      Icon(AppIcons.timer, size: 12, color: colors.textTertiary),
                      const SizedBox(width: 3),
                      Text(
                        shop.waitLabel,
                        style: BBTypography.textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      if (shop.distanceKm != null) ...[
                        const SizedBox(width: BBSpacing.sm),
                        Icon(Icons.near_me_outlined, size: 12, color: colors.textTertiary),
                        const SizedBox(width: 3),
                        Text(
                          shop.distanceLabel,
                          style: BBTypography.textTheme.labelSmall?.copyWith(
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: shop.isOpen
                    ? BBColors.success.withValues(alpha: 0.1)
                    : colors.surfaceVariant,
                borderRadius: BorderRadius.circular(BBRadius.full),
              ),
              child: Text(
                shop.isOpen ? 'Open' : 'Closed',
                style: BBTypography.textTheme.labelSmall?.copyWith(
                  color: shop.isOpen ? BBColors.success : colors.textTertiary,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
