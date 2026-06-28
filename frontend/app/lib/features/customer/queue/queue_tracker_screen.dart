import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_button.dart';
import '../../../core/widgets/bb_error_widget.dart';
import '../../../core/widgets/bb_loading.dart';
import '../../../core/widgets/bb_snackbar.dart';
import '../../../core/widgets/bb_status_chip.dart';
import '../../shared/domain/queue_models.dart';
import 'queue_provider.dart';

class QueueTrackerScreen extends ConsumerWidget {
  const QueueTrackerScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final state = ref.watch(myQueueProvider(bookingId));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Your Queue'),
        actions: [
          IconButton(
            icon: Icon(
              state.isConnected
                  ? Icons.wifi_rounded
                  : Icons.wifi_off_rounded,
              size: 20,
              color: state.isConnected ? BBColors.success : colors.textTertiary,
            ),
            onPressed: null,
          ),
        ],
      ),
      body: state.isLoading
          ? const BBSkeletonListView(itemCount: 2, padding: EdgeInsets.all(20))
          : state.error != null
              ? BBErrorWidget(
                  error: state.error!,
                  onRetry: () =>
                      ref.read(myQueueProvider(bookingId).notifier).refresh(),
                )
              : state.myPosition == null
                  ? _NotInQueue(onGoHome: () => context.go('/home'))
                  : _QueueView(
                      position: state.myPosition!,
                      bookingId: bookingId,
                    ),
    );
  }
}

class _QueueView extends ConsumerWidget {
  const _QueueView({
    required this.position,
    required this.bookingId,
  });
  final MyQueuePosition position;
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final status = position.status.toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpacing.pageHorizontal,
        vertical: BBSpacing.pageVertical,
      ),
      child: Column(
        children: [
          // Status header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(BBSpacing.xl),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(BBRadius.xl),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                BBStatusChip(status: status),
                const SizedBox(height: BBSpacing.xl),
                if (status == 'WAITING' || status == 'QUEUED') ...[
                  Text(
                    '#${position.position}',
                    style: BBTypography.textTheme.displayLarge?.copyWith(
                      color: BBColors.amber,
                      fontSize: 80,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'in queue',
                    style: BBTypography.textTheme.bodyLarge?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ] else if (status == 'READY') ...[
                  const Icon(
                    Icons.notifications_active_rounded,
                    size: 60,
                    color: BBColors.amber,
                  ),
                  const SizedBox(height: BBSpacing.md),
                  Text(
                    'You\'re Next!',
                    style: BBTypography.textTheme.headlineLarge?.copyWith(
                      color: colors.text,
                    ),
                  ),
                  Text(
                    'Please proceed to the barber.',
                    style: BBTypography.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ] else if (status == 'CALLED') ...[
                  const Icon(
                    Icons.chair_rounded,
                    size: 60,
                    color: BBColors.amber,
                  ),
                  const SizedBox(height: BBSpacing.md),
                  Text(
                    'Chair Assigned!',
                    style: BBTypography.textTheme.headlineLarge?.copyWith(
                      color: colors.text,
                    ),
                  ),
                  if (position.chairLabel != null)
                    Text(
                      position.chairLabel!,
                      style: BBTypography.textTheme.displaySmall?.copyWith(
                        color: BBColors.amber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ] else if (status == 'IN_SERVICE') ...[
                  const Icon(
                    Icons.content_cut_rounded,
                    size: 60,
                    color: BBColors.amber,
                  ),
                  const SizedBox(height: BBSpacing.md),
                  Text(
                    'In Service',
                    style: BBTypography.textTheme.headlineLarge?.copyWith(
                      color: colors.text,
                    ),
                  ),
                  Text(
                    'Enjoy your experience!',
                    style: BBTypography.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ] else if (status == 'COMPLETED') ...[
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 60,
                    color: BBColors.success,
                  ),
                  const SizedBox(height: BBSpacing.md),
                  Text(
                    'All Done!',
                    style: BBTypography.textTheme.headlineLarge?.copyWith(
                      color: colors.text,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: BBSpacing.base),

          // Info grid
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.timer_outlined,
                  label: 'Wait',
                  value: position.estimatedWaitMinutes > 0
                      ? '~${position.estimatedWaitMinutes}m'
                      : '—',
                ),
              ),
              const SizedBox(width: BBSpacing.sm),
              Expanded(
                child: _InfoTile(
                  icon: Icons.content_cut_rounded,
                  label: 'Service',
                  value: position.serviceNames.isNotEmpty
                      ? position.serviceNames
                      : '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Barber',
                  value: position.barberName ?? 'Assigning...',
                ),
              ),
              const SizedBox(width: BBSpacing.sm),
              Expanded(
                child: _InfoTile(
                  icon: Icons.store_outlined,
                  label: 'Shop',
                  value: position.shopName,
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.xl),

          // Actions
          if (status == 'READY') ...[
            BBButton(
              label: 'Check In',
              onPressed: () async {
                try {
                  await ref
                      .read(myQueueProvider(bookingId).notifier)
                      .checkIn();
                } catch (e) {
                  if (context.mounted) {
                    showBBSnackbar(context,
                        message: e.toString(), isError: true);
                  }
                }
              },
              icon: Icons.check_circle_outline_rounded,
            ),
            const SizedBox(height: BBSpacing.sm),
          ],
          if (status == 'COMPLETED') ...[
            BBButton(
              label: 'Leave a Review',
              onPressed: () =>
                  context.push('/review/$bookingId'),
              icon: Icons.star_outline_rounded,
            ),
            const SizedBox(height: BBSpacing.sm),
          ],
          if (status == 'WAITING' || status == 'QUEUED') ...[
            BBButton(
              label: 'Smart Arrival',
              onPressed: () => context.push('/arrival/$bookingId'),
              variant: BBButtonVariant.secondary,
              icon: Icons.navigation_rounded,
            ),
            const SizedBox(height: BBSpacing.sm),
            BBButton(
              label: 'Cancel',
              onPressed: () => _confirmCancel(context, ref),
              variant: BBButtonVariant.destructive,
              icon: Icons.cancel_outlined,
            ),
          ],
          if (status == 'COMPLETED' || status == 'CANCELLED' ||
              status == 'NO_SHOW') ...[
            BBButton(
              label: 'Back to Home',
              onPressed: () => context.go('/home'),
              variant: BBButtonVariant.secondary,
              icon: Icons.home_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel?'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text(
              'Cancel Booking',
              style: TextStyle(color: BBColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref.read(myQueueProvider(bookingId).notifier).cancel();
        if (context.mounted) context.go('/home');
      } catch (e) {
        if (context.mounted) {
          showBBSnackbar(context, message: e.toString(), isError: true);
        }
      }
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: colors.textTertiary),
              const SizedBox(width: 4),
              Text(
                label,
                style: BBTypography.textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.xs),
          Text(
            value,
            style: BBTypography.textTheme.titleMedium?.copyWith(
              color: colors.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _NotInQueue extends StatelessWidget {
  const _NotInQueue({required this.onGoHome});
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BBSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.queue_outlined,
              size: 64,
              color: BBColors.amber,
            ),
            const SizedBox(height: BBSpacing.base),
            Text(
              'Not in queue',
              style: BBTypography.textTheme.headlineSmall?.copyWith(
                color: context.bbColors.text,
              ),
            ),
            const SizedBox(height: BBSpacing.sm),
            Text(
              'This booking doesn\'t have an active queue position.',
              style: BBTypography.textTheme.bodyMedium?.copyWith(
                color: context.bbColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BBSpacing.xl),
            BBButton(
              label: 'Go Home',
              onPressed: onGoHome,
              expand: false,
            ),
          ],
        ),
      ),
    );
  }
}
