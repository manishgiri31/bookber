import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/constants/api_endpoints.dart';
import '../../../core/providers/providers.dart';
import '../../shared/domain/queue_models.dart';
import '../booking/booking_provider.dart';
import '../home/home_provider.dart';

// ─────────────── Queue state ───────────────

class QueueState {
  const QueueState({
    this.entries = const [],
    this.myPosition,
    this.isLoading = false,
    this.isConnected = false,
    this.error,
  });

  final List<QueueEntry> entries;
  final MyQueuePosition? myPosition;
  final bool isLoading;
  final bool isConnected;
  final String? error;

  QueueState copyWith({
    List<QueueEntry>? entries,
    MyQueuePosition? myPosition,
    bool? isLoading,
    bool? isConnected,
    String? error,
    bool clearError = false,
  }) =>
      QueueState(
        entries: entries ?? this.entries,
        myPosition: myPosition ?? this.myPosition,
        isLoading: isLoading ?? this.isLoading,
        isConnected: isConnected ?? this.isConnected,
        error: clearError ? null : (error ?? this.error),
      );
}

// ─────────────── Live queue for a shop ───────────────

class QueueNotifier extends StateNotifier<QueueState> {
  QueueNotifier(this._ref, this._shopId) : super(const QueueState(isLoading: true)) {
    _load();
    _connectSocket();
  }

  final Ref _ref;
  final String _shopId;
  io.Socket? _socket;

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = _ref.read(apiClientProvider);
      final data =
          await api.get<Map<String, dynamic>>(ApiEndpoints.shopQueue(_shopId));
      final entries = (data['queue'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(QueueEntry.fromJson)
          .toList();
      if (mounted) state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _connectSocket() async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.accessToken;
    if (token == null) return;

    _socket = io.io(
      ApiEndpoints.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setAuth({'token': token})
          .build(),
    );

    _socket!
      ..onConnect((_) {
        if (mounted) state = state.copyWith(isConnected: true);
        _socket!.emit('room:subscribe', {'shopId': _shopId});
      })
      ..onDisconnect((_) {
        if (mounted) state = state.copyWith(isConnected: false);
      })
      ..on('queue.updated', (_) => _load())
      ..on('queue:updated', (_) => _load())
      ..connect();
  }

  Future<void> refresh() => _load();
}

final queueProvider = StateNotifierProvider.autoDispose
    .family<QueueNotifier, QueueState, String>(
  (ref, shopId) => QueueNotifier(ref, shopId),
);

// ─────────────── Customer's own queue position ───────────────

class MyQueueNotifier extends StateNotifier<QueueState> {
  MyQueueNotifier(this._ref, this._bookingId)
      : super(const QueueState(isLoading: true)) {
    _load();
    _connectSocket();
  }

  final Ref _ref;
  final String _bookingId;
  io.Socket? _socket;

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = _ref.read(apiClientProvider);
      final data = await api.get<Map<String, dynamic>>(
        ApiEndpoints.bookingById(_bookingId),
      );
      final bookingData =
          data['booking'] as Map<String, dynamic>? ?? data;
      final position = MyQueuePosition.fromBooking(bookingData);
      if (mounted) state = state.copyWith(myPosition: position, isLoading: false);
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _connectSocket() async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.accessToken;
    if (token == null) return;

    _socket = io.io(
      ApiEndpoints.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setAuth({'token': token})
          .build(),
    );

    _socket!
      ..onConnect((_) {
        if (mounted) state = state.copyWith(isConnected: true);
      })
      ..onDisconnect((_) {
        if (mounted) state = state.copyWith(isConnected: false);
      })
      ..on('queue.updated', (_) => _load())
      ..on('booking.called', (data) {
        if (data is Map && data['bookingId'] == _bookingId) {
          _load();
        }
      })
      ..on('chair.updated', (_) => _load())
      ..connect();
  }

  Future<void> checkIn() async {
    if (state.myPosition == null) return;
    final api = _ref.read(apiClientProvider);
    await api.post<void>(ApiEndpoints.checkIn(_bookingId), body: {});
    await _load();
  }

  Future<void> cancel() async {
    final api = _ref.read(apiClientProvider);
    await api.post<void>(ApiEndpoints.cancelBooking(_bookingId), body: {});
    await _load();
    // These providers are autoDispose but the home screen underneath this route
    // stays mounted (offstage) during navigation, so it never naturally refetches.
    _ref.invalidate(activeBookingsProvider);
    _ref.invalidate(myBookingsProvider);
  }

  Future<void> refresh() => _load();
}

final myQueueProvider = StateNotifierProvider.autoDispose
    .family<MyQueueNotifier, QueueState, String>(
  (ref, bookingId) => MyQueueNotifier(ref, bookingId),
);
