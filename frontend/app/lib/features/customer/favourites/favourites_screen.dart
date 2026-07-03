import 'package:flutter/material.dart';
import '../../../core/design/app_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen>
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
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Favourites'),
        bottom: TabBar(
          controller: _tab,
          labelColor: colors.text,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: context.bbColors.accent,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Shops'),
            Tab(text: 'Barbers'),
            Tab(text: 'Services'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _ShopsTab(),
          _BarbersTab(),
          _ServicesTab(),
        ],
      ),
    );
  }
}

// ── Demo data ──────────────────────────────────────────────────────────────────

const _demoShops = [
  ('The Classic Cut', 'Koramangala, Bangalore', 4.8, '5 min wait'),
  ('Style Studio', 'Indiranagar, Bangalore', 4.6, '12 min wait'),
];

const _demoBarbers = [
  ('Alex Silva', 'The Classic Cut', 4.9, 'Specializes in Fades'),
  ('Sam Khan', 'Style Studio', 4.7, 'Hair & Beard Expert'),
];

const _demoServices = [
  ('Premium Fade', 'The Classic Cut', '₹350', '30 min'),
  ('Classic Haircut', 'Style Studio', '₹250', '25 min'),
  ('Hot Towel Shave', 'The Classic Cut', '₹200', '20 min'),
];

// ── Shops tab ──────────────────────────────────────────────────────────────────

class _ShopsTab extends StatelessWidget {
  const _ShopsTab();

  @override
  Widget build(BuildContext context) {
    if (_demoShops.isEmpty) return const _EmptyFavourites(type: 'shops');
    return ListView.separated(
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      itemCount: _demoShops.length,
      separatorBuilder: (_, _) => const SizedBox(height: BBSpacing.sm),
      itemBuilder: (ctx, i) {
        final shop = _demoShops[i];
        return _FavShopCard(
          name: shop.$1,
          location: shop.$2,
          rating: shop.$3,
          waitLabel: shop.$4,
        );
      },
    );
  }
}

class _FavShopCard extends StatelessWidget {
  const _FavShopCard({
    required this.name,
    required this.location,
    required this.rating,
    required this.waitLabel,
  });
  final String name;
  final String location;
  final double rating;
  final String waitLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.xl),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(BBRadius.md),
            ),
            child: Icon(AppIcons.store,
                size: 24, color: colors.textTertiary),
          ),
          const SizedBox(width: BBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: BBTypography.textTheme.titleMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  location,
                  style: BBTypography.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(AppIcons.starFill,
                        size: 12, color: context.bbColors.accent),
                    const SizedBox(width: 3),
                    Text(
                      rating.toStringAsFixed(1),
                      style: BBTypography.textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(AppIcons.timer,
                        size: 12, color: colors.textTertiary),
                    const SizedBox(width: 3),
                    Text(
                      waitLabel,
                      style: BBTypography.textTheme.labelSmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(AppIcons.favoriteFill,
                    color: BBColors.error, size: 20),
                onPressed: () {},
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: context.bbColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(BBRadius.full),
                  ),
                  child: Text(
                    'Rebook',
                    style: BBTypography.textTheme.labelSmall?.copyWith(
                      color: context.bbColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Barbers tab ────────────────────────────────────────────────────────────────

class _BarbersTab extends StatelessWidget {
  const _BarbersTab();

  @override
  Widget build(BuildContext context) {
    if (_demoBarbers.isEmpty) return const _EmptyFavourites(type: 'barbers');
    return ListView.separated(
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      itemCount: _demoBarbers.length,
      separatorBuilder: (_, _) => const SizedBox(height: BBSpacing.sm),
      itemBuilder: (ctx, i) {
        final b = _demoBarbers[i];
        return _FavBarberCard(
          name: b.$1,
          shop: b.$2,
          rating: b.$3,
          speciality: b.$4,
        );
      },
    );
  }
}

class _FavBarberCard extends StatelessWidget {
  const _FavBarberCard({
    required this.name,
    required this.shop,
    required this.rating,
    required this.speciality,
  });
  final String name;
  final String shop;
  final double rating;
  final String speciality;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.xl),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: context.bbColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: BBTypography.textTheme.titleLarge?.copyWith(
                  color: context.bbColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: BBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: BBTypography.textTheme.titleMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  shop,
                  style: BBTypography.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  speciality,
                  style: BBTypography.textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Icon(AppIcons.starFill,
                      size: 14, color: context.bbColors.accent),
                  const SizedBox(width: 3),
                  Text(
                    rating.toStringAsFixed(1),
                    style: BBTypography.textTheme.labelMedium?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(AppIcons.favoriteFill,
                    color: BBColors.error, size: 20),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Services tab ───────────────────────────────────────────────────────────────

class _ServicesTab extends StatelessWidget {
  const _ServicesTab();

  @override
  Widget build(BuildContext context) {
    if (_demoServices.isEmpty) return const _EmptyFavourites(type: 'services');
    return ListView.separated(
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      itemCount: _demoServices.length,
      separatorBuilder: (_, _) => const SizedBox(height: BBSpacing.sm),
      itemBuilder: (ctx, i) {
        final s = _demoServices[i];
        return _FavServiceCard(
          name: s.$1,
          shop: s.$2,
          price: s.$3,
          duration: s.$4,
        );
      },
    );
  }
}

class _FavServiceCard extends StatelessWidget {
  const _FavServiceCard({
    required this.name,
    required this.shop,
    required this.price,
    required this.duration,
  });
  final String name;
  final String shop;
  final String price;
  final String duration;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.xl),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(BBRadius.md),
            ),
            child: Icon(AppIcons.scissors,
                size: 20, color: colors.textTertiary),
          ),
          const SizedBox(width: BBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: BBTypography.textTheme.titleMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  shop,
                  style: BBTypography.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      duration,
                      style: BBTypography.textTheme.labelSmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: BBTypography.textTheme.titleMedium?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(AppIcons.favoriteFill,
                    color: BBColors.error, size: 18),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyFavourites extends StatelessWidget {
  const _EmptyFavourites({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BBSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.favorite,
                  size: 36, color: colors.textTertiary),
            ),
            const SizedBox(height: BBSpacing.base),
            Text(
              'No favourite $type yet',
              style: BBTypography.textTheme.titleMedium?.copyWith(
                color: colors.text,
              ),
            ),
            const SizedBox(height: BBSpacing.xs),
            Text(
              'Tap the heart icon on any $type to save it here.',
              style: BBTypography.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BBSpacing.xl),
            TextButton.icon(
              onPressed: () => context.go('/shops'),
              icon: const Icon(AppIcons.explore),
              label: const Text('Explore Shops'),
            ),
          ],
        ),
      ),
    );
  }
}
