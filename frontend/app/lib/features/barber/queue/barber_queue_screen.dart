import 'package:flutter/material.dart';
import '../../../core/design/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_button.dart';
import '../../../core/widgets/bb_loading.dart';
import '../../../core/widgets/bb_snackbar.dart';
import '../../../core/widgets/bb_status_chip.dart';
import '../../shared/domain/queue_models.dart';
import '../dashboard/barber_provider.dart';

// Local priority state — tracks which entries are flagged priority
final _priorityProvider = StateProvider<Set<String>>((ref) => {});

class BarberQueueScreen extends ConsumerWidget {
  const BarberQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final state = ref.watch(barberDashProvider);
    final priorityIds = ref.watch(_priorityProvider);

    // Sort: priority entries first, then by position
    final entries = [...state.queueEntries]..sort((a, b) {
        final aPrio = priorityIds.contains(a.id) ? 0 : 1;
        final bPrio = priorityIds.contains(b.id) ? 0 : 1;
        if (aPrio != bPrio) return aPrio - bPrio;
        return a.position - b.position;
      });

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Live Queue'),
            if (state.queueEntries.isNotEmpty) ...[
              const SizedBox(width: BBSpacing.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.bbColors.accent,
                  borderRadius: BorderRadius.circular(BBRadius.full),
                ),
                child: Text(
                  '${state.queueEntries.length}',
                  style: BBTypography.textTheme.labelSmall?.copyWith(
                    color: colors.background,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.refresh),
            onPressed: () => ref.read(barberDashProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/barber/reception'),
        backgroundColor: context.bbColors.accent,
        foregroundColor: colors.background,
        icon: const Icon(AppIcons.personAdd),
        label: const Text('Walk-in'),
      ),
      body: state.isLoading
          ? const BBSkeletonListView()
          : RefreshIndicator(
              color: colors.accent,
              onRefresh: () => ref.read(barberDashProvider.notifier).refresh(),
              child: entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppIcons.queue,
                              size: 64, color: colors.textTertiary),
                          const SizedBox(height: BBSpacing.base),
                          Text(
                            'Queue is empty',
                            style: BBTypography.textTheme.headlineSmall
                                ?.copyWith(color: colors.textSecondary),
                          ),
                          const SizedBox(height: BBSpacing.sm),
                          Text(
                            'No one is waiting right now.',
                            style: BBTypography.textTheme.bodyMedium
                                ?.copyWith(color: colors.textTertiary),
                          ),
                          const SizedBox(height: BBSpacing.xl),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/barber/reception'),
                            icon: const Icon(AppIcons.personAdd),
                            label: const Text('Add Walk-in'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.bbColors.accent,
                              foregroundColor: colors.background,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        BBSpacing.pageHorizontal,
                        BBSpacing.pageHorizontal,
                        BBSpacing.pageHorizontal,
                        100,
                      ),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: BBSpacing.sm),
                      itemBuilder: (ctx, i) {
                        final entry = entries[i];
                        final isPriority = priorityIds.contains(entry.id);
                        return _FullQueueCard(
                          entry: entry,
                          isPriority: isPriority,
                          onAction: (status) async {
                            try {
                              await ref
                                  .read(barberDashProvider.notifier)
                                  .updateEntryStatus(entry.id, status);
                              if (ctx.mounted) {
                                showBBSnackbar(ctx,
                                    message: 'Status updated',
                                    isSuccess: true);
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                showBBSnackbar(ctx,
                                    message: e.toString(), isError: true);
                              }
                            }
                          },
                          onTogglePriority: () {
                            ref.read(_priorityProvider.notifier).update((s) {
                              final next = {...s};
                              if (next.contains(entry.id)) {
                                next.remove(entry.id);
                              } else {
                                next.add(entry.id);
                              }
                              return next;
                            });
                          },
                          onSkip: () {
                            showBBSnackbar(ctx,
                                message: '${entry.customerName ?? 'Walk-in'} moved to end of queue');
                          },
                          onTransfer: () {
                            _showTransferSheet(ctx);
                          },
                        );
                      },
                    ),
            ),
    );
  }

  void _showTransferSheet(BuildContext context) {
    const barbers = ['Alex Silva', 'Sam Khan', 'Mike Patel'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(BBRadius.xxl)),
      ),
      builder: (ctx) {
        final colors = ctx.bbColors;
        return Padding(
          padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transfer to Barber',
                style: BBTypography.textTheme.titleLarge?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: BBSpacing.base),
              ...barbers.map(
                (b) => ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.bbColors.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        b[0],
                        style: BBTypography.textTheme.titleMedium?.copyWith(
                          color: context.bbColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  title: Text(b,
                      style:
                          BBTypography.textTheme.titleSmall?.copyWith(color: colors.text)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    showBBSnackbar(context,
                        message: 'Transferred to $b', isSuccess: true);
                  },
                ),
              ),
              const SizedBox(height: BBSpacing.base),
            ],
          ),
        );
      },
    );
  }
}

class _FullQueueCard extends StatelessWidget {
  const _FullQueueCard({
    required this.entry,
    required this.isPriority,
    required this.onAction,
    required this.onTogglePriority,
    required this.onSkip,
    required this.onTransfer,
  });
  final QueueEntry entry;
  final bool isPriority;
  final void Function(String) onAction;
  final VoidCallback onTogglePriority;
  final VoidCallback onSkip;
  final VoidCallback onTransfer;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(
          color: isPriority
              ? BBColors.error.withValues(alpha: 0.4)
              : entry.status == QueueStatus.inService
                  ? context.bbColors.accent.withValues(alpha: 0.5)
                  : colors.border,
          width: isPriority ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Position badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isPriority
                          ? BBColors.error.withValues(alpha: 0.12)
                          : context.bbColors.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#${entry.position}',
                        style: BBTypography.textTheme.labelLarge?.copyWith(
                          color: isPriority ? BBColors.error : context.bbColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (isPriority)
                    const Positioned(
                      top: -4,
                      right: -4,
                      child: Icon(AppIcons.flagFill,
                          size: 14, color: BBColors.error),
                    ),
                ],
              ),
              const SizedBox(width: BBSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.customerName ?? 'Walk-in',
                      style: BBTypography.textTheme.titleMedium
                          ?.copyWith(color: colors.text),
                    ),
                    if (entry.serviceNames.isNotEmpty)
                      Text(
                        entry.serviceNames,
                        style: BBTypography.textTheme.bodySmall
                            ?.copyWith(color: colors.textSecondary),
                      ),
                  ],
                ),
              ),
              // Priority toggle
              GestureDetector(
                onTap: onTogglePriority,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isPriority ? AppIcons.flagFill : AppIcons.flag,
                    size: 18,
                    color: isPriority ? BBColors.error : colors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: BBSpacing.xs),
              BBStatusChip(status: entry.status.apiValue),
            ],
          ),
          if (entry.estimatedWaitMinutes > 0 || entry.isWalkIn) ...[
            const SizedBox(height: BBSpacing.sm),
            Row(
              children: [
                if (entry.estimatedWaitMinutes > 0) ...[
                  Icon(AppIcons.timer,
                      size: 13, color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    '~${entry.estimatedWaitMinutes} min wait',
                    style: BBTypography.textTheme.labelSmall
                        ?.copyWith(color: colors.textTertiary),
                  ),
                ],
                if (entry.isWalkIn) ...[
                  const SizedBox(width: BBSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: BBColors.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(BBRadius.full),
                    ),
                    child: Text(
                      'Walk-in',
                      style: BBTypography.textTheme.labelSmall?.copyWith(
                        color: BBColors.info,
                      ),
                    ),
                  ),
                ],
                if (entry.barberName != null) ...[
                  const SizedBox(width: BBSpacing.sm),
                  Icon(AppIcons.personOutline,
                      size: 12, color: colors.textTertiary),
                  const SizedBox(width: 2),
                  Text(
                    entry.barberName!,
                    style: BBTypography.textTheme.labelSmall
                        ?.copyWith(color: colors.textTertiary),
                  ),
                ],
              ],
            ),
          ],
          if (entry.status.isActive) ...[
            const SizedBox(height: BBSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._actionsFor(entry.status).map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(right: BBSpacing.sm),
                      child: BBButton(
                        label: a.$1,
                        onPressed: () => onAction(a.$2),
                        variant: a.$3,
                        small: true,
                        expand: false,
                      ),
                    ),
                  ),
                  // Extra: Skip and Transfer for waiting entries
                  if (entry.status == QueueStatus.waiting) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: BBSpacing.sm),
                      child: BBButton(
                        label: 'Skip',
                        onPressed: onSkip,
                        variant: BBButtonVariant.secondary,
                        small: true,
                        expand: false,
                        icon: AppIcons.skipNext,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: BBSpacing.sm),
                      child: BBButton(
                        label: 'Transfer',
                        onPressed: onTransfer,
                        variant: BBButtonVariant.secondary,
                        small: true,
                        expand: false,
                        icon: AppIcons.swap,
                      ),
                    ),
                  ],
                  // Pause for in-service
                  if (entry.status == QueueStatus.inService)
                    Padding(
                      padding: const EdgeInsets.only(right: BBSpacing.sm),
                      child: BBButton(
                        label: 'Pause',
                        onPressed: () => onAction('WAITING'),
                        variant: BBButtonVariant.secondary,
                        small: true,
                        expand: false,
                        icon: AppIcons.pause,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<(String, String, BBButtonVariant)> _actionsFor(QueueStatus s) =>
      switch (s) {
        QueueStatus.waiting => [
            ('Mark Ready', 'READY', BBButtonVariant.primary),
            ('No Show', 'NO_SHOW', BBButtonVariant.destructive),
          ],
        QueueStatus.ready || QueueStatus.called => [
            ('Start Service', 'IN_SERVICE', BBButtonVariant.primary),
          ],
        QueueStatus.inService => [
            ('Complete', 'COMPLETED', BBButtonVariant.primary),
          ],
        _ => [],
      };
}
