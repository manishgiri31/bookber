import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../providers/shop_providers.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  bool _isMapView = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Nearby', 'Open Now', 'Top Rated', 'Quick Wait'];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: BBSpacing.px20, vertical: BBSpacing.px16),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BBRadius.md,
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: BBSpacing.px16),
                    const Icon(Icons.search, size: 20, color: BBColors.brandPrimary),
                    const SizedBox(width: BBSpacing.px12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (value) {
                          ref.read(searchQueryProvider.notifier).state = value;
                        },
                        style: BBTypography.bodyM.copyWith(color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search barbers, shops, services...',
                          hintStyle:
                              BBTypography.bodyM.copyWith(color: colors.textSecondary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: BBSpacing.px12),
                    GestureDetector(
                      onTap: _showFilterBottomSheet,
                      child: Icon(Icons.tune, size: 20, color: colors.textSecondary),
                    ),
                    const SizedBox(width: BBSpacing.px16),
                  ],
                ),
              ),
            ),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
              child: SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: EdgeInsets.only(
                          right: index < _filters.length - 1 ? BBSpacing.px8 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: BBSpacing.px16, vertical: BBSpacing.px8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? BBColors.brandPrimary
                                : colors.bgSurface,
                            borderRadius: BBRadius.pill,
                            border: isSelected
                                ? null
                                : Border.all(color: colors.borderSubtle),
                          ),
                          child: Text(
                            filter,
                            style: BBTypography.labelS.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: BBSpacing.px12),

            // Map/List toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isMapView = !_isMapView),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: BBSpacing.px12, vertical: BBSpacing.px8),
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BBRadius.sm,
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isMapView ? Icons.list : Icons.map_outlined,
                            size: 18,
                            color: BBColors.brandPrimary,
                          ),
                          const SizedBox(width: BBSpacing.px8),
                          Text(
                            _isMapView ? 'List' : 'Map',
                            style: BBTypography.labelS
                                .copyWith(color: colors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: BBSpacing.px12),

            // Content
            Expanded(
              child: _isMapView ? _buildMapView(colors) : _buildListView(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(BBColorTheme colors) {
    return Consumer(
      builder: (context, ref, _) {
        final query = ref.watch(searchQueryProvider);
        final shopsAsync = query.isEmpty
            ? ref.watch(nearbyShopsProvider('Ludhiana'))
            : ref.watch(searchShopsProvider(query));

        return shopsAsync.when(
          data: (shops) {
            if (shops.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.store_mall_directory_outlined,
                        size: 56, color: colors.textDisabled),
                    const SizedBox(height: BBSpacing.px12),
                    Text('No shops found',
                        style: BBTypography.headingM
                            .copyWith(color: colors.textPrimary)),
                    const SizedBox(height: BBSpacing.px4),
                    Text('Try a different search or filter',
                        style: BBTypography.bodyM
                            .copyWith(color: colors.textSecondary)),
                  ],
                ),
              );
            }
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
              child: ListView.builder(
                itemCount: shops.length,
                itemBuilder: (context, index) {
                  final shop = shops[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: BBSpacing.px12),
                    child: GestureDetector(
                      onTap: () => context.go('/shop/${shop.id}'),
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BBRadius.card,
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            // Thumbnail
                            Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colors.bgElevated,
                                borderRadius: BBRadius.md,
                              ),
                              child: shop.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BBRadius.md,
                                      child: Image.network(
                                        shop.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const SizedBox.shrink(),
                                      ),
                                    )
                                  : Icon(Icons.content_cut_rounded,
                                      size: BBIconSize.lg,
                                      color: colors.textDisabled),
                            ),
                            // Info
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      shop.name,
                                      style: BBTypography.headingS.copyWith(
                                          color: colors.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: BBSpacing.px4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded,
                                            size: 13,
                                            color: BBColors.brandSecondary),
                                        const SizedBox(width: BBSpacing.px4),
                                        Text(
                                          shop.rating.toStringAsFixed(1),
                                          style: BBTypography.labelS.copyWith(
                                              color: colors.textPrimary),
                                        ),
                                        Text(
                                          ' (${shop.reviewCount})',
                                          style: BBTypography.bodyS.copyWith(
                                              color: colors.textSecondary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: BBSpacing.px4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined,
                                            size: 12,
                                            color: colors.textSecondary),
                                        const SizedBox(width: BBSpacing.px4),
                                        Text(
                                          shop.distanceLabel,
                                          style: BBTypography.bodyS.copyWith(
                                              color: colors.textSecondary),
                                        ),
                                        const SizedBox(width: BBSpacing.px12),
                                        Icon(Icons.access_time,
                                            size: 12,
                                            color: colors.textSecondary),
                                        const SizedBox(width: BBSpacing.px4),
                                        Text(
                                          shop.waitTimeLabel,
                                          style: BBTypography.bodyS.copyWith(
                                              color: colors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Book button
                            Padding(
                              padding: const EdgeInsets.only(right: BBSpacing.px12),
                              child: SizedBox(
                                width: 72,
                                height: 34,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      context.go('/shop/${shop.id}'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: BBColors.brandPrimary,
                                    foregroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BBRadius.pill),
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text('Book',
                                      style: BBTypography.labelS.copyWith(
                                          color: Colors.white)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('Error: $error',
                style: BBTypography.bodyM.copyWith(color: colors.textSecondary)),
          ),
        );
      },
    );
  }

  Widget _buildMapView(BBColorTheme colors) {
    return Container(
      color: colors.bgSurface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: colors.textDisabled),
            const SizedBox(height: BBSpacing.px16),
            Text('Map view coming soon',
                style:
                    BBTypography.headingM.copyWith(color: colors.textPrimary)),
            const SizedBox(height: BBSpacing.px4),
            Text('Browse shops in list view for now',
                style:
                    BBTypography.bodyM.copyWith(color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _FilterBottomSheet(),
    );
  }
}

class _FilterBottomSheet extends ConsumerWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final filters = ref.watch(shopFiltersProvider);
    final notifier = ref.read(shopFiltersProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BBRadius.sheet,
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: BBSpacing.px12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BBRadius.pill,
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters',
                    style: BBTypography.headingL
                        .copyWith(color: colors.textPrimary)),
                GestureDetector(
                  onTap: () => notifier.reset(),
                  child: Text('Reset',
                      style: BBTypography.labelM
                          .copyWith(color: colors.textSecondary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: BBSpacing.px24),
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: BBSpacing.px24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Distance',
                      style: BBTypography.labelM
                          .copyWith(color: colors.textPrimary)),
                  const SizedBox(height: BBSpacing.px12),
                  Slider(
                    value: filters.maxDistance,
                    min: 0,
                    max: 50,
                    divisions: 50,
                    activeColor: BBColors.brandPrimary,
                    onChanged: (value) => notifier.updateMaxDistance(value),
                  ),
                  Text('${filters.maxDistance.toInt()} km',
                      style: BBTypography.bodyS
                          .copyWith(color: colors.textSecondary)),
                  const SizedBox(height: BBSpacing.px24),

                  Text('Minimum Rating',
                      style: BBTypography.labelM
                          .copyWith(color: colors.textPrimary)),
                  const SizedBox(height: BBSpacing.px12),
                  Row(
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => notifier.updateMinRating(index + 1),
                        child: Icon(
                          index < (filters.minRating ?? 0)
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: BBColors.brandSecondary,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: BBSpacing.px24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Open Now',
                          style: BBTypography.labelM
                              .copyWith(color: colors.textPrimary)),
                      Switch(
                        value: filters.openNow,
                        onChanged: (_) => notifier.toggleOpenNow(),
                        activeColor: BBColors.brandPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: BBSpacing.px24),

                  Text('Sort By',
                      style: BBTypography.labelM
                          .copyWith(color: colors.textPrimary)),
                  const SizedBox(height: BBSpacing.px12),
                  ...['distance', 'rating', 'waitTime'].map((option) {
                    final label = option == 'waitTime'
                        ? 'Wait Time'
                        : option[0].toUpperCase() + option.substring(1);
                    return GestureDetector(
                      onTap: () => notifier.updateSortBy(option),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: BBSpacing.px12),
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: colors.borderSubtle, width: 1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(label,
                                style: BBTypography.bodyL
                                    .copyWith(color: colors.textPrimary)),
                            if (filters.sortBy == option)
                              const Icon(Icons.check_rounded,
                                  color: BBColors.brandPrimary, size: 20),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: BBSpacing.px24),
                ],
              ),
            ),
          ),
          // Apply button
          Padding(
            padding: const EdgeInsets.all(BBSpacing.px24),
            child: SizedBox(
              width: double.infinity,
              height: BBTouchTarget.button,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
