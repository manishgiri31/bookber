import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/bookber_models.dart' show QueueEntry;
import '../../../core/network/api_result.dart';
import '../../../core/realtime/socket_providers.dart';
import '../data/queue_repository.dart';

class QueuePosition {
  const QueuePosition({
    required this.position,
    required this.estimatedWaitMinutes,
    required this.totalInQueue,
    required this.status,
    this.chairNumber,
    this.serviceName,
    this.barberName,
    this.serviceStartTime,
    this.estimatedCompletionTime,
  });

  final int position;
  final int estimatedWaitMinutes;
  final int totalInQueue;
  final QueueStatus status;
  final int? chairNumber;
  final String? serviceName;
  final String? barberName;
  final DateTime? serviceStartTime;
  final DateTime? estimatedCompletionTime;
}

enum QueueStatus { waiting, next, inService, completed }

class QueueActivity {
  const QueueActivity({
    required this.id,
    required this.message,
    required this.timestamp,
    this.type = ActivityType.info,
  });

  final String id;
  final String message;
  final DateTime timestamp;
  final ActivityType type;
}

enum ActivityType { info, success, warning }

class ChairAssignment {
  const ChairAssignment({
    required this.chairNumber,
    required this.assignedAt,
  });

  final int chairNumber;
  final DateTime assignedAt;
}

final queueStatusProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, shopId) async {
  final result = await ref.read(queueRepositoryProvider).getQueueStatus(shopId);
  if (result is ApiSuccess<Map<String, dynamic>>) return result.data;
  throw Exception((result as ApiError<Map<String, dynamic>>).message);
});

final liveQueueProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, shopId) {
  final controller = StreamController<Map<String, dynamic>>.broadcast();
  final socket = ref.watch(socketServiceProvider);
  final repo = ref.watch(queueRepositoryProvider);
  Timer? pollTimer;

  Future<void> fetch() async {
    final result = await repo.getQueueStatus(shopId);
    if (result is ApiSuccess<Map<String, dynamic>> && !controller.isClosed) {
      controller.add(result.data);
    }
  }

  socket.joinShopRoom(shopId);
  fetch();
  final sub = socket.onQueueUpdate.listen((data) {
    if (data['shopId']?.toString() == shopId || data['shopId'] == null) {
      controller.add(data);
    }
  });
  pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
    if (!socket.isConnected) fetch();
  });

  ref.onDispose(() {
    socket.leaveShopRoom(shopId);
    sub.cancel();
    pollTimer?.cancel();
    controller.close();
  });

  return controller.stream;
});

final queuePositionProvider = StreamProvider.family<QueuePosition, String>((ref, shopId) {
  return ref.watch(liveQueueProvider(shopId).stream).map(_positionFromJson);
});

final queueActivityProvider = StateProvider<List<QueueActivity>>((ref) => const []);
final chairAssignmentProvider = StateProvider<ChairAssignment?>((ref) => null);

final chairAssignmentStreamProvider = StreamProvider<ChairAssignment?>((ref) {
  return ref.watch(socketServiceProvider).onChairAssigned.map((assignment) {
    return ChairAssignment(chairNumber: assignment.chairNumber, assignedAt: assignment.assignedAt);
  });
});

final connectionStatusProvider = StateProvider<ConnectionStatus>((ref) {
  final connected = ref.watch(socketConnectedProvider).value ?? false;
  return connected ? ConnectionStatus.connected : ConnectionStatus.offline;
});

enum ConnectionStatus { connected, reconnecting, offline }

final joinQueueProvider = FutureProvider.family<void, ({String shopId, List<String> serviceIds})>((ref, params) async {
  final result = await ref.read(queueRepositoryProvider).joinQueue(params.shopId, params.serviceIds);
  if (result is ApiError<QueueEntry>) throw Exception(result.message);
  ref.invalidate(queueStatusProvider(params.shopId));
});

QueuePosition _positionFromJson(Map<String, dynamic> json) {
  final position = _asInt(json['myPosition'], fallback: -1);
  return QueuePosition(
    position: position,
    estimatedWaitMinutes: _asInt(json['estimatedWaitMinutes']),
    totalInQueue: (json['entries'] as List<dynamic>?)?.length ?? 0,
    status: _statusFromString(json['status']?.toString()),
    chairNumber: _asIntOrNull(json['chairNumber']),
    serviceName: json['serviceName']?.toString(),
    barberName: json['barberName']?.toString(),
  );
}

QueueStatus _statusFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'next':
      return QueueStatus.next;
    case 'in_service':
    case 'inservice':
      return QueueStatus.inService;
    case 'completed':
      return QueueStatus.completed;
    default:
      return QueueStatus.waiting;
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  return value is int ? value : int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _asIntOrNull(dynamic value) {
  return value == null ? null : _asInt(value);
}
