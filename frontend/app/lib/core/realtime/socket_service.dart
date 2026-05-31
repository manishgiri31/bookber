import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../storage/app_storage.dart';

class SocketService {
  SocketService({
    required String socketUrl,
    required AppStorage storage,
  })  : _storage = storage,
        _socketUrl = socketUrl;

  final String _socketUrl;
  final AppStorage _storage;
  io.Socket? _socket;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _controller.stream;

  Future<void> connect() async {
    final token = _storage.accessToken;
    if (token == null) return;
    _socket?.dispose();
    _socket = io.io(
      _socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setAuth({'token': token})
          .build(),
    );

    _socket!
      ..onConnect((_) {})
      ..onReconnect((_) {})
      ..onDisconnect((_) {})
      ..on('booking.created', (data) => _controller.add({'event': 'booking.created', 'data': data}))
      ..on('booking.updated', (data) => _controller.add({'event': 'booking.updated', 'data': data}))
      ..on('queue.updated', (data) => _controller.add({'event': 'queue.updated', 'data': data}))
      ..on('chair.allocated', (data) => _controller.add({'event': 'chair.allocated', 'data': data}))
      ..on('barber.delayed', (data) => _controller.add({'event': 'barber.delayed', 'data': data}))
      ..on('customer.checked_in', (data) => _controller.add({'event': 'customer.checked_in', 'data': data}));
  }

  void subscribeToBooking(String bookingId) {
    _socket?.emit('room:subscribe', {'bookingId': bookingId});
  }

  void subscribeToShop(String shopId) {
    _socket?.emit('room:subscribe', {'shopId': shopId});
  }

  Future<void> dispose() async {
    _socket?.dispose();
    await _controller.close();
  }
}
