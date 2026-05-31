import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di/providers.dart';

final socketEventsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final socket = ref.watch(socketServiceProvider);
  socket.connect();
  return socket.events;
});
