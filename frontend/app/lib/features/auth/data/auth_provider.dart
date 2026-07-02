import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/notifications_provider.dart';
import '../../../core/providers/providers.dart';
import '../../barber/dashboard/barber_provider.dart';
import '../../customer/home/home_provider.dart';
import '../../customer/payment/payment_provider.dart';
import '../../customer/wallet/wallet_provider.dart';
import '../domain/auth_models.dart';
import 'auth_repository.dart';

/// Invalidates every non-autoDispose provider that holds session-scoped data.
/// Must be called on both login AND logout to guarantee that a new session
/// never sees the previous user's cached state regardless of role.
void _resetSessionScopedState(Ref ref) {
  // Barber state
  ref.invalidate(barberDashProvider);

  // Customer state — these are non-autoDispose and survive navigation, so they
  // must be explicitly cleared when the session boundary is crossed.
  ref.invalidate(activeBookingsProvider);
  ref.invalidate(homeProvider);
  ref.invalidate(walletProvider);
  ref.invalidate(paymentHistoryProvider);

  // Cross-role
  ref.invalidate(notificationsProvider);
}

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
    Future.microtask(_restoreSession);
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
      _resetSessionScopedState(ref);
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
      _resetSessionScopedState(ref);
      state = AuthAuthenticated(user);
      _registerFcm();
      return true;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  Future<void> updateProfile({String? phone}) async {
    final updated = await _repo.updateProfile(phone: phone);
    if (state is AuthAuthenticated) {
      state = AuthAuthenticated(updated);
    }
  }

  Future<void> logout() async {
    // Fire-and-forget FCM token revocation — don't block logout on it
    ref.read(notificationsProvider.notifier).revokeToken().ignore();
    await _repo.logout(); // Has built-in 3-second timeout on the API call
    state = const AuthUnauthenticated();
    _resetSessionScopedState(ref);
  }

  void forceLogout() {
    _repo.clearLocalSession();
    state = const AuthUnauthenticated();
    _resetSessionScopedState(ref);
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
