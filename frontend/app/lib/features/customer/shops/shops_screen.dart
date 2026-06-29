import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/design/app_icons.dart';
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

  void _showAdvancedFilters(
      BuildContext context, WidgetRef ref, ShopsSearchState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(BBRadius.xxl)),
      ),
      builder: (_) => _AdvancedFiltersSheet(
        state: state,
        onApply: ({
          required double minRating,
          required double? maxDistanceKm,
          required bool verifiedOnly,
          required bool openOnly,
        }) {
          ref.read(shopsProvider.notifier).setMinRating(minRating);
          ref.read(shopsProvider.notifier).setMaxDistance(maxDistanceKm);
          ref.read(shopsProvider.notifier).setVerifiedOnly(verifiedOnly);
          ref.read(shopsProvider.notifier).setOpenOnly(openOnly);
        },
        onClear: () => ref.read(shopsProvider.notifier).clearFilters(),
      ),
    );
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
                  AppIcons.search,
                  size: 20,
                  color: colors.textTertiary,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(AppIcons.clear,
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
            hasActiveFilters: state.hasActiveFilters,
            onSortChanged: (s) => ref.read(shopsProvider.notifier).setSortBy(s),
            onOpenOnlyChanged: (v) =>
                ref.read(shopsProvider.notifier).setOpenOnly(v),
            onAdvancedFilters: () => _showAdvancedFilters(context, ref, state),
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
                            icon: AppIcons.store,
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
    required this.hasActiveFilters,
    required this.onSortChanged,
    required this.onOpenOnlyChanged,
    required this.onAdvancedFilters,
  });

  final ShopSortBy sortBy;
  final bool openOnly;
  final bool hasActiveFilters;
  final void Function(ShopSortBy) onSortChanged;
  final void Function(bool) onOpenOnlyChanged;
  final VoidCallback onAdvancedFilters;

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
            // Advanced filters button
            GestureDetector(
              onTap: onAdvancedFilters,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasActiveFilters ? BBColors.amber : colors.surface,
                  borderRadius: BorderRadius.circular(BBRadius.full),
                  border: Border.all(
                    color:
                        hasActiveFilters ? BBColors.amber : colors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppIcons.filter,
                      size: 13,
                      color: hasActiveFilters
                          ? colors.background
                          : colors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      hasActiveFilters ? 'Filtered' : 'Filters',
                      style: BBTypography.textTheme.labelSmall?.copyWith(
                        color: hasActiveFilters
                            ? colors.background
                            : colors.textSecondary,
                        fontWeight: hasActiveFilters
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: BBSpacing.sm),
            Container(width: 1, height: 20, color: colors.border),
            const SizedBox(width: BBSpacing.sm),
            _SortChip(
              label: 'Nearest',
              icon: AppIcons.nearMe,
              selected: sortBy == ShopSortBy.nearest,
              onTap: () => onSortChanged(ShopSortBy.nearest),
            ),
            const SizedBox(width: BBSpacing.xs),
            _SortChip(
              label: 'Top Rated',
              icon: AppIcons.star,
              selected: sortBy == ShopSortBy.topRated,
              onTap: () => onSortChanged(ShopSortBy.topRated),
            ),
            const SizedBox(width: BBSpacing.xs),
            _SortChip(
              label: 'Fastest',
              icon: AppIcons.timer,
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
              icon: AppIcons.circleFill,
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
                  AppIcons.scissors,
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
                        icon: AppIcons.starFill,
                        label: shop.rating.toStringAsFixed(1),
                      ),
                      _InfoChip(
                        icon: AppIcons.timer,
                        label: shop.waitLabel,
                      ),
                      if (shop.distanceKm != null)
                        _InfoChip(
                          icon: AppIcons.nearMe,
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

// ── Advanced Filters Sheet ────────────────────────────────────────────────────

class _AdvancedFiltersSheet extends StatefulWidget {
  const _AdvancedFiltersSheet({
    required this.state,
    required this.onApply,
    required this.onClear,
  });
  final ShopsSearchState state;
  final void Function({
    required double minRating,
    required double? maxDistanceKm,
    required bool verifiedOnly,
    required bool openOnly,
  }) onApply;
  final VoidCallback onClear;

  @override
  State<_AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();
}

class _AdvancedFiltersSheetState extends State<_AdvancedFiltersSheet> {
  late double _minRating;
  late double? _maxDistanceKm;
  late bool _verifiedOnly;
  late bool _openOnly;

  static const _ratingOptions = [0.0, 4.0, 4.5, 4.8];
  static const _distanceOptions = <double?>[null, 1.0, 2.0, 5.0, 10.0];

  @override
  void initState() {
    super.initState();
    _minRating = widget.state.minRating;
    _maxDistanceKm = widget.state.maxDistanceKm;
    _verifiedOnly = widget.state.verifiedOnly;
    _openOnly = widget.state.openOnly;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BBSpacing.pageHorizontal, BBSpacing.lg, BBSpacing.pageHorizontal, BBSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filters',
                style: BBTypography.textTheme.headlineSmall?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  widget.onClear();
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Clear all',
                  style: BBTypography.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.xl),

          // ── Min rating ──────────────────────────────────────────
          Text(
            'MINIMUM RATING',
            style: BBTypography.textTheme.labelSmall?.copyWith(
              color: colors.textTertiary, letterSpacing: 1,
            ),
          ),
          const SizedBox(height: BBSpacing.sm),
          Row(
            children: _ratingOptions.map((r) {
              final selected = _minRating == r;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: BBSpacing.xs),
                  child: GestureDetector(
                    onTap: () => setState(() => _minRating = r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? BBColors.amber : colors.surface,
                        borderRadius: BorderRadius.circular(BBRadius.md),
                        border: Border.all(
                          color: selected ? BBColors.amber : colors.border,
                        ),
                      ),
                      child: Column(
                        children: [
                          if (r == 0.0)
                            Text('Any',
                                style: BBTypography.textTheme.labelSmall?.copyWith(
                                  color: selected ? colors.background : colors.text,
                                  fontWeight: FontWeight.w700,
                                ))
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(AppIcons.starFill,
                                    size: 12,
                                    color: selected ? colors.background : BBColors.amber),
                                const SizedBox(width: 2),
                                Text('$r+',
                                    style: BBTypography.textTheme.labelSmall?.copyWith(
                                      color: selected ? colors.background : colors.text,
                                      fontWeight: FontWeight.w700,
                                    )),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: BBSpacing.xl),

          // ── Distance ─────────────────────────────────────────────
          Text(
            'MAX DISTANCE',
            style: BBTypography.textTheme.labelSmall?.copyWith(
              color: colors.textTertiary, letterSpacing: 1,
            ),
          ),
          const SizedBox(height: BBSpacing.sm),
          Row(
            children: _distanceOptions.map((d) {
              final selected = _maxDistanceKm == d;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: BBSpacing.xs),
                  child: GestureDetector(
                    onTap: () => setState(() => _maxDistanceKm = d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? BBColors.amber : colors.surface,
                        borderRadius: BorderRadius.circular(BBRadius.md),
                        border: Border.all(
                          color: selected ? BBColors.amber : colors.border,
                        ),
                      ),
                      child: Text(
                        d == null ? 'Any' : '${d.toInt()}km',
                        textAlign: TextAlign.center,
                        style: BBTypography.textTheme.labelSmall?.copyWith(
                          color: selected ? colors.background : colors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: BBSpacing.xl),

          // ── Toggles ──────────────────────────────────────────────
          _ToggleRow(
            label: 'Open Now',
            subtitle: 'Only show currently open shops',
            value: _openOnly,
            onChanged: (v) => setState(() => _openOnly = v),
          ),
          const SizedBox(height: BBSpacing.sm),
          _ToggleRow(
            label: 'Verified Shops',
            subtitle: 'Only show verified & trusted shops',
            value: _verifiedOnly,
            onChanged: (v) => setState(() => _verifiedOnly = v),
          ),

          const SizedBox(height: BBSpacing.xl),

          // ── Apply ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BBColors.amber,
                foregroundColor: colors.background,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BBRadius.md),
                ),
              ),
              onPressed: () {
                widget.onApply(
                  minRating: _minRating,
                  maxDistanceKm: _maxDistanceKm,
                  verifiedOnly: _verifiedOnly,
                  openOnly: _openOnly,
                );
                Navigator.of(context).pop();
              },
              child: Text(
                'Apply Filters',
                style: BBTypography.textTheme.labelLarge?.copyWith(
                  color: colors.background,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.base, vertical: BBSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: BBTypography.textTheme.labelMedium?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                    )),
                Text(subtitle,
                    style: BBTypography.textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                    )),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: BBColors.amber,
          ),
        ],
      ),
    );
  }
}
