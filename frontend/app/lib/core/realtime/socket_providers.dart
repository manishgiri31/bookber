import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../storage/app_storage.dart';
import 'socket_service.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(service.dispose);
  return service;
});

final socketConnectionBootstrapProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  final socket = ref.watch(socketServiceProvider);
  if (user != null) {
    ref.read(appStorageProvider).getAccessToken().then((token) {
      if (token != null) socket.connect(user.id, token);
    });
  }
});

final socketConnectedProvider = StreamProvider<bool>((ref) {
  final socket = ref.watch(socketServiceProvider);
  return socket.onConnectionChange;
});

final socketEventsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  ref.watch(socketConnectionBootstrapProvider);
  return ref.watch(socketServiceProvider).events;
});
