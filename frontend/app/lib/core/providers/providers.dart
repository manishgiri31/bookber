import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_provider.dart';
import '../network/api_client.dart';
import '../storage/secure_storage.dart';

final secureStorageProvider = Provider<SecureStorage>(
  (_) => SecureStorage.instance,
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(
    storage: storage,
    onSessionExpired: () {
      try {
        ref.read(authProvider.notifier).forceLogout();
      } catch (_) {}
    },
  );
});
