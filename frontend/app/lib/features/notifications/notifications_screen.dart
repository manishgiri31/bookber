import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';

// ── Stub model ─────────────────────────────────────────────────

enum _NotifType { booking, queue, promo, system }

class _Notif {
  const _Notif({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
  });

  final String id;
  final _NotifType type;
  final String title;
  final String body;
  final DateTime time;
  final bool read;

  _Notif copyWith({bool? read}) =>
      _Notif(id: id, type: type, title: title, body: body, time: time, read: read ?? this.read);
}

// ── Provider (stub — replace with real API) ────────────────────

class _NotifsNotifier extends StateNotifier<List<_Notif>> {
  _NotifsNotifier()
      : super([
          _Notif(
            id: '1',
            type: _NotifType.booking,
            title: 'Booking Confirmed',
            body: 'Your appointment at The Classic Barber is confirmed for today at 3:00 PM.',
            time: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
          _Notif(
            id: '2',
            type: _NotifType.queue,
            title: "You're Next!",
            body: 'Only 1 person ahead of you. Head to the shop now.',
            time: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          _Notif(
            id: '3',
            type: _NotifType.booking,
            title: 'Appointment Reminder',
            body: 'Your haircut at Kings Cut Lounge is tomorrow at 11:00 AM.',
            time: DateTime.now().subtract(const Duration(hours: 3)),
            read: true,
          ),
          _Notif(
            id: '4',
            type: _NotifType.promo,
            title: '20% Off This Weekend',
            body: 'Enjoy a special discount at partner shops this Saturday and Sunday.',
            time: DateTime.now().subtract(const Duration(days: 1)),
            read: true,
          ),
          _Notif(
            id: '5',
            type: _NotifType.system,
            title: 'Profile Updated',
            body: 'Your profile information was updated successfully.',
            time: DateTime.now().subtract(const Duration(days: 2)),
            read: true,
          ),
        ]);

  void markRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(read: true) else n,
    ];
  }

  void markAllRead() {
    state = [for (final n in state) n.copyWith(read: true)];
  }
}

final _notifsProvider =
    StateNotifierProvider<_NotifsNotifier, List<_Notif>>(
  (ref) => _NotifsNotifier(),
);

// ── Screen ─────────────────────────────────────────────────────

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final notifs = ref.watch(_notifsProvider);
    final unread = notifs.where((n) => !n.read).length;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        backgroundColor: colors.bgCanvas,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: BBIconSize.md, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: BBTypography.headingL.copyWith(color: colors.textPrimary),
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => ref.read(_notifsProvider.notifier).markAllRead(),
              child: Text(
                'Mark all read',
                style: BBTypography.labelM.copyWith(color: BBColors.brandPrimary),
              ),
            ),
        ],
      ),
      body: notifs.isEmpty
          ? _EmptyState(colors: colors)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: BBSpacing.px8),
              itemCount: notifs.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: colors.borderSubtle,
                indent: BBSpacing.px16,
                endIndent: BBSpacing.px16,
              ),
              itemBuilder: (context, i) {
                final n = notifs[i];
                return _NotifTile(
                  notif: n,
                  onTap: () =>
                      ref.read(_notifsProvider.notifier).markRead(n.id),
                );
              },
            ),
    );
  }
}

// ── Tile ───────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.notif, required this.onTap});

  final _Notif notif;
  final VoidCallback onTap;

  static IconData _icon(_NotifType t) => switch (t) {
        _NotifType.booking => Icons.calendar_today_rounded,
        _NotifType.queue => Icons.people_rounded,
        _NotifType.promo => Icons.local_offer_rounded,
        _NotifType.system => Icons.info_rounded,
      };

  static Color _iconColor(_NotifType t) => switch (t) {
        _NotifType.booking => BBColors.brandPrimary,
        _NotifType.queue => BBColors.success,
        _NotifType.promo => BBColors.brandSecondary,
        _NotifType.system => BBColors.textSecondary,
      };

  String _timeLabel() {
    final diff = DateTime.now().difference(notif.time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notif.read ? Colors.transparent : BBColors.brandPrimaryDim,
        padding: const EdgeInsets.symmetric(
            horizontal: BBSpacing.px16, vertical: BBSpacing.px14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor(notif.type).withValues(alpha: 0.15),
                borderRadius: BBRadius.md,
              ),
              child: Icon(_icon(notif.type),
                  size: BBIconSize.md, color: _iconColor(notif.type)),
            ),
            const SizedBox(width: BBSpacing.px12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: BBTypography.headingS.copyWith(
                            color: colors.textPrimary,
                            fontWeight: notif.read
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: BBSpacing.px8),
                      Text(
                        _timeLabel(),
                        style: BBTypography.caption.copyWith(
                            color: colors.textDisabled),
                      ),
                    ],
                  ),
                  const SizedBox(height: BBSpacing.px4),
                  Text(
                    notif.body,
                    style: BBTypography.bodyS.copyWith(color: colors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!notif.read) ...[
              const SizedBox(width: BBSpacing.px8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: BBColors.brandPrimary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colors});
  final BBColorTheme colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 64, color: colors.textDisabled),
          const SizedBox(height: BBSpacing.px16),
          Text('No notifications yet',
              style: BBTypography.headingM.copyWith(color: colors.textPrimary)),
          const SizedBox(height: BBSpacing.px8),
          Text("We'll notify you about bookings, queue updates, and offers.",
              style: BBTypography.bodyM.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
