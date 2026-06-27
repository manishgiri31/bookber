import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_empty_state.dart';
import '../../../core/widgets/bb_error_widget.dart';
import '../../../core/widgets/bb_loading.dart';
import '../../shared/domain/shop_models.dart';
import 'shops_provider.dart';

class ShopsScreen extends ConsumerStatefulWidget {
  const ShopsScreen({super.key});

  @override
  ConsumerState<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends ConsumerState<ShopsScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(shopsProvider.notifier).search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final state = ref.watch(shopsProvider);
    final shops = state.displayed;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Barber Shops'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              BBSpacing.pageHorizontal,
              0,
              BBSpacing.pageHorizontal,
              BBSpacing.md,
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              style: BBTypography.textTheme.bodyLarge?.copyWith(
                color: colors.text,
              ),
              decoration: InputDecoration(
                hintText: 'Search shops...',
                hintStyle: BBTypography.textTheme.bodyLarge?.copyWith(
                  color: colors.textTertiary,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: colors.textTertiary,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            size: 18, color: colors.textTertiary),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(shopsProvider.notifier).search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BBRadius.md),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BBRadius.md),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BBRadius.md),
                  borderSide: BorderSide(color: colors.accent, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: BBSpacing.base,
                  vertical: BBSpacing.md,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _FilterBar(
            sortBy: state.sortBy,
            openOnly: state.openOnly,
            onSortChanged: (s) => ref.read(shopsProvider.notifier).setSortBy(s),
            onOpenOnlyChanged: (v) =>
                ref.read(shopsProvider.notifier).setOpenOnly(v),
          ),
          Expanded(
            child: state.isLoading
                ? const _ShopsSkeletonLoader()
                : state.error != null
                    ? BBErrorWidget(
                        error: state.error!,
                        onRetry: () =>
                            ref.read(shopsProvider.notifier).refresh(),
                      )
                    : shops.isEmpty
                        ? BBEmptyState(
                            title: state.openOnly && state.shops.isNotEmpty
                                ? 'No open shops'
                                : 'No shops found',
                            subtitle: state.query.isNotEmpty
                                ? 'Try a different search term.'
                                : state.openOnly && state.shops.isNotEmpty
                                    ? 'All nearby shops are currently closed.'
                                    : 'No barber shops available yet.',
                            icon: Icons.store_outlined,
                          )
                        : RefreshIndicator(
                            color: colors.accent,
                            onRefresh: () =>
                                ref.read(shopsProvider.notifier).refresh(),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(
                                  BBSpacing.pageHorizontal),
                              itemCount: shops.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: BBSpacing.sm),
                              itemBuilder: (ctx, i) =>
                                  _ShopCard(shop: shops[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _ShopsSkeletonLoader extends StatelessWidget {
  const _ShopsSkeletonLoader();

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return ListView.separated(
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      itemCount: 4,
      physics: const NeverScrollableScrollPhysics(),
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
            BBShimmerBox(width: 72, height: 72, radius: BBRadius.md),
            const SizedBox(width: BBSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: BBShimmerBox(
                            width: double.infinity, height: 16),
                      ),
                      const SizedBox(width: 8),
                      BBShimmerBox(
                          width: 48, height: 20, radius: BBRadius.full),
                    ],
                  ),
                  const SizedBox(height: 8),
                  BBShimmerBox(width: 140, height: 12),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      BBShimmerBox(width: 36, height: 12),
                      const SizedBox(width: 8),
                      BBShimmerBox(width: 52, height: 12),
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.sortBy,
    required this.openOnly,
    required this.onSortChanged,
    required this.onOpenOnlyChanged,
  });

  final ShopSortBy sortBy;
  final bool openOnly;
  final void Function(ShopSortBy) onSortChanged;
  final void Function(bool) onOpenOnlyChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.pageHorizontal,
          vertical: BBSpacing.sm,
        ),
        child: Row(
          children: [
            _SortChip(
              label: 'Nearest',
              icon: Icons.near_me_outlined,
              selected: sortBy == ShopSortBy.nearest,
              onTap: () => onSortChanged(ShopSortBy.nearest),
            ),
            const SizedBox(width: BBSpacing.xs),
            _SortChip(
              label: 'Top Rated',
              icon: Icons.star_outline_rounded,
              selected: sortBy == ShopSortBy.topRated,
              onTap: () => onSortChanged(ShopSortBy.topRated),
            ),
            const SizedBox(width: BBSpacing.xs),
            _SortChip(
              label: 'Fastest',
              icon: Icons.timer_outlined,
              selected: sortBy == ShopSortBy.fastest,
              onTap: () => onSortChanged(ShopSortBy.fastest),
            ),
            const SizedBox(width: BBSpacing.sm),
            Container(
              width: 1,
              height: 20,
              color: colors.border,
            ),
            const SizedBox(width: BBSpacing.sm),
            _SortChip(
              label: 'Open Now',
              icon: Icons.circle_rounded,
              selected: openOnly,
              selectedIconColor: BBColors.success,
              onTap: () => onOpenOnlyChanged(!openOnly),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.selectedIconColor,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedIconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.accent : colors.surface,
          borderRadius: BorderRadius.circular(BBRadius.full),
          border: Border.all(
            color: selected ? colors.accent : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected
                  ? (selectedIconColor ?? colors.accentForeground)
                  : colors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: BBTypography.textTheme.labelSmall?.copyWith(
                color: selected ? colors.accentForeground : colors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
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
        padding: const EdgeInsets.all(BBSpacing.base),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(BBRadius.lg),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(BBRadius.md),
              ),
              child: Center(
                child: Icon(
                  Icons.content_cut_rounded,
                  size: 28,
                  color: colors.textTertiary,
                ),
              ),
            ),
            const SizedBox(width: BBSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shop.name,
                          style: BBTypography.textTheme.titleMedium?.copyWith(
                            color: colors.text,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: shop.isOpen
                              ? BBColors.success.withValues(alpha: 0.12)
                              : colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(BBRadius.full),
                        ),
                        child: Text(
                          shop.isOpen ? 'Open' : 'Closed',
                          style: BBTypography.textTheme.labelSmall?.copyWith(
                            color: shop.isOpen
                                ? BBColors.success
                                : colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shop.address,
                    style: BBTypography.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: BBSpacing.sm,
                    children: [
                      _InfoChip(
                        icon: Icons.star_rounded,
                        label: shop.rating.toStringAsFixed(1),
                      ),
                      _InfoChip(
                        icon: Icons.timer_outlined,
                        label: shop.waitLabel,
                      ),
                      if (shop.distanceKm != null)
                        _InfoChip(
                          icon: Icons.near_me_outlined,
                          label: shop.distanceLabel,
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: BBTypography.textTheme.labelSmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
