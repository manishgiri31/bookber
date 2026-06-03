import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../app/config/app_env.dart';
import '../models/bookber_models.dart';

class SocketService {
  io.Socket? _socket;

  final _eventsController = StreamController<Map<String, dynamic>>.broadcast();
  final _queueUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _chairAssignedController = StreamController<ChairAssignment>.broadcast();
  final _serviceStartedController = StreamController<String>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventsController.stream;
  Stream<Map<String, dynamic>> get onQueueUpdate => _queueUpdateController.stream;
  Stream<ChairAssignment> get onChairAssigned => _chairAssignedController.stream;
  Stream<String> get onServiceStarted => _serviceStartedController.stream;
  Stream<bool> get onConnectionChange => _connectionController.stream;

  void connect(String userId, String token) {
    _socket?.dispose();
    _socket = io.io(
      AppEnv.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setAuth({'token': token, 'userId': userId})
          .build(),
    );
    _setupListeners();
    _socket!.connect();
  }

  void joinShopRoom(String shopId) {
    _socket?.emit('queue:join_room', {'shopId': shopId});
  }

  void leaveShopRoom(String shopId) {
    _socket?.emit('queue:leave_room', {'shopId': shopId});
  }

  void emit(String event, Map<String, dynamic> data) {
    _socket?.emit(event, data);
  }

  void _setupListeners() {
    _socket
      ?..onConnect((_) => _connectionController.add(true))
      ..onDisconnect((_) => _connectionController.add(false))
      ..on('queue:updated', (data) {
        final payload = _asMap(data);
        _queueUpdateController.add(payload);
        _eventsController.add({'event': 'queue:updated', 'data': payload});
        _eventsController.add({'event': 'queue.updated', 'data': payload});
      })
      ..on('chair:assigned', (data) {
        final payload = _asMap(data);
        _chairAssignedController.add(ChairAssignment.fromJson(payload));
        _eventsController.add({'event': 'chair:assigned', 'data': payload});
        _eventsController.add({'event': 'chair.allocated', 'data': payload});
      })
      ..on('service:started', (data) {
        final payload = _asMap(data);
        _serviceStartedController.add(payload['bookingId']?.toString() ?? '');
        _eventsController.add({'event': 'service:started', 'data': payload});
      })
      ..on('service:completed', (data) {
        _eventsController.add({'event': 'service:completed', 'data': _asMap(data)});
      })
      ..on('admin:activity', (data) {
        _eventsController.add({'event': 'admin:activity', 'data': data});
      });
  }

  bool get isConnected => _socket?.connected ?? false;

  void disconnect() {
    _socket?.disconnect();
  }

  Future<void> dispose() async {
    _socket?.dispose();
    await _eventsController.close();
    await _queueUpdateController.close();
    await _chairAssignedController.close();
    await _serviceStartedController.close();
    await _connectionController.close();
  }

  Map<String, dynamic> _asMap(dynamic data) {
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }
}
