import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tokens.dart';
import '../../../core/models/bookber_models.dart';
import '../../shops/domain/shop_models.dart';
import '../providers/shop_providers.dart';

class ShopDetailScreen extends ConsumerWidget {
  const ShopDetailScreen({super.key, required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopDetailProvider(shopId));
    final servicesAsync = ref.watch(shopServicesProvider(shopId));
    final barbersAsync = ref.watch(shopBarbersProvider(shopId));
    final queueAsync = ref.watch(liveQueueProvider(shopId));

    return shopAsync.when(
      data: (shop) {
        if (shop == null) {
          return Scaffold(
            backgroundColor: BBColors.bgCanvas,
            appBar: AppBar(backgroundColor: BBColors.bgCanvas),
            body: const Center(child: Text('Shop not found', style: BBTypography.bodyM)),
          );
        }
        return Scaffold(
          backgroundColor: BBColors.bgCanvas,
          body: _ShopDetailBody(
            shopId: shopId,
            shop: shop,
            servicesAsync: servicesAsync,
            barbersAsync: barbersAsync,
            queueAsync: queueAsync,
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: BBColors.bgCanvas,
        appBar: AppBar(backgroundColor: BBColors.bgCanvas),
        body: const Center(child: CircularProgressIndicator(color: BBColors.brandPrimary)),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: BBColors.bgCanvas,
        appBar: AppBar(backgroundColor: BBColors.bgCanvas),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: BBColors.textDisabled),
              const SizedBox(height: BBSpacing.px12),
              Text('Could not load shop', style: BBTypography.bodyM),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopDetailBody extends StatelessWidget {
  const _ShopDetailBody({
    required this.shopId,
    required this.shop,
    required this.servicesAsync,
    required this.barbersAsync,
    required this.queueAsync,
  });

  final String shopId;
  final ShopDetail shop;
  final AsyncValue<List<ServiceItem>> servicesAsync;
  final AsyncValue<List<Barber>> barbersAsync;
  final AsyncValue<Map<String, dynamic>> queueAsync;

  @override
  Widget build(BuildContext context) {
    final waitMins = queueAsync.whenData((q) => q['waitTime'] as int? ?? 0).valueOrNull ?? 0;
    final peopleAhead = queueAsync.whenData((q) => q['peopleAhead'] as int? ?? 0).valueOrNull ?? 0;

    return CustomScrollView(
      slivers: [
        // ── Hero header ─────────────────────────────────────
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: BBColors.bgCanvas,
          leading: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BBColors.bgOverlay,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: BBColors.textPrimary, size: BBIconSize.md),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BBColors.bgOverlay,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.share_outlined, size: BBIconSize.md),
                color: BBColors.textPrimary,
                onPressed: () {},
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                shop.imageUrl != null
                    ? Image.network(shop.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _HeroPlaceholder(name: shop.name))
                    : _HeroPlaceholder(name: shop.name),
                // Gradient overlay
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, BBColors.bgCanvas],
                    ),
                  ),
                ),
                // Open/closed badge
                Positioned(
                  bottom: 16,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BBSpacing.px12, vertical: BBSpacing.px6,
                    ),
                    decoration: BoxDecoration(
                      color: shop.isOpen ? BBColors.success : BBColors.error,
                      borderRadius: BBRadius.pill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: BBSpacing.px6),
                        Text(
                          shop.isOpen ? 'Open' : 'Closed',
                          style: BBTypography.labelS.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Content ─────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.all(BBSpacing.px20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Shop name
              Text(shop.name, style: BBTypography.displayS),
              const SizedBox(height: BBSpacing.px8),

              // Rating + distance row
              Row(
                children: [
                  if (shop.rating > 0) ...[
                    const Icon(Icons.star_rounded, size: BBIconSize.sm, color: BBColors.warning),
                    const SizedBox(width: BBSpacing.px4),
                    Text(shop.rating.toStringAsFixed(1), style: BBTypography.labelM),
                    if (shop.reviewCount != null) ...[
                      const SizedBox(width: BBSpacing.px4),
                      Text('(${shop.reviewCount})', style: BBTypography.bodyS),
                    ],
                    const SizedBox(width: BBSpacing.px12),
                  ],
                  if (shop.distanceLabel.isNotEmpty) ...[
                    const Icon(Icons.place_outlined, size: BBIconSize.sm, color: BBColors.textSecondary),
                    const SizedBox(width: BBSpacing.px4),
                    Text(shop.distanceLabel, style: BBTypography.bodyS),
                  ],
                ],
              ),
              const SizedBox(height: BBSpacing.px12),

              // Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: BBIconSize.sm, color: BBColors.textSecondary),
                  const SizedBox(width: BBSpacing.px8),
                  Expanded(
                    child: Text(
                      '${shop.address}, ${shop.city}',
                      style: BBTypography.bodyM.copyWith(color: BBColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: BBSpacing.px8),
                  GestureDetector(
                    onTap: () {/* TODO: open maps */},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BBSpacing.px12, vertical: BBSpacing.px6,
                      ),
                      decoration: BoxDecoration(
                        color: BBColors.bgSurface,
                        borderRadius: BBRadius.sm,
                        border: Border.all(color: BBColors.borderSubtle),
                      ),
                      child: Text(
                        'Directions',
                        style: BBTypography.labelS.copyWith(color: BBColors.brandPrimary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BBSpacing.px24),

              // ── Live Queue Banner ──────────────────────────
              _QueueBanner(
                shopId: shopId,
                waitMins: waitMins,
                peopleAhead: peopleAhead,
                availableChairs: shop.availableChairs,
              ),
              const SizedBox(height: BBSpacing.px32),

              // ── Services ────────────────────────────────────
              _SectionHeader(title: 'Services'),
              const SizedBox(height: BBSpacing.px16),
              _ServicesGrid(servicesAsync: servicesAsync),
              const SizedBox(height: BBSpacing.px32),

              // ── Chairs ──────────────────────────────────────
              if (shop.chairs.isNotEmpty) ...[
                _SectionHeader(title: 'Chair Status'),
                const SizedBox(height: BBSpacing.px16),
                _ChairsGrid(chairs: shop.chairs),
                const SizedBox(height: BBSpacing.px32),
              ],

              // ── Barbers ─────────────────────────────────────
              _SectionHeader(title: 'Barbers'),
              const SizedBox(height: BBSpacing.px16),
              _BarbersList(barbersAsync: barbersAsync),
              const SizedBox(height: BBSpacing.px32),

              // Reviews placeholder
              _SectionHeader(title: 'Reviews'),
              const SizedBox(height: BBSpacing.px16),
              Center(
                child: Text(
                  'Reviews coming soon',
                  style: BBTypography.bodyM.copyWith(color: BBColors.textDisabled),
                ),
              ),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BBColors.bgElevated,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'B',
          style: BBTypography.displayL.copyWith(
            color: BBColors.brandPrimary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: BBTypography.headingL);
  }
}

class _QueueBanner extends StatelessWidget {
  const _QueueBanner({
    required this.shopId,
    required this.waitMins,
    required this.peopleAhead,
    required this.availableChairs,
  });

  final String shopId;
  final int waitMins;
  final int peopleAhead;
  final int availableChairs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BBSpacing.px20),
      decoration: BoxDecoration(
        color: BBColors.bgSurface,
        borderRadius: BBRadius.card,
        border: Border(
          left: BorderSide(color: BBColors.brandPrimary, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Wait', style: BBTypography.bodyS),
                  const SizedBox(height: BBSpacing.px4),
                  Text(
                    waitMins > 0 ? '~$waitMins mins' : 'No wait',
                    style: BBTypography.displayM.copyWith(color: BBColors.brandPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: BBSpacing.px14, vertical: BBSpacing.px8,
                ),
                decoration: BoxDecoration(
                  color: BBColors.success.withValues(alpha: 0.12),
                  borderRadius: BBRadius.pill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline, size: BBIconSize.sm, color: BBColors.success),
                    const SizedBox(width: BBSpacing.px4),
                    Text(
                      '$peopleAhead ahead',
                      style: BBTypography.labelS.copyWith(color: BBColors.success),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.px16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/queue/$shopId'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BBColors.brandPrimary,
                    side: const BorderSide(color: BBColors.brandPrimary),
                    shape: RoundedRectangleBorder(borderRadius: BBRadius.pill),
                    padding: const EdgeInsets.symmetric(vertical: BBSpacing.px14),
                  ),
                  child: const Text('Join Queue'),
                ),
              ),
              const SizedBox(width: BBSpacing.px12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go('/book/$shopId'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BBColors.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BBRadius.pill),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: BBSpacing.px14),
                  ),
                  child: const Text('Book Slot'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({required this.servicesAsync});
  final AsyncValue<List<ServiceItem>> servicesAsync;

  @override
  Widget build(BuildContext context) {
    return servicesAsync.when(
      data: (services) {
        if (services.isEmpty) {
          return Text(
            'No services listed',
            style: BBTypography.bodyM.copyWith(color: BBColors.textDisabled),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: BBSpacing.px12,
            mainAxisSpacing: BBSpacing.px12,
            childAspectRatio: 1.4,
          ),
          itemCount: services.length,
          itemBuilder: (context, i) {
            final svc = services[i];
            return Container(
              padding: const EdgeInsets.all(BBSpacing.px14),
              decoration: BoxDecoration(
                color: BBColors.bgSurface,
                borderRadius: BBRadius.card,
                border: Border.all(color: BBColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(svc.name, style: BBTypography.labelL, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${svc.price.toStringAsFixed(0)}',
                        style: BBTypography.headingS.copyWith(color: BBColors.brandPrimary),
                      ),
                      Text(
                        '${svc.durationMinutes} mins',
                        style: BBTypography.bodyS.copyWith(color: BBColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: BBColors.brandPrimary)),
      error: (_, __) => Text(
        'Error loading services',
        style: BBTypography.bodyM.copyWith(color: BBColors.error),
      ),
    );
  }
}

class _ChairsGrid extends StatelessWidget {
  const _ChairsGrid({required this.chairs});
  final List<ShopChair> chairs;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: BBSpacing.px10,
        mainAxisSpacing: BBSpacing.px10,
      ),
      itemCount: chairs.length,
      itemBuilder: (_, i) {
        final chair = chairs[i];
        final available = chair.isAvailable;
        return Container(
          decoration: BoxDecoration(
            color: available ? BBColors.success : BBColors.bgSurface,
            borderRadius: BBRadius.sm,
            border: Border.all(
              color: available ? BBColors.success : BBColors.borderSubtle,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_seat,
                color: available ? Colors.white : BBColors.textDisabled,
                size: BBIconSize.md,
              ),
              Text(
                '#${chair.number}',
                style: BBTypography.caption.copyWith(
                  color: available ? Colors.white : BBColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BarbersList extends StatelessWidget {
  const _BarbersList({required this.barbersAsync});
  final AsyncValue<List<Barber>> barbersAsync;

  @override
  Widget build(BuildContext context) {
    return barbersAsync.when(
      data: (barbers) {
        if (barbers.isEmpty) {
          return Text(
            'No barbers listed',
            style: BBTypography.bodyM.copyWith(color: BBColors.textDisabled),
          );
        }
        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: barbers.length,
            separatorBuilder: (_, __) => const SizedBox(width: BBSpacing.px12),
            itemBuilder: (_, i) {
              final barber = barbers[i];
              return Container(
                width: 100,
                padding: const EdgeInsets.all(BBSpacing.px12),
                decoration: BoxDecoration(
                  color: BBColors.bgSurface,
                  borderRadius: BBRadius.card,
                  border: Border.all(color: BBColors.borderSubtle),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: BBColors.bgElevated,
                      child: const Icon(Icons.person, color: BBColors.textSecondary, size: BBIconSize.lg),
                    ),
                    const SizedBox(height: BBSpacing.px8),
                    Text(
                      barber.name,
                      style: BBTypography.labelS,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: BBSpacing.px4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded, size: 10, color: BBColors.warning),
                        const SizedBox(width: 2),
                        Text(barber.rating.toStringAsFixed(1), style: BBTypography.caption),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: BBColors.brandPrimary)),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
