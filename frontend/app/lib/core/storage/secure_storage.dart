import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Serializes access to [FlutterSecureStorage] behind a single-lane queue.
///
/// flutter_secure_storage_web lazily initializes an AES wrap-key in
/// IndexedDB. Concurrent reads/writes issued before that key is cached race
/// on the underlying WebCrypto calls and throw `OperationError`, which
/// silently kills whichever request triggered it (e.g. the auth interceptor
/// reading the access token). Running every operation through this queue
/// makes storage access effectively single-threaded, matching the plugin's
/// actual concurrency guarantees.
Future<void> _storageQueue = Future.value();

Future<T> _serialized<T>(Future<T> Function() operation) {
  final result = _storageQueue.then((_) => operation());
  _storageQueue = result.then((_) {}, onError: (_) {});
  return result;
}

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
  static const String biometricEnabled = 'bb_biometric_enabled';
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
      _serialized(() => _storage.write(key: key, value: value));

  Future<String?> read(String key) =>
      _serialized(() => _storage.read(key: key));

  Future<void> delete(String key) => _serialized(() => _storage.delete(key: key));

  Future<void> deleteAll() => _serialized(() => _storage.deleteAll());

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
