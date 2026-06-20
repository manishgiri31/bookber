import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_endpoints.dart';
import 'providers.dart';

// ─── In-app notification model ───────────────────────────────────────────────

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.data = const {},
  });

  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final Map<String, dynamic> data;

  factory AppNotification.fromMessage(RemoteMessage msg) => AppNotification(
        id: msg.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: msg.notification?.title ?? '',
        body: msg.notification?.body ?? '',
        receivedAt: msg.sentTime ?? DateTime.now(),
        data: msg.data,
      );
}

// ─── Notification state ───────────────────────────────────────────────────────

class NotificationState {
  const NotificationState({
    this.messages = const [],
    this.unreadCount = 0,
    this.fcmToken,
  });

  final List<AppNotification> messages;
  final int unreadCount;
  final String? fcmToken;

  NotificationState copyWith({
    List<AppNotification>? messages,
    int? unreadCount,
    String? fcmToken,
  }) =>
      NotificationState(
        messages: messages ?? this.messages,
        unreadCount: unreadCount ?? this.unreadCount,
        fcmToken: fcmToken ?? this.fcmToken,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class NotificationsNotifier extends Notifier<NotificationState> {
  StreamSubscription<RemoteMessage>? _sub;

  @override
  NotificationState build() {
    ref.onDispose(() => _sub?.cancel());
    _listenForeground();
    return const NotificationState();
  }

  void _listenForeground() {
    _sub = FirebaseMessaging.onMessage.listen((msg) {
      _addMessage(msg);
    });
  }

  void _addMessage(RemoteMessage msg) {
    final notification = AppNotification.fromMessage(msg);
    state = state.copyWith(
      messages: [notification, ...state.messages],
      unreadCount: state.unreadCount + 1,
    );
  }

  void markAllRead() {
    state = state.copyWith(unreadCount: 0);
  }

  void clearAll() {
    state = const NotificationState();
  }

  Future<void> registerToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (permission.authorizationStatus != AuthorizationStatus.authorized &&
          permission.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }

      final token = await messaging.getToken();
      if (token == null) return;

      state = state.copyWith(fcmToken: token);

      final api = ref.read(apiClientProvider);
      await api.post<void>(
        ApiEndpoints.notificationTokens,
        body: {
          'token': token,
          'platform': _platform(),
        },
      );

      messaging.onTokenRefresh.listen((newToken) async {
        state = state.copyWith(fcmToken: newToken);
        try {
          await api.post<void>(
            ApiEndpoints.notificationTokens,
            body: {'token': newToken, 'platform': _platform()},
          );
        } catch (_) {}
      });
    } catch (_) {
      // Non-fatal — FCM may not be configured in all environments
    }
  }

  Future<void> revokeToken() async {
    final token = state.fcmToken;
    if (token == null) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.delete<void>(ApiEndpoints.revokeToken(token));
    } catch (_) {}
    state = const NotificationState();
  }

  String _platform() {
    // ignore: do_not_use_environment
    const platform = String.fromEnvironment('FLUTTER_PLATFORM', defaultValue: '');
    if (platform == 'ios') return 'IOS';
    if (platform == 'web') return 'WEB';
    return 'ANDROID';
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationState>(
  NotificationsNotifier.new,
);
