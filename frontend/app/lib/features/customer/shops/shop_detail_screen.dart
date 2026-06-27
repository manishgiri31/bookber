import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_button.dart';
import '../../../core/widgets/bb_error_widget.dart';
import '../../../core/widgets/bb_loading.dart';
import '../../shared/domain/shop_models.dart';
import 'shops_provider.dart';

class ShopDetailScreen extends ConsumerStatefulWidget {
  const ShopDetailScreen({super.key, required this.shopId});
  final String shopId;

  @override
  ConsumerState<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends ConsumerState<ShopDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final isDark = context.isDark;
    final shopAsync = ref.watch(shopDetailProvider(widget.shopId));

    return shopAsync.when(
      loading: () => const BBLoadingScreen(),
      error: (e, _) => BBErrorWidget(error: e, fullScreen: true),
      data: (shop) => Scaffold(
        backgroundColor: colors.background,
        extendBodyBehindAppBar: true,
        body: NestedScrollView(
          headerSliverBuilder: (ctx, _) => [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: colors.background.withValues(alpha: 0.95),
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: colors.text,
                    ),
                  ),
                ),
              ),
              actions: [
                if (shop.latitude != null && shop.longitude != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: GestureDetector(
                      onTap: () => _openDirections(shop),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.directions_rounded,
                          size: 18,
                          color: BBColors.info,
                        ),
                      ),
                    ),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: colors.surfaceVariant,
                      child: Center(
                        child: Icon(
                          Icons.content_cut_rounded,
                          size: 72,
                          color: colors.textTertiary.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    // Gradient overlay at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              colors.background,
                              colors.background.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: BBSpacing.pageHorizontal),
                child: _ShopHeader(shop: shop, onDirections: () => _openDirections(shop)),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tab,
                  labelColor: BBColors.amber,
                  unselectedLabelColor: colors.textSecondary,
                  indicatorColor: BBColors.amber,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 2.5,
                  labelStyle: BBTypography.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: BBTypography.textTheme.labelLarge,
                  tabs: const [
                    Tab(text: 'Services'),
                    Tab(text: 'Barbers'),
                    Tab(text: 'Reviews'),
                  ],
                  dividerColor: colors.border,
                ),
                colors.background,
              ),
            ),
          ],
          body: TabBarView(
            controller: _tab,
            children: [
              _ServicesTab(shopId: widget.shopId),
              _BarbersTab(shopId: widget.shopId),
              _ReviewsTab(shopId: widget.shopId),
            ],
          ),
        ),
        bottomNavigationBar: _BottomActions(shop: shop),
      ),
    );
  }

  Future<void> _openDirections(Shop shop) async {
    if (shop.latitude == null || shop.longitude == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${shop.latitude},${shop.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({required this.shop, required this.onDirections});
  final Shop shop;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                shop.name,
                style: BBTypography.textTheme.headlineMedium?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: BBSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: shop.isOpen
                    ? BBColors.success.withValues(alpha: 0.12)
                    : colors.surfaceVariant,
                borderRadius: BorderRadius.circular(BBRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: shop.isOpen ? BBColors.success : colors.textTertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    shop.isOpen ? 'Open' : 'Closed',
                    style: BBTypography.textTheme.labelMedium?.copyWith(
                      color: shop.isOpen ? BBColors.success : colors.textTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: BBSpacing.sm),
        GestureDetector(
          onTap: (shop.latitude != null && shop.longitude != null) ? onDirections : null,
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: (shop.latitude != null && shop.longitude != null)
                    ? BBColors.info
                    : colors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  shop.address,
                  style: BBTypography.textTheme.bodyMedium?.copyWith(
                    color: (shop.latitude != null && shop.longitude != null)
                        ? BBColors.info
                        : colors.textSecondary,
                    decoration: (shop.latitude != null && shop.longitude != null)
                        ? TextDecoration.underline
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: BBSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _StatChip(
                icon: Icons.star_rounded,
                label: '${shop.rating.toStringAsFixed(1)} (${shop.reviewCount})',
                iconColor: BBColors.amber,
              ),
              const SizedBox(width: BBSpacing.sm),
              _StatChip(
                icon: Icons.timer_outlined,
                label: shop.waitLabel,
              ),
              if (shop.availableChairs > 0) ...[
                const SizedBox(width: BBSpacing.sm),
                _StatChip(
                  icon: Icons.chair_outlined,
                  label: '${shop.availableChairs} free',
                ),
              ],
              if (shop.distanceKm != null) ...[
                const SizedBox(width: BBSpacing.sm),
                _StatChip(
                  icon: Icons.near_me_outlined,
                  label: shop.distanceLabel,
                  iconColor: BBColors.info,
                ),
              ],
            ],
          ),
        ),
        if (shop.phone != null && shop.phone!.isNotEmpty) ...[
          const SizedBox(height: BBSpacing.sm),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse('tel:${shop.phone}');
              if (await canLaunchUrl(uri)) launchUrl(uri);
            },
            child: Row(
              children: [
                Icon(Icons.phone_outlined, size: 14, color: BBColors.success),
                const SizedBox(width: 4),
                Text(
                  shop.phone!,
                  style: BBTypography.textTheme.bodyMedium?.copyWith(
                    color: BBColors.success,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: BBSpacing.base),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, this.iconColor});
  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(BBRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? colors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: BBTypography.textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesTab extends ConsumerWidget {
  const _ServicesTab({required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final async = ref.watch(shopServicesProvider(shopId));
    return async.when(
      loading: () => const BBSkeletonListView(itemCount: 5),
      error: (e, _) => BBErrorWidget(error: e),
      data: (services) => services.isEmpty
          ? const Center(child: Text('No services listed'))
          : ListView.separated(
              padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
              itemCount: services.length,
              separatorBuilder: (_, _) => Divider(color: colors.border, height: 1),
              itemBuilder: (ctx, i) => _ServiceRow(service: services[i]),
            ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service});
  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BBSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BBColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(BBRadius.md),
            ),
            child: const Center(
              child: Icon(Icons.content_cut_rounded, size: 18, color: BBColors.amber),
            ),
          ),
          const SizedBox(width: BBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: BBTypography.textTheme.titleMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  service.durationLabel,
                  style: BBTypography.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: BBColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(BBRadius.full),
            ),
            child: Text(
              service.priceLabel,
              style: BBTypography.textTheme.labelLarge?.copyWith(
                color: BBColors.amber,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarbersTab extends ConsumerWidget {
  const _BarbersTab({required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shopBarbersProvider(shopId));
    return async.when(
      loading: () => const BBSkeletonListView(itemCount: 3),
      error: (e, _) => BBErrorWidget(error: e),
      data: (barbers) => barbers.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(BBSpacing.pageHorizontal),
                child: Text('No barbers listed for this shop yet.'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
              itemCount: barbers.length,
              separatorBuilder: (_, _) => const SizedBox(height: BBSpacing.sm),
              itemBuilder: (ctx, i) => _BarberCard(barber: barbers[i]),
            ),
    );
  }
}

class _BarberCard extends StatelessWidget {
  const _BarberCard({required this.barber});
  final Barber barber;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: BBColors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    barber.name.isNotEmpty ? barber.name[0].toUpperCase() : 'B',
                    style: BBTypography.textTheme.titleLarge?.copyWith(
                      color: BBColors.amber,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: barber.isAvailable ? BBColors.success : colors.textTertiary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: BBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  barber.name,
                  style: BBTypography.textTheme.titleMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (barber.bio != null && barber.bio!.isNotEmpty)
                  Text(
                    barber.bio!,
                    style: BBTypography.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (barber.rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 12, color: BBColors.amber),
                      const SizedBox(width: 3),
                      Text(
                        barber.rating!.toStringAsFixed(1),
                        style: BBTypography.textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: barber.isAvailable
                  ? BBColors.success.withValues(alpha: 0.1)
                  : colors.surfaceVariant,
              borderRadius: BorderRadius.circular(BBRadius.full),
            ),
            child: Text(
              barber.isAvailable ? 'Available' : 'Busy',
              style: BBTypography.textTheme.labelSmall?.copyWith(
                color: barber.isAvailable ? BBColors.success : colors.textTertiary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsTab extends ConsumerWidget {
  const _ReviewsTab({required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shopReviewsProvider(shopId));
    return async.when(
      loading: () => const BBSkeletonListView(itemCount: 3),
      error: (e, _) => BBErrorWidget(error: e),
      data: (reviews) => reviews.isEmpty
          ? const Center(child: Text('No reviews yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
              itemCount: reviews.length,
              separatorBuilder: (_, _) => const SizedBox(height: BBSpacing.sm),
              itemBuilder: (ctx, i) => _ReviewCard(review: reviews[i]),
            ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final ShopReview review;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: BBColors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.customerName.isNotEmpty
                        ? review.customerName[0].toUpperCase()
                        : 'A',
                    style: BBTypography.textTheme.labelLarge?.copyWith(
                      color: BBColors.amber,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: BBSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: BBTypography.textTheme.labelLarge?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 12,
                            color: BBColors.amber,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          DateFormat('MMM d, yyyy').format(review.createdAt),
                          style: BBTypography.textTheme.labelSmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: BBSpacing.sm),
            Text(
              review.comment,
              style: BBTypography.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        BBSpacing.pageHorizontal, BBSpacing.base, BBSpacing.pageHorizontal, 0),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: BBButton(
                label: 'Join Queue',
                onPressed: shop.isOpen
                    ? () => context.push(
                          '/shops/${shop.id}/book',
                          extra: {
                            'joinQueue': true,
                            'shopName': shop.name,
                          },
                        )
                    : null,
                disabled: !shop.isOpen,
                icon: Icons.queue_rounded,
              ),
            ),
            const SizedBox(width: BBSpacing.sm),
            Expanded(
              child: BBButton(
                label: 'Book',
                onPressed: shop.isOpen
                    ? () => context.push(
                          '/shops/${shop.id}/book',
                          extra: {'shopName': shop.name},
                        )
                    : null,
                disabled: !shop.isOpen,
                variant: BBButtonVariant.secondary,
                icon: Icons.calendar_today_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar, this.color);
  final TabBar tabBar;
  final Color color;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: color, child: tabBar);

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}
