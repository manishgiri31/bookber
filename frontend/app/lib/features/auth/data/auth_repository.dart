import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_storage.dart';
import '../domain/auth_state.dart';

class AuthRepository {
  AuthRepository(this._storage);

  final AppStorage _storage;

  Future<AuthState> restoreSession() async {
    final token = _storage.accessToken;
    return token == null
        ? AuthState.unauthenticated
        : AuthState(isAuthenticated: true, userId: 'demo-user');
  }

  Future<AuthState> login(String email, String password) async {
    await _storage.saveTokens(accessToken: 'access-demo', refreshToken: 'refresh-demo');
    return const AuthState(isAuthenticated: true, userId: 'demo-user');
  }

  Future<void> logout() async {
    await _storage.clear();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(appStorageProvider));
});
