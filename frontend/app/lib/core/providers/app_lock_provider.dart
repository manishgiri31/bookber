import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/biometric_service.dart';
import '../storage/secure_storage.dart';
import 'providers.dart';

final biometricServiceProvider = Provider<BiometricService>(
  (_) => BiometricService(),
);

/// Whether the user has opted into biometric app-lock (persisted on-device).
class BiometricEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    Future.microtask(_load);
    return false;
  }

  Future<void> _load() async {
    final storage = ref.read(secureStorageProvider);
    final value = await storage.read(StorageKeys.biometricEnabled);
    state = value == 'true';
  }

  Future<void> set(bool enabled) async {
    state = enabled;
    final storage = ref.read(secureStorageProvider);
    await storage.write(StorageKeys.biometricEnabled, enabled.toString());
  }
}

final biometricEnabledProvider =
    NotifierProvider<BiometricEnabledNotifier, bool>(
        BiometricEnabledNotifier.new);

/// Gates access to the authenticated app behind a biometric prompt.
///
/// Starts `true` (locked) so a cold start with biometric-lock enabled never
/// flashes authenticated content before the prompt resolves. [SplashScreen]
/// and the router redirect both consult this after session restoration.
class AppLockNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void lock() => state = true;
  void unlock() => state = false;
}

final appLockProvider = NotifierProvider<AppLockNotifier, bool>(
  AppLockNotifier.new,
);
