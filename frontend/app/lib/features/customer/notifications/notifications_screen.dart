import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/providers/notifications_provider.dart';

enum _Category { all, booking, queue, offers, loyalty, system }

extension _CatExt on _Category {
  String get label => switch (this) {
        _Category.all => 'All',
        _Category.booking => 'Booking',
        _Category.queue => 'Queue',
        _Category.offers => 'Offers',
        _Category.loyalty => 'Loyalty',
        _Category.system => 'System',
      };

  IconData get icon => switch (this) {
        _Category.all => Icons.notifications_rounded,
        _Category.booking => Icons.calendar_today_rounded,
        _Category.queue => Icons.queue_rounded,
        _Category.offers => Icons.local_offer_rounded,
        _Category.loyalty => Icons.military_tech_rounded,
        _Category.system => Icons.info_outline_rounded,
      };

  Color get color => switch (this) {
        _Category.all => BBColors.amber,
        _Category.booking => BBColors.info,
        _Category.queue => BBColors.amber,
        _Category.offers => BBColors.success,
        _Category.loyalty => const Color(0xFFFFD700),
        _Category.system => BBColors.warning,
      };
}

_Category _categorize(AppNotification n) {
  final t = n.title.toLowerCase();
  final type = n.data['type']?.toString().toLowerCase() ?? '';
  if (type.contains('booking') || t.contains('booking') || t.contains('appointment')) {
    return _Category.booking;
  }
  if (type.contains('queue') || t.contains('queue') || t.contains('wait') || t.contains('ready')) {
    return _Category.queue;
  }
  if (type.contains('offer') || t.contains('offer') || t.contains('deal') || t.contains('discount')) {
    return _Category.offers;
  }
  if (type.contains('loyalty') || t.contains('points') || t.contains('tier') || t.contains('reward')) {
    return _Category.loyalty;
  }
  return _Category.system;
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _categories = _Category.values;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Notifications',
          style: BBTypography.textTheme.titleLarge?.copyWith(
            color: colors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (state.messages.isNotEmpty)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).clearAll(),
              child: Text(
                'Clear all',
                style: BBTypography.textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: colors.text,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: BBColors.amber,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _categories.map((c) => Tab(text: c.label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: _categories.map((cat) {
          final items = cat == _Category.all
              ? state.messages
              : state.messages
                  .where((n) => _categorize(n) == cat)
                  .toList();
          return _NotificationList(notifications: items, category: cat);
        }).toList(),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.notifications,
    required this.category,
  });
  final List<AppNotification> notifications;
  final _Category category;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                category.icon,
                size: 32,
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(height: BBSpacing.base),
            Text(
              'No ${category.label.toLowerCase()} notifications',
              style: BBTypography.textTheme.titleMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: BBSpacing.xs),
            Text(
              category == _Category.all
                  ? 'Queue updates, booking reminders\nand more will appear here.'
                  : '${category.label} notifications will appear here.',
              style: BBTypography.textTheme.bodySmall?.copyWith(
                color: colors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpacing.pageHorizontal,
        vertical: BBSpacing.base,
      ),
      itemCount: notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: BBSpacing.sm),
      itemBuilder: (ctx, i) => _NotificationCard(
        notification: notifications[i],
        category: _categorize(notifications[i]),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.category,
  });
  final AppNotification notification;
  final _Category category;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final cat = category;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(cat.icon, size: 18, color: cat.color),
            ),
          ),
          const SizedBox(width: BBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title.isNotEmpty
                            ? notification.title
                            : cat.label,
                        style: BBTypography.textTheme.titleSmall?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(BBRadius.full),
                      ),
                      child: Text(
                        cat.label,
                        style: BBTypography.textTheme.labelSmall?.copyWith(
                          color: cat.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (notification.body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: BBTypography.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: BBSpacing.xs),
                Text(
                  _timeAgo(notification.receivedAt),
                  style: BBTypography.textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
