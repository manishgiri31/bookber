import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_env.dart';
import 'di/providers.dart';

Future<ProviderContainer> buildAppContainer() async {
  final container = ProviderContainer();
  container.read(appEnvProvider);
  container.read(appBootstrapProvider);
  return container;
}
