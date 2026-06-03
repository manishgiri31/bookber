import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/bookber_models.dart';
import '../../core/storage/app_storage.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/auth_controller.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    repository: ref.watch(authRepositoryProvider),
    storage: ref.watch(appStorageProvider),
  );
});

final authStateProvider = StreamProvider<AuthState>((ref) async* {
  final controller = ref.watch(authControllerProvider.notifier);

  await controller.checkAuth(navigate: false);
  yield ref.read(authControllerProvider);

  await for (final state in controller.stream) {
    yield state;
  }
});

final currentUserProvider = Provider<UserProfile?>((ref) {
  final state = ref.watch(authControllerProvider);
  return state is AuthAuthenticated ? state.user : null;
});
