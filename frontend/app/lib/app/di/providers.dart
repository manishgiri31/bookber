import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/realtime/socket_providers.dart';
import '../../core/storage/app_storage.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../core/providers/auth_provider.dart';
import '../../features/booking/data/booking_repository.dart';
import '../../features/booking/presentation/booking_controller.dart';
import '../../features/booking/presentation/booking_flow_controller.dart';
import '../../features/queue/data/queue_repository.dart';
import '../../features/queue/presentation/queue_controller.dart';

final appBootstrapProvider = Provider<void>((ref) {
  ref.read(dioClientProvider);
  ref.read(socketServiceProvider);
  ref.read(appStorageProvider);
  ref.read(authRepositoryProvider);
  ref.read(bookingRepositoryProvider);
  ref.read(queueRepositoryProvider);
  ref.read(authControllerProvider);
  ref.read(bookingControllerProvider);
  ref.read(bookingFlowControllerProvider);
  ref.read(queueControllerProvider);
});
