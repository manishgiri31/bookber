import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.cityName,
  });
  final double latitude;
  final double longitude;
  final String? cityName;
}

class LocationNotifier extends AsyncNotifier<UserLocation?> {
  @override
  // On startup: only use already-granted permission, never show dialog.
  Future<UserLocation?> build() => _getIfGranted();

  Future<UserLocation?> _getIfGranted() async {
    try {
      final svcEnabled = await Geolocator.isLocationServiceEnabled();
      if (!svcEnabled) return null;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await _resolvePosition();
    } catch (_) {
      return null;
    }
  }

  Future<UserLocation?> _fetch() async {
    try {
      final svcEnabled = await Geolocator.isLocationServiceEnabled();
      if (!svcEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await _resolvePosition();
    } catch (_) {
      return null;
    }
  }

  Future<UserLocation?> _resolvePosition() async {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
    );

    String? cityName;
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        cityName = p.locality?.isNotEmpty == true
            ? p.locality
            : p.subAdministrativeArea?.isNotEmpty == true
                ? p.subAdministrativeArea
                : p.administrativeArea;
      }
    } catch (_) {}

    return UserLocation(
      latitude: pos.latitude,
      longitude: pos.longitude,
      cityName: cityName,
    );
  }

  // Called when user explicitly taps "Enable location" — shows permission dialog.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final locationProvider =
    AsyncNotifierProvider<LocationNotifier, UserLocation?>(
  LocationNotifier.new,
);

final locationCityProvider = Provider<String?>((ref) {
  return ref.watch(locationProvider).valueOrNull?.cityName;
});
