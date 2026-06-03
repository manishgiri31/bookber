import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_result.dart';
import '../../../app/router/app_router.dart';
import '../../../core/models/bookber_models.dart';
import '../../../core/storage/app_storage.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthRepository repository,
    required AppStorage storage,
  })  : _repository = repository,
        _storage = storage,
        super(const AuthInitial());

  final AuthRepository _repository;
  final AppStorage _storage;

  Future<void> login(
    String email,
    String password, {
    required UserRole role,
  }) async {
    state = const AuthLoading();

    final result = await _repository.login(email, password, role.value);
    if (result is ApiSuccess<AuthResponse>) {
      final authResponse = result.data;
      await _storage.saveTokens(authResponse.accessToken, authResponse.refreshToken);
      await _storage.saveUser(authResponse.user.toJson());
      state = AuthAuthenticated(authResponse.user);
      _navigateByRole(authResponse.user.role);
      return;
    }

    state = AuthError((result as ApiError).message);
  }

  Future<void> register(RegisterRequest request) async {
    state = const AuthLoading();

    final result = await _repository.register(request);
    if (result is ApiSuccess<AuthResponse>) {
      final authResponse = result.data;
      await _storage.saveTokens(authResponse.accessToken, authResponse.refreshToken);
      await _storage.saveUser(authResponse.user.toJson());
      state = AuthAuthenticated(authResponse.user);
      _navigateByRole(authResponse.user.role);
      return;
    }

    state = AuthError((result as ApiError).message);
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {
      // Ignore logout failure; session must still be cleared locally.
    }

    await _storage.clear();
    state = const AuthInitial();
    _redirectToLogin();
  }

  Future<void> checkAuth({bool navigate = true}) async {
    state = const AuthLoading();

    final accessToken = await _storage.getAccessToken();
    if (accessToken == null) {
      state = const AuthInitial();
      return;
    }

    final result = await _repository.getMe();
    if (result is ApiSuccess<UserProfile>) {
      final user = result.data;
      await _storage.saveUser(user.toJson());
      state = AuthAuthenticated(user);
      if (navigate) {
        _navigateByRole(user.role);
      }
      return;
    }

    if (result is ApiError<UserProfile> && result.code == 'SESSION_EXPIRED') {
      state = const AuthInitial();
      return;
    }

    state = const AuthInitial();
  }

  void _navigateByRole(String role) {
    final context = appRouterKey.currentContext;
    if (context == null) return;

    if (role == 'barber') {
      GoRouter.of(context).go('/barber');
      return;
    }

    if (role == 'admin') {
      GoRouter.of(context).go('/admin');
      return;
    }

    GoRouter.of(context).go('/home');
  }

  void _redirectToLogin() {
    final context = appRouterKey.currentContext;
    if (context == null) return;
    GoRouter.of(context).go('/login');
  }
}
