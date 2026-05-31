import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppStorage {
  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  Future<void> saveTokens({String? accessToken, String? refreshToken}) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
  }
}

final appStorageProvider = Provider<AppStorage>((ref) => AppStorage());
