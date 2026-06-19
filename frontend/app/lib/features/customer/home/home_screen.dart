import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tokens.dart';
import '../../../core/components/bb_card.dart';
import '../../../core/components/bb_skeleton.dart';
import '../../../core/components/bb_status.dart';
import '../../../core/components/bb_input.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../features/auth/domain/auth_state.dart';
import '../../shops/domain/shop_models.dart';
import '../providers/shop_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _promoController = PageController();
  int _promoPage = 0;

  @override
  void initState() {
    super.initState();
    _startPromoAutoScroll();
    // Keep status bar light on dark bg
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _startPromoAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final next = (_promoPage + 1) % _promoItems.length;
      _promoController.animateToPage(
        next,
        duration: BBMotion.slow,
        curve: BBMotion.smooth,
      );
      _startPromoAutoScroll();
    });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static const _promoItems = [
    _PromoItem(
      headline: 'BookBer Members\nget 20% off',
      sub: 'Limited time offer',
      gradient: LinearGradient(
        colors: [BBColors.brandPrimary, BBColorPrimitives.indigo100],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      ctaLabel: 'Book now',
      textColor: BBColorPrimitives.neutral50,
    ),
    _PromoItem(
      headline: 'New shops\nnear you',
      sub: '14 new barbershops this week',
      gradient: LinearGradient(
        colors: [BBColorPrimitives.neutral150, BBColorPrimitives.neutral200],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      ctaLabel: 'Explore',
      textColor: BBColorPrimitives.neutral900,
    ),
    _PromoItem(
      headline: 'Skip the wait\nwith BookBer',
      sub: 'Real-time queue tracking',
      gradient: LinearGradient(
        colors: [BBColorPrimitives.coral400, BBColorPrimitives.coral500],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      ctaLabel: 'Learn more',
      textColor: BBColorPrimitives.neutral50,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final userName = switch (authState) {
      AuthAuthenticated(:final user) => user.name.split(' ').first,
      _ => '',
    };

    return Scaffold(
      backgroundColor: BBColors.bgCanvas,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _HomeAppBar(greeting: _greeting, userName: userName),
          ),

          // ── Search ───────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              BBSpacing.px20, BBSpacing.px4, BBSpacing.px20, BBSpacing.px20,
            ),
            sliver: SliverToBoxAdapter(
              child: BBSearchField(
                hint: 'Search barbers, shops, services...',
                onTap: () => context.push('/search'),
              ),
            ),
          ),

          // ── Promo carousel ───────────────────────────────
          SliverToBoxAdapter(
            child: _PromoCarousel(
              items: _promoItems,
              controller: _promoController,
              currentPage: _promoPage,
              onPageChanged: (i) => setState(() => _promoPage = i),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: BBSpacing.px32)),

          // ── Quick filters ────────────────────────────────
          SliverToBoxAdapter(
            child: _ServiceFilterRow(
              onFilter: (service) {
                context.push('/search?service=$service');
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: BBSpacing.px32)),

          // ── Nearby shops ─────────────────────────────────
          SliverToBoxAdapter(
            child: BBSectionHeader(
              title: 'Nearby Shops',
              action: 'See all',
              onActionTap: () => context.push('/explore'),
              padding: const EdgeInsets.fromLTRB(
                BBSpacing.px20, 0, BBSpacing.px20, BBSpacing.px16,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 272,
              child: ref.watch(nearbyShopsProvider('Ludhiana')).when(
                data: (shops) => _ShopHorizontalList(shops: shops),
                loading: () => const _ShopHorizontalSkeleton(),
                error: (e, _) => _ShopsError(onRetry: () => ref.invalidate(nearbyShopsProvider)),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: BBSpacing.px32)),

          // ── Open now ─────────────────────────────────────
          SliverToBoxAdapter(
            child: BBSectionHeader(
              title: 'Open Now',
              action: 'See all',
              onActionTap: () => context.push('/explore?filter=open'),
              padding: const EdgeInsets.fromLTRB(
                BBSpacing.px20, 0, BBSpacing.px20, BBSpacing.px16,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: ref.watch(nearbyShopsProvider('Ludhiana')).when(
              data: (shops) {
                final open = shops.where((s) => s.isOpen).toList();
                return open.isEmpty
                    ? const _NoOpenShops()
                    : _OpenShopsList(shops: open);
              },
              loading: () => const _OpenShopsListSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // ── Bottom padding ────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// APP BAR
// ─────────────────────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar({required this.greeting, required this.userName});

  final String greeting;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BBSpacing.px20, BBSpacing.px16, BBSpacing.px20, BBSpacing.px8,
        ),
        child: Row(
          children: [
            // Greeting
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName.isNotEmpty ? '$greeting, $userName' : greeting,
                    style: BBTypography.displayS,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: BBSpacing.px4),
                  // Location pill
                  GestureDetector(
                    onTap: () {/* TODO: location picker */},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: BBIconSize.sm,
                          color: BBColors.brandPrimary,
                        ),
                        const SizedBox(width: BBSpacing.px4),
                        Text('Ludhiana, Punjab', style: BBTypography.bodyM),
                        const SizedBox(width: BBSpacing.px4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: BBIconSize.sm,
                          color: BBColors.textDisabled,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Notification
            _NotificationButton(onTap: () => context.push('/notifications')),
            const SizedBox(width: BBSpacing.px10),
            // Avatar
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: BBColors.brandPrimaryDim,
                  shape: BoxShape.circle,
                  border: Border.all(color: BBColors.brandPrimary, width: 1.5),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: BBIconSize.md,
                  color: BBColors.brandPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: BBColors.bgSurface,
              borderRadius: BBRadius.md,
              border: Border.all(color: BBColors.borderSubtle, width: 1),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: BBIconSize.md,
              color: BBColors.textPrimary,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: BBColors.brandPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PROMO CAROUSEL
// ─────────────────────────────────────────────────────────────

class _PromoItem {
  const _PromoItem({
    required this.headline,
    required this.sub,
    required this.gradient,
    required this.ctaLabel,
    required this.textColor,
  });

  final String headline;
  final String sub;
  final Gradient gradient;
  final String ctaLabel;
  final Color textColor;
}

class _PromoCarousel extends StatelessWidget {
  const _PromoCarousel({
    required this.items,
    required this.controller,
    required this.currentPage,
    required this.onPageChanged,
  });

  final List<_PromoItem> items;
  final PageController controller;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
                child: BBGradientCard(
                  gradient: item.gradient,
                  borderRadius: BBRadius.xxl,
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.headline,
                            style: BBTypography.displayM.copyWith(
                              color: item.textColor,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: BBSpacing.px6),
                          Text(
                            item.sub,
                            style: BBTypography.bodyM.copyWith(
                              color: item.textColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BBSpacing.px14,
                            vertical: BBSpacing.px8,
                          ),
                          decoration: BoxDecoration(
                            color: item.textColor.withValues(alpha: 0.15),
                            borderRadius: BBRadius.pill,
                          ),
                          child: Text(
                            item.ctaLabel,
                            style: BBTypography.buttonS.copyWith(color: item.textColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: BBSpacing.px12),
        // Page dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (i) {
            final active = i == currentPage;
            return AnimatedContainer(
              duration: BBMotion.normal,
              curve: BBMotion.smooth,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? BBColors.brandPrimary : BBColors.bgElevated,
                borderRadius: BBRadius.pill,
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SERVICE FILTER ROW
// ─────────────────────────────────────────────────────────────

class _ServiceFilterRow extends StatefulWidget {
  const _ServiceFilterRow({required this.onFilter});

  final ValueChanged<String> onFilter;

  @override
  State<_ServiceFilterRow> createState() => _ServiceFilterRowState();
}

class _ServiceFilterRowState extends State<_ServiceFilterRow> {
  String? _selected;

  static const _filters = [
    ('Haircut', Icons.content_cut),
    ('Beard', Icons.face),
    ('Shave', Icons.spa_outlined),
    ('Fade', Icons.gradient),
    ('Kids', Icons.child_care),
    ('Color', Icons.palette_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: BBSpacing.px8),
        itemBuilder: (context, i) {
          final (label, icon) = _filters[i];
          final isSelected = _selected == label;
          return GestureDetector(
            onTap: () {
              setState(() => _selected = isSelected ? null : label);
              if (!isSelected) widget.onFilter(label);
            },
            child: AnimatedContainer(
              duration: BBMotion.fast,
              padding: const EdgeInsets.symmetric(
                horizontal: BBSpacing.px14,
                vertical: BBSpacing.px8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? BBColors.brandPrimary : BBColors.bgSurface,
                borderRadius: BBRadius.pill,
                border: Border.all(
                  color: isSelected ? BBColors.brandPrimary : BBColors.borderSubtle,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: BBIconSize.sm,
                    color: isSelected ? BBColorPrimitives.neutral50 : BBColors.textSecondary,
                  ),
                  const SizedBox(width: BBSpacing.px6),
                  Text(
                    label,
                    style: BBTypography.labelM.copyWith(
                      color: isSelected ? BBColorPrimitives.neutral50 : BBColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NEARBY SHOPS HORIZONTAL LIST
// ─────────────────────────────────────────────────────────────

class _ShopHorizontalList extends StatelessWidget {
  const _ShopHorizontalList({required this.shops});

  final List<ShopSummary> shops;

  @override
  Widget build(BuildContext context) {
    if (shops.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(BBSpacing.px20),
          child: Text('No shops nearby', style: BBTypography.bodyM),
        ),
      );
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
      itemCount: shops.length,
      separatorBuilder: (_, __) => const SizedBox(width: BBSpacing.px12),
      itemBuilder: (context, i) {
        // Stagger entrance
        return _AnimatedShopCard(shop: shops[i], index: i);
      },
    );
  }
}

class _AnimatedShopCard extends StatefulWidget {
  const _AnimatedShopCard({required this.shop, required this.index});

  final ShopSummary shop;
  final int index;

  @override
  State<_AnimatedShopCard> createState() => _AnimatedShopCardState();
}

class _AnimatedShopCardState extends State<_AnimatedShopCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: BBMotion.slow);
    _slide = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: BBMotion.enter),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: BBMotion.enter),
    );

    Future.delayed(BBMotion.stagger(widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(_slide.value, 0),
        child: Opacity(opacity: _opacity.value, child: child),
      ),
      child: _ShopCard(
        shop: widget.shop,
        onTap: () => context.push('/shop/${widget.shop.id}'),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.shop, required this.onTap});

  final ShopSummary shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 196,
        decoration: BoxDecoration(
          color: BBColors.bgSurface,
          borderRadius: BBRadius.card,
          border: Border.all(color: BBColors.borderSubtle, width: 1),
          boxShadow: BBElevation.low,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 120,
              width: double.infinity,
              child: shop.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: shop.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: BBColors.bgElevated),
                      errorWidget: (_, __, ___) => _ShopImagePlaceholder(name: shop.name),
                    )
                  : _ShopImagePlaceholder(name: shop.name),
            ),

            Padding(
              padding: const EdgeInsets.all(BBSpacing.px12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    style: BBTypography.headingS,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: BBSpacing.px6),

                  // Rating + distance row
                  Row(
                    children: [
                      BBRatingBadge(rating: shop.rating, reviewCount: shop.reviewCount),
                      const Spacer(),
                      Text(shop.distanceLabel, style: BBTypography.bodyS),
                    ],
                  ),
                  const SizedBox(height: BBSpacing.px10),

                  // Status row
                  Row(
                    children: [
                      if (shop.isOpen)
                        BBStatusPill(
                          type: BBStatusType.open,
                          label: 'Open',
                          showPulse: true,
                        )
                      else
                        const BBStatusPill(type: BBStatusType.closed, label: 'Closed'),
                      const Spacer(),
                      if (shop.waitMinutes != null)
                        BBWaitBadge(minutes: shop.waitMinutes!),
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

class _ShopImagePlaceholder extends StatelessWidget {
  const _ShopImagePlaceholder({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BBColors.bgElevated,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'B',
          style: BBTypography.displayL.copyWith(
            color: BBColors.brandPrimary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SKELETON STATES
// ─────────────────────────────────────────────────────────────

class _ShopHorizontalSkeleton extends StatelessWidget {
  const _ShopHorizontalSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: BBSpacing.px12),
      itemBuilder: (_, __) => const ShopCardSkeleton(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// OPEN NOW LIST
// ─────────────────────────────────────────────────────────────

class _OpenShopsList extends StatelessWidget {
  const _OpenShopsList({required this.shops});

  final List<ShopSummary> shops;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: shops.take(4).map((shop) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            BBSpacing.px20, 0, BBSpacing.px20, BBSpacing.px12,
          ),
          child: BBCard(
            onTap: () => context.push('/shop/${shop.id}'),
            padding: const EdgeInsets.all(BBSpacing.px14),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BBRadius.md,
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: shop.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: shop.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: BBColors.bgElevated),
                            errorWidget: (_, __, ___) =>
                                Container(color: BBColors.bgElevated),
                          )
                        : Container(
                            color: BBColors.bgElevated,
                            child: Icon(
                              Icons.store,
                              size: BBIconSize.lg,
                              color: BBColors.brandPrimary.withValues(alpha: 0.5),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: BBSpacing.px14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style: BBTypography.headingS,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: BBSpacing.px4),
                      Row(
                        children: [
                          BBRatingBadge(rating: shop.rating),
                          const SizedBox(width: BBSpacing.px8),
                          Text('·', style: BBTypography.bodyS),
                          const SizedBox(width: BBSpacing.px8),
                          Text(shop.distanceLabel, style: BBTypography.bodyS),
                        ],
                      ),
                    ],
                  ),
                ),

                // Wait time
                if (shop.waitMinutes != null) ...[
                  const SizedBox(width: BBSpacing.px8),
                  BBWaitBadge(minutes: shop.waitMinutes!),
                ],

                const SizedBox(width: BBSpacing.px8),
                const Icon(
                  Icons.chevron_right,
                  size: BBIconSize.md,
                  color: BBColors.textDisabled,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _OpenShopsListSkeleton extends StatelessWidget {
  const _OpenShopsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return BBSkeletonList(
      itemCount: 3,
      itemBuilder: (_) => const ListItemSkeleton(),
    );
  }
}

class _NoOpenShops extends StatelessWidget {
  const _NoOpenShops();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(BBSpacing.px20),
      child: BBEmptyState(
        icon: Icons.store_outlined,
        title: 'No shops open right now',
        subtitle: 'Check back during business hours',
      ),
    );
  }
}

class _ShopsError extends StatelessWidget {
  const _ShopsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_outlined, size: 32, color: BBColors.textDisabled),
          const SizedBox(height: BBSpacing.px12),
          Text('Could not load shops', style: BBTypography.bodyM),
          const SizedBox(height: BBSpacing.px12),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Retry',
              style: BBTypography.labelL.copyWith(color: BBColors.brandPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
