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

// Simple derived provider — no side-effects, no checkAuth calls.
final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authControllerProvider);
});

final currentUserProvider = Provider<UserProfile?>((ref) {
  final state = ref.watch(authControllerProvider);
  return state is AuthAuthenticated ? state.user : null;
});
