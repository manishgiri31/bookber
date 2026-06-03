import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppEnv {
  const AppEnv._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://clump-passion-cruelty.ngrok-free.dev',
  );

  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'https://clump-passion-cruelty.ngrok-free.dev',
  );
}

const _defaultEnv = AppEnv._();

final appEnvProvider = Provider<AppEnv>((ref) => _defaultEnv);
