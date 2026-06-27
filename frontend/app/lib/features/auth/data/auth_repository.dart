import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/auth_models.dart';

class AuthRepository {
  const AuthRepository(this._api, this._storage);

  final ApiClient _api;
  final SecureStorage _storage;

  Future<(UserProfile, AuthTokens)> login(LoginRequest req) async {
    final data = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      body: req.toJson(),
    );
    final tokens = AuthTokens.fromJson(data);
    final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    await _persistSession(tokens, user);
    return (user, tokens);
  }

  Future<(UserProfile, AuthTokens)> register(RegisterRequest req) async {
    final data = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      body: req.toJson(),
    );
    final tokens = AuthTokens.fromJson(data);
    final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    await _persistSession(tokens, user);
    return (user, tokens);
  }

  Future<UserProfile> getMe() async {
    final data = await _api.get<Map<String, dynamic>>(ApiEndpoints.me);
    return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile({String? phone}) async {
    final data = await _api.patch<Map<String, dynamic>>(
      ApiEndpoints.updateMe,
      body: {
        if (phone != null && phone.isNotEmpty) 'phoneNumber': phone,
        if (phone != null && phone.isEmpty) 'phoneNumber': null,
      },
    );
    return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
  }

  void clearLocalSession() {
    _storage.clearSession();
    _api.clearAuthToken();
  }

  Future<void> logout() async {
    try {
      await _api.post<void>(ApiEndpoints.logout, body: {})
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
    await _storage.clearSession();
    _api.clearAuthToken();
  }

  Future<UserProfile?> restoreSession() async {
    final accessToken = await _storage.accessToken;
    if (accessToken == null) return null;

    try {
      await _api.setAuthToken(accessToken);
      return await getMe();
    } catch (_) {
      await _storage.clearSession();
      return null;
    }
  }

  Future<void> _persistSession(AuthTokens tokens, UserProfile user) async {
    await _storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    await Future.wait([
      _storage.write(StorageKeys.userId, user.id),
      _storage.write(StorageKeys.userRole, user.role),
    ]);
    await _api.setAuthToken(tokens.accessToken);
  }
}
