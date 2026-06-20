import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      ),
      body: state.messages.isEmpty
          ? Center(
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
                      Icons.notifications_none_rounded,
                      size: 36,
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: BBSpacing.base),
                  Text(
                    'No notifications yet',
                    style: BBTypography.textTheme.titleMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: BBSpacing.xs),
                  Text(
                    'Queue updates, booking reminders and\nmore will appear here.',
                    style: BBTypography.textTheme.bodySmall?.copyWith(
                      color: colors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: BBSpacing.pageHorizontal,
                vertical: BBSpacing.base,
              ),
              itemCount: state.messages.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: BBSpacing.sm),
              itemBuilder: (ctx, i) =>
                  _NotificationCard(notification: state.messages[i]),
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});
  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BBColors.amber.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.notifications_rounded,
                size: 18,
                color: BBColors.amber,
              ),
            ),
          ),
          const SizedBox(width: BBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (notification.title.isNotEmpty)
                  Text(
                    notification.title,
                    style: BBTypography.textTheme.titleSmall?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                    ),
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
