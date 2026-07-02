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
      // Send the refresh token in the body so the backend can revoke it.
      // Mobile clients have no cookie jar, so this is the only revocation path.
      final refreshToken = await _storage.refreshToken;
      await _api
          .post<void>(
            ApiEndpoints.logout,
            body: refreshToken != null ? {'refreshToken': refreshToken} : {},
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
    await _storage.clearSession();
    _api.clearAuthToken();
  }

  Future<UserProfile?> restoreSession() async {
    final accessToken = await _storage.accessToken;
    if (accessToken == null) return null;

    await _api.setAuthToken(accessToken);

    // Read all cached fields in parallel — no network call needed.
    final [id, role, name, email, phone] = await Future.wait([
      _storage.read(StorageKeys.userId),
      _storage.read(StorageKeys.userRole),
      _storage.read(StorageKeys.userName),
      _storage.read(StorageKeys.userEmail),
      _storage.read(StorageKeys.userPhone),
    ]);

    if (id != null && role != null && name != null && email != null) {
      return UserProfile(
        id: id,
        role: role,
        name: name,
        email: email,
        phone: phone ?? '',
      );
    }

    // Fallback: cache was incomplete, fetch from API once.
    try {
      final user = await getMe();
      await _cacheProfile(user);
      return user;
    } catch (_) {
      await _storage.clearSession();
      return null;
    }
  }

  Future<void> _persistSession(AuthTokens tokens, UserProfile user) async {
    await Future.wait([
      _storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      ),
      _cacheProfile(user),
    ]);
    await _api.setAuthToken(tokens.accessToken);
  }

  Future<void> _cacheProfile(UserProfile user) => Future.wait([
        _storage.write(StorageKeys.userId, user.id),
        _storage.write(StorageKeys.userRole, user.role),
        _storage.write(StorageKeys.userName, user.name),
        _storage.write(StorageKeys.userEmail, user.email),
        _storage.write(StorageKeys.userPhone, user.phone),
      ]);
}
