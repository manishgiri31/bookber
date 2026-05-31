import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/bookber_models.dart';
import 'booking_flow_controller.dart';

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

enum BarberOperationalState {
  availableNow,
  busy,
  premium,
  trending,
  instantBooking,
}

enum SearchScope { all, barber, service, city, style }

class SearchSuggestion {
  const SearchSuggestion({
    required this.label,
    required this.subtitle,
    required this.scope,
  });

  final String label;
  final String subtitle;
  final SearchScope scope;
}

class NearbyBarberSpot {
  NearbyBarberSpot({
    required this.barber,
    required this.location,
    required this.waitMinutes,
    required this.queueDepth,
    required this.isPremium,
    required this.hasInstantBooking,
    required this.availableNow,
    required this.isTrending,
    required this.operationalState,
    required this.city,
    required this.styleTags,
  });

  final Barber barber;
  final LatLng location;
  final int waitMinutes;
  final int queueDepth;
  final bool isPremium;
  final bool hasInstantBooking;
  final bool availableNow;
  final bool isTrending;
  final BarberOperationalState operationalState;
  final String city;
  final List<String> styleTags;

  bool get isBusy => !availableNow || waitMinutes > 18;
}

class DiscoveryState {
  const DiscoveryState({
    required this.searchQuery,
    required this.searchScope,
    required this.activeFilters,
    required this.availableNowOnly,
    required this.topRatedOnly,
    required this.selectedBarberId,
    required this.spots,
  });

  final String searchQuery;
  final SearchScope searchScope;
  final List<String> activeFilters;
  final bool availableNowOnly;
  final bool topRatedOnly;
  final String? selectedBarberId;
  final List<NearbyBarberSpot> spots;

  DiscoveryState copyWith({
    String? searchQuery,
    SearchScope? searchScope,
    List<String>? activeFilters,
    bool? availableNowOnly,
    bool? topRatedOnly,
    String? selectedBarberId,
    List<NearbyBarberSpot>? spots,
  }) {
    return DiscoveryState(
      searchQuery: searchQuery ?? this.searchQuery,
      searchScope: searchScope ?? this.searchScope,
      activeFilters: activeFilters ?? this.activeFilters,
      availableNowOnly: availableNowOnly ?? this.availableNowOnly,
      topRatedOnly: topRatedOnly ?? this.topRatedOnly,
      selectedBarberId: selectedBarberId ?? this.selectedBarberId,
      spots: spots ?? this.spots,
    );
  }

  factory DiscoveryState.initial() {
    return DiscoveryState(
      searchQuery: '',
      searchScope: SearchScope.all,
      activeFilters: const [],
      availableNowOnly: false,
      topRatedOnly: false,
      selectedBarberId: 'b1',
      spots: [
        NearbyBarberSpot(
          barber: Barber(
            id: 'b1',
            name: 'Arjun Fade',
            rating: 4.9,
            distanceKm: 0.6,
            bio: 'Precision fades, beard shaping, and fast turnaround.',
            isAvailable: true,
          ),
          location: const LatLng(12.9718, 77.5948),
          waitMinutes: 8,
          queueDepth: 3,
          isPremium: true,
          hasInstantBooking: true,
          availableNow: true,
          isTrending: true,
          operationalState: BarberOperationalState.availableNow,
          city: 'Indiranagar',
          styleTags: const ['Fade', 'Beard', 'Quick Cut'],
        ),
        NearbyBarberSpot(
          barber: Barber(
            id: 'b2',
            name: 'Nikhil Studio',
            rating: 4.8,
            distanceKm: 1.2,
            bio: 'Combo packages and premium grooming.',
            isAvailable: true,
          ),
          location: const LatLng(12.9726, 77.5990),
          waitMinutes: 15,
          queueDepth: 6,
          isPremium: true,
          hasInstantBooking: true,
          availableNow: true,
          isTrending: false,
          operationalState: BarberOperationalState.instantBooking,
          city: 'Koramangala',
          styleTags: const ['Premium', 'Signature Cut', 'Grooming'],
        ),
        NearbyBarberSpot(
          barber: Barber(
            id: 'b3',
            name: 'Metro Clippers',
            rating: 4.6,
            distanceKm: 1.8,
            bio: 'Efficient walk-ins and quick service.',
            isAvailable: false,
          ),
          location: const LatLng(12.9685, 77.5971),
          waitMinutes: 22,
          queueDepth: 9,
          isPremium: false,
          hasInstantBooking: false,
          availableNow: false,
          isTrending: true,
          operationalState: BarberOperationalState.busy,
          city: 'MG Road',
          styleTags: const ['Express', 'Classic Cut', 'Wash & Trim'],
        ),
      ],
    );
  }
}

class HomeDiscoveryController extends Notifier<DiscoveryState> {
  static const _searchSuggestions = [
    SearchSuggestion(
      label: 'Arjun Fade',
      subtitle: 'Premium fade specialist',
      scope: SearchScope.barber,
    ),
    SearchSuggestion(
      label: 'Beard Trim',
      subtitle: 'Fast grooming service',
      scope: SearchScope.service,
    ),
    SearchSuggestion(
      label: 'Indiranagar',
      subtitle: 'High-demand neighborhood',
      scope: SearchScope.city,
    ),
    SearchSuggestion(
      label: 'Koramangala',
      subtitle: 'Map area with premium shops',
      scope: SearchScope.city,
    ),
    SearchSuggestion(
      label: 'Fade',
      subtitle: 'Modern taper and skin fade',
      scope: SearchScope.style,
    ),
    SearchSuggestion(
      label: 'Signature Cut',
      subtitle: 'Barber-selected premium style',
      scope: SearchScope.style,
    ),
    SearchSuggestion(
      label: 'Live availability',
      subtitle: 'Only open chairs',
      scope: SearchScope.all,
    ),
  ];

  static const _defaultFilters = [
    'Indiranagar',
    'Koramangala',
    'Fade',
    'Beard Trim',
    'Premium',
  ];

  @override
  DiscoveryState build() => DiscoveryState.initial();

  void selectBarber(String barberId) {
    final spot = state.spots
        .where((spot) => spot.barber.id == barberId)
        .firstOrNull;
    if (spot == null) return;
    state = state.copyWith(selectedBarberId: barberId);
    ref.read(bookingFlowControllerProvider.notifier).selectBarber(spot.barber);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSearchScope(SearchScope scope) {
    state = state.copyWith(searchScope: scope);
  }

  void applySuggestion(SearchSuggestion suggestion) {
    final currentFilters = [...state.activeFilters];
    if (suggestion.scope == SearchScope.city ||
        suggestion.scope == SearchScope.style) {
      if (!currentFilters.contains(suggestion.label)) {
        currentFilters.add(suggestion.label);
      }
    }
    state = state.copyWith(
      searchQuery: suggestion.label,
      searchScope: suggestion.scope,
      activeFilters: currentFilters,
    );
  }

  void toggleFilter(String filter) {
    final updated = [...state.activeFilters];
    if (updated.contains(filter)) {
      updated.remove(filter);
    } else {
      updated.add(filter);
    }
    state = state.copyWith(activeFilters: updated);
  }

  void toggleAvailableNowOnly() {
    state = state.copyWith(availableNowOnly: !state.availableNowOnly);
  }

  void toggleTopRatedOnly() {
    state = state.copyWith(topRatedOnly: !state.topRatedOnly);
  }

  List<SearchSuggestion> suggestions() {
    final query = state.searchQuery.trim().toLowerCase();
    final candidates = _searchSuggestions.where((suggestion) {
      final matchesScope =
          state.searchScope == SearchScope.all ||
          suggestion.scope == state.searchScope;
      final matchesQuery =
          query.isEmpty ||
          suggestion.label.toLowerCase().contains(query) ||
          suggestion.subtitle.toLowerCase().contains(query);
      return matchesScope && matchesQuery;
    }).toList();

    if (query.isEmpty) {
      return _searchSuggestions
          .where((suggestion) => suggestion.scope == SearchScope.all)
          .toList();
    }

    return candidates.take(6).toList();
  }

  List<String> get quickFilters => _defaultFilters;

  List<NearbyBarberSpot> filteredSpots() {
    return state.spots.where((spot) {
      final query = state.searchQuery.trim().toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          spot.barber.name.toLowerCase().contains(query) ||
          spot.barber.bio.toLowerCase().contains(query) ||
          spot.city.toLowerCase().contains(query) ||
          spot.styleTags.any((style) => style.toLowerCase().contains(query));

      final matchesScope =
          state.searchScope == SearchScope.all ||
          (state.searchScope == SearchScope.barber &&
              spot.barber.name.toLowerCase().contains(query)) ||
          (state.searchScope == SearchScope.service &&
              spot.styleTags.any(
                (style) => style.toLowerCase().contains(query),
              )) ||
          (state.searchScope == SearchScope.city &&
              spot.city.toLowerCase().contains(query)) ||
          (state.searchScope == SearchScope.style &&
              spot.styleTags.any(
                (style) => style.toLowerCase().contains(query),
              ));

      final matchesFilters = state.activeFilters.every((filter) {
        final normalized = filter.toLowerCase();
        return spot.city.toLowerCase() == normalized ||
            spot.styleTags.any((style) => style.toLowerCase() == normalized) ||
            spot.barber.name.toLowerCase().contains(normalized) ||
            spot.barber.bio.toLowerCase().contains(normalized);
      });

      final matchesAvailability = !state.availableNowOnly || spot.availableNow;
      final matchesRating = !state.topRatedOnly || spot.barber.rating >= 4.8;
      return matchesQuery &&
          matchesScope &&
          matchesFilters &&
          matchesAvailability &&
          matchesRating;
    }).toList();
  }

  NearbyBarberSpot? get selectedSpot {
    return state.spots
        .where((spot) => spot.barber.id == state.selectedBarberId)
        .firstOrNull;
  }
}

final homeDiscoveryControllerProvider =
    NotifierProvider<HomeDiscoveryController, DiscoveryState>(
      HomeDiscoveryController.new,
    );
