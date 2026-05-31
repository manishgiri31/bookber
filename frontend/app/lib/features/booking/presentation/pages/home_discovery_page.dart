import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_theme.dart';
import '../booking_flow_controller.dart';
import '../home_discovery_controller.dart';
import '../widgets/apple_maps_barber_sheet.dart';
import '../widgets/floating_map_action.dart';
import '../widgets/map_barber_marker.dart';
import '../widgets/map_filter_chip.dart';

class HomeDiscoveryPage extends HookConsumerWidget {
  const HomeDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discovery = ref.watch(homeDiscoveryControllerProvider);
    final discoveryController = ref.read(
      homeDiscoveryControllerProvider.notifier,
    );
    final bookingFlow = ref.watch(bookingFlowControllerProvider);
    final bookingFlowController = ref.read(
      bookingFlowControllerProvider.notifier,
    );
    final mapController = useMemoized(MapController.new);
    final suggestions = discoveryController.suggestions();

    useEffect(() {
      if (discovery.selectedBarberId == null) return null;
      final selected = discoveryController.selectedSpot;
      if (selected != null &&
          bookingFlow.selectedBarber?.id != selected.barber.id) {
        bookingFlowController.selectBarber(selected.barber);
      }
      return null;
    }, [discovery.selectedBarberId]);

    final spots = discoveryController.filteredSpots();
    final selectedSpot =
        discoveryController.selectedSpot ??
        (spots.isNotEmpty ? spots.first : null);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: const LatLng(12.9716, 77.5946),
                initialZoom: 14.2,
                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bookber.app',
                ),
                MarkerLayer(
                  markers: spots
                      .map(
                        (spot) => Marker(
                          width: 112,
                          height: 112,
                          point: spot.location,
                          child: GestureDetector(
                            onTap: () => discoveryController.selectBarber(
                              spot.barber.id,
                            ),
                            child: MapBarberMarker(
                              name: spot.barber.name,
                              waitMinutes: spot.waitMinutes,
                              isAvailable: spot.availableNow,
                              isPremium: spot.isPremium,
                              isSelected:
                                  selectedSpot?.barber.id == spot.barber.id,
                              isTrending: spot.isTrending,
                              hasInstantBooking: spot.hasInstantBooking,
                              operationalState: spot.operationalState,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xAA0B1220),
                      Colors.transparent,
                      Colors.transparent,
                      Color(0xAA0B1220),
                    ],
                    stops: [0.0, 0.18, 0.78, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FloatingSearchPanel(
                    query: discovery.searchQuery,
                    scope: discovery.searchScope,
                    suggestions: suggestions,
                    activeFilters: discovery.activeFilters,
                    onChanged: discoveryController.setSearchQuery,
                    onVoiceTap: () {},
                    onScopeSelected: discoveryController.setSearchScope,
                    onSuggestionTap: discoveryController.applySuggestion,
                    onFilterTap: discoveryController.toggleFilter,
                    quickFilters: discoveryController.quickFilters,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        MapFilterChip(
                          label: 'Available now',
                          selected: discovery.availableNowOnly,
                          icon: Icons.bolt,
                          onTap: discoveryController.toggleAvailableNowOnly,
                        ),
                        const SizedBox(width: 8),
                        MapFilterChip(
                          label: 'Top rated',
                          selected: discovery.topRatedOnly,
                          icon: Icons.star,
                          onTap: discoveryController.toggleTopRatedOnly,
                        ),
                        const SizedBox(width: 8),
                        MapFilterChip(
                          label: 'Instant booking',
                          selected: discovery.activeFilters.contains(
                            'Instant booking',
                          ),
                          icon: Icons.flash_on,
                          onTap: () => discoveryController.toggleFilter(
                            'Instant booking',
                          ),
                        ),
                        const SizedBox(width: 8),
                        MapFilterChip(
                          label: 'Premium',
                          selected: discovery.activeFilters.contains('Premium'),
                          icon: Icons.workspace_premium,
                          onTap: () =>
                              discoveryController.toggleFilter('Premium'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 180,
            child: Column(
              children: [
                FloatingMapAction(
                  icon: Icons.my_location,
                  label: 'Current location',
                  onTap: () {
                    mapController.move(const LatLng(12.9716, 77.5946), 15.0);
                  },
                ),
                const SizedBox(height: 10),
                FloatingMapAction(
                  icon: Icons.layers,
                  label: 'Filters',
                  onTap: () {},
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: selectedSpot == null
                        ? const SizedBox.shrink()
                        : _MapQuickStatusStrip(spot: selectedSpot),
                  ),
                ),
              ],
            ),
          ),
          AppleMapsBarberSheet(
            selectedBarber: selectedSpot?.barber,
            availableServices: bookingFlow.availableServices,
            bookingFlow: bookingFlow,
            onBookNow: () => context.go(RoutePaths.services),
          ),
        ],
      ),
    );
  }
}

class _FloatingSearchPanel extends HookWidget {
  const _FloatingSearchPanel({
    required this.query,
    required this.scope,
    required this.suggestions,
    required this.activeFilters,
    required this.onChanged,
    required this.onVoiceTap,
    required this.onScopeSelected,
    required this.onSuggestionTap,
    required this.onFilterTap,
    required this.quickFilters,
  });

  final String query;
  final SearchScope scope;
  final List<SearchSuggestion> suggestions;
  final List<String> activeFilters;
  final ValueChanged<String> onChanged;
  final VoidCallback onVoiceTap;
  final ValueChanged<SearchScope> onScopeSelected;
  final ValueChanged<SearchSuggestion> onSuggestionTap;
  final ValueChanged<String> onFilterTap;
  final List<String> quickFilters;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: query);
    final theme = Theme.of(context);

    useEffect(() {
      if (controller.text != query) {
        controller.text = query;
        controller.selection = TextSelection.collapsed(offset: query.length);
      }
      return null;
    }, [query]);

    return Material(
      elevation: 18,
      shadowColor: Colors.black.withValues(alpha: 0.20),
      borderRadius: BorderRadius.circular(24),
      color: AppTheme.searchSurface,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search barbers, services, or city',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF334155),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.mic_none,
                            color: Color(0xFF334155),
                          ),
                          onPressed: onVoiceTap,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.liveIndicator,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.liveIndicator.withValues(alpha: 0.28),
                          blurRadius: 18,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.flash_on,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: SearchScope.values.map((item) {
                    final active = item == scope;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          _scopeLabel(item),
                          style: TextStyle(
                            color: active
                                ? Colors.white
                                : const Color(0xFF334155),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        selected: active,
                        selectedColor: AppTheme.primaryAccent,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (_) => onScopeSelected(item),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              if (suggestions.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: suggestions.map((suggestion) {
                      return Column(
                        children: [
                          ListTile(
                            onTap: () => onSuggestionTap(suggestion),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppTheme.operationalAccent.withValues(
                                  alpha: 0.08,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _suggestionIcon(suggestion.scope),
                                color: AppTheme.operationalAccent,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              suggestion.label,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              suggestion.subtitle,
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          if (suggestion != suggestions.last)
                            const Divider(height: 1, indent: 86, endIndent: 16),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              if (activeFilters.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: activeFilters
                      .map(
                        (filter) => MapFilterChip(
                          label: filter,
                          selected: true,
                          icon: Icons.check_circle,
                          onTap: () => onFilterTap(filter),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: quickFilters
                    .map(
                      (filter) => MapFilterChip(
                        label: filter,
                        selected: activeFilters.contains(filter),
                        onTap: () => onFilterTap(filter),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _scopeLabel(SearchScope item) {
    switch (item) {
      case SearchScope.all:
        return 'All';
      case SearchScope.barber:
        return 'Barber';
      case SearchScope.service:
        return 'Service';
      case SearchScope.city:
        return 'City';
      case SearchScope.style:
        return 'Style';
    }
  }

  static IconData _suggestionIcon(SearchScope scope) {
    switch (scope) {
      case SearchScope.barber:
        return Icons.person_outline;
      case SearchScope.service:
        return Icons.cut;
      case SearchScope.city:
        return Icons.location_city;
      case SearchScope.style:
        return Icons.style;
      case SearchScope.all:
        return Icons.search;
    }
  }
}

class _MapQuickStatusStrip extends StatelessWidget {
  const _MapQuickStatusStrip({required this.spot});

  final NearbyBarberSpot spot;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(20),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: spot.availableNow
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    spot.barber.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${spot.waitMinutes} min wait · ${spot.queueDepth} in queue · ${spot.barber.distanceKm} km away',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
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
