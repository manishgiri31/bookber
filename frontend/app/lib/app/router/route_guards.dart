import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';

final authStateProvider = Provider<bool>((ref) {
  final state = ref.watch(authControllerProvider);
  return state.asData?.value.isAuthenticated ?? false;
});
