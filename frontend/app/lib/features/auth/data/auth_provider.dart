import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/notifications_provider.dart';
import '../../../core/providers/providers.dart';
import '../domain/auth_models.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});

sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final UserProfile user;
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Start session restoration on init
    _restoreSession();
    return const AuthInitial();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> _restoreSession() async {
    state = const AuthLoading();
    try {
      final user = await _repo.restoreSession();
      if (user != null) {
        state = AuthAuthenticated(user);
        _registerFcm();
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final (user, _) = await _repo.login(
        LoginRequest(email: email.trim(), password: password),
      );
      state = AuthAuthenticated(user);
      _registerFcm();
      return true;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    state = const AuthLoading();
    try {
      final (user, _) = await _repo.register(
        RegisterRequest(
          name: name.trim(),
          email: email.trim(),
          phone: phone.trim(),
          password: password,
          role: role,
        ),
      );
      state = AuthAuthenticated(user);
      _registerFcm();
      return true;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(notificationsProvider.notifier).revokeToken();
    await _repo.logout();
    state = const AuthUnauthenticated();
  }

  void _registerFcm() {
    ref.read(notificationsProvider.notifier).registerToken();
  }

  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }

  UserProfile? get currentUser =>
      state is AuthAuthenticated ? (state as AuthAuthenticated).user : null;
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final currentUserProvider = Provider<UserProfile?>((ref) {
  final auth = ref.watch(authProvider);
  return auth is AuthAuthenticated ? auth.user : null;
});
