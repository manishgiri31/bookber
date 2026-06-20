import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class UserLocation {
  const UserLocation({required this.latitude, required this.longitude});
  final double latitude;
  final double longitude;
}

class LocationNotifier extends AsyncNotifier<UserLocation?> {
  @override
  Future<UserLocation?> build() => _fetch();

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

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      return UserLocation(latitude: pos.latitude, longitude: pos.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final locationProvider =
    AsyncNotifierProvider<LocationNotifier, UserLocation?>(
  LocationNotifier.new,
);
