import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppEnv {
  const AppEnv({
    required this.apiBaseUrl,
    required this.socketUrl,
  });

  final String apiBaseUrl;
  final String socketUrl;
}

const _defaultEnv = AppEnv(
  apiBaseUrl: 'http://localhost:3000',
  socketUrl: 'http://localhost:3000',
);

final appEnvProvider = Provider<AppEnv>((ref) => _defaultEnv);
