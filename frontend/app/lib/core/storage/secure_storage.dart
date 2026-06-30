import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract final class StorageKeys {
  static const String accessToken = 'bb_access_token';
  static const String refreshToken = 'bb_refresh_token';
  static const String userId = 'bb_user_id';
  static const String userRole = 'bb_user_role';
  static const String userName = 'bb_user_name';
  static const String userEmail = 'bb_user_email';
  static const String userPhone = 'bb_user_phone';
  static const String barberId = 'bb_barber_id';
  static const String themeMode = 'bb_theme_mode';
}

class SecureStorage {
  const SecureStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const SecureStorage _instance = SecureStorage(
    FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  static SecureStorage get instance => _instance;

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      write(StorageKeys.accessToken, accessToken),
      write(StorageKeys.refreshToken, refreshToken),
    ]);
  }

  Future<String?> get accessToken => read(StorageKeys.accessToken);
  Future<String?> get refreshToken => read(StorageKeys.refreshToken);

  Future<void> clearSession() async {
    await Future.wait([
      delete(StorageKeys.accessToken),
      delete(StorageKeys.refreshToken),
      delete(StorageKeys.userId),
      delete(StorageKeys.userRole),
      delete(StorageKeys.userName),
      delete(StorageKeys.userEmail),
      delete(StorageKeys.userPhone),
      delete(StorageKeys.barberId),
    ]);
  }
}
