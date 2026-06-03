import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import '../providers/shop_providers.dart';
import '../widgets/customer_nav_bar.dart';
import '../widgets/shop_card.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  int _currentIndex = 1;
  bool _isMapView = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Nearby', 'Open Now', 'Top Rated', 'Quick Wait'];

  @override
  void initState() {
    super.initState();
    // Auto-focus search on load
    Future.delayed(const Duration(milliseconds: 100), () {
      _searchFocusNode.requestFocus();
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
    return Scaffold(
      backgroundColor: BookBerPalette.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: BookBerPalette.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.search,
                            size: 20,
                            color: BookBerPalette.primaryAccent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: (value) {
                                ref.read(searchQueryProvider.notifier).state = value;
                              },
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: BookBerPalette.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search barbers, shops, services...',
                                hintStyle: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: BookBerPalette.textSecondary,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => _showFilterBottomSheet(),
                            child: const Icon(
                              Icons.tune,
                              size: 20,
                              color: BookBerPalette.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                  ),

                  // Filter chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        itemBuilder: (context, index) {
                          final filter = _filters[index];
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index < _filters.length - 1 ? 12 : 0,
                            ),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedFilter = filter),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? BookBerPalette.primaryAccent
                                      : BookBerPalette.bgSurface,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  filter,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? BookBerPalette.bgPrimary
                                        : BookBerPalette.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Map/List toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                      GestureDetector(
                        onTap: () => setState(() => _isMapView = !_isMapView),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: BookBerPalette.bgSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isMapView ? Icons.list : Icons.map_outlined,
                                size: 18,
                                color: BookBerPalette.primaryAccent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isMapView ? 'List' : 'Map',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: BookBerPalette.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  ),
                  const SizedBox(height: 16),

                  // Content
                  Expanded(
                    child: _isMapView ? _buildMapView() : _buildListView(),
                  ),
                ],
              ),
            ),
            // Bottom navigation
            CustomerNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Consumer(
      builder: (context, ref, _) {
        final query = ref.watch(searchQueryProvider);
        final shopsAsync = query.isEmpty
            ? ref.watch(nearbyShopsProvider('Ludhiana'))
            : ref.watch(searchShopsProvider(query));

        return shopsAsync.when(
          data: (shops) {
            if (shops.isEmpty) {
              return const Center(
                child: Text('No shops found'),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.builder(
                itemCount: shops.length,
                itemBuilder: (context, index) {
                  final shop = shops[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () => context.go('/shop/${shop.id}'),
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: BookBerPalette.bgSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0x0FFFFFFF),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Image
                            Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: BookBerPalette.bgElevated,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: shop.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        shop.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container();
                                        },
                                      ),
                                    )
                                  : null,
                            ),
                            // Info
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      shop.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: BookBerPalette.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 14,
                                          color: BookBerPalette.primaryAccent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          shop.rating.toStringAsFixed(1),
                                          style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: BookBerPalette.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '(${shop.reviewCount})',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            color: BookBerPalette.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 12,
                                          color: BookBerPalette.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          shop.distanceLabel,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            color: BookBerPalette.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(
                                          Icons.access_time,
                                          size: 12,
                                          color: BookBerPalette.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          shop.waitTimeLabel,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            color: BookBerPalette.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Book button
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: SizedBox(
                                width: 80,
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: () => context.go('/shop/${shop.id}'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: BookBerPalette.primaryAccent,
                                    foregroundColor: BookBerPalette.bgPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    'Book',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        );
      },
    );
  }

  Widget _buildShopListTile(int index) {
    // This method is no longer used, but kept for reference
    return GestureDetector(
      onTap: () => context.go('/shop/${index + 1}'),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: BookBerPalette.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0x0FFFFFFF),
            width: 1,
          ),
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      color: BookBerPalette.bgSurface,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: BookBerPalette.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'Google Maps integration',
              style: TextStyle(
                fontSize: 16,
                color: BookBerPalette.textSecondary,
              ),
            ),
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
      builder: (context) => _FilterBottomSheet(),
    );
  }
}

class _FilterBottomSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(shopFiltersProvider);
    final notifier = ref.read(shopFiltersProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: BookBerPalette.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: BookBerPalette.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => notifier.reset(),
                  child: Text(
                    'Reset',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: BookBerPalette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Distance slider
                  Text(
                    'Distance',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BookBerPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: filters.maxDistance,
                    min: 0,
                    max: 50,
                    divisions: 50,
                    activeColor: BookBerPalette.primaryAccent,
                    onChanged: (value) {
                      notifier.updateMaxDistance(value);
                    },
                  ),
                  Text(
                    '${filters.maxDistance.toInt()} km',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: BookBerPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Min rating
                  Text(
                    'Minimum Rating',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BookBerPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => notifier.updateMinRating(index + 1),
                        child: Icon(
                          index < (filters.minRating ?? 0)
                              ? Icons.star
                              : Icons.star_border,
                          color: BookBerPalette.primaryAccent,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Open Now toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Open Now',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: BookBerPalette.textPrimary,
                        ),
                      ),
                      Switch(
                        value: filters.openNow,
                        onChanged: (_) => notifier.toggleOpenNow(),
                        activeColor: BookBerPalette.primaryAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sort By
                  Text(
                    'Sort By',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BookBerPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...['distance', 'rating', 'waitTime'].map((option) {
                    return GestureDetector(
                      onTap: () => notifier.updateSortBy(option),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: const Color(0x0FFFFFFF),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              option[0].toUpperCase() +
                                  option.substring(1).replaceAll(
                                      RegExp(r'([A-Z])'), ' ${r'$1'}'),
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: BookBerPalette.textPrimary,
                              ),
                            ),
                            if (filters.sortBy == option)
                              const Icon(
                                Icons.check,
                                color: BookBerPalette.primaryAccent,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Apply button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BookBerPalette.primaryAccent,
                  foregroundColor: BookBerPalette.bgPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
