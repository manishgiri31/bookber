import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_button.dart';
import '../../../core/widgets/bb_loading.dart';
import '../../../core/widgets/bb_snackbar.dart';
import '../../../core/widgets/bb_status_chip.dart';
import '../../shared/domain/queue_models.dart';
import '../dashboard/barber_provider.dart';

class BarberQueueScreen extends ConsumerWidget {
  const BarberQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final state = ref.watch(barberDashProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Live Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(barberDashProvider.notifier).refresh(),
          ),
        ],
      ),
      body: state.isLoading
          ? const BBSkeletonListView()
          : RefreshIndicator(
              color: colors.accent,
              onRefresh: () =>
                  ref.read(barberDashProvider.notifier).refresh(),
              child: state.queueEntries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.queue_outlined,
                            size: 64,
                            color: colors.textTertiary,
                          ),
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
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
                      itemCount: state.queueEntries.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: BBSpacing.sm),
                      itemBuilder: (ctx, i) => _FullQueueCard(
                        entry: state.queueEntries[i],
                        onAction: (status) async {
                          try {
                            await ref
                                .read(barberDashProvider.notifier)
                                .updateEntryStatus(
                                  state.queueEntries[i].id,
                                  status,
                                );
                            if (ctx.mounted) {
                              showBBSnackbar(
                                ctx,
                                message: 'Status updated',
                                isSuccess: true,
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              showBBSnackbar(ctx,
                                  message: e.toString(), isError: true);
                            }
                          }
                        },
                      ),
                    ),
            ),
    );
  }
}

class _FullQueueCard extends StatelessWidget {
  const _FullQueueCard({required this.entry, required this.onAction});
  final QueueEntry entry;
  final void Function(String) onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(
          color: entry.status == QueueStatus.inService
              ? BBColors.amber.withValues(alpha: 0.5)
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BBColors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#${entry.position}',
                    style: BBTypography.textTheme.labelLarge?.copyWith(
                      color: BBColors.amber,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
              BBStatusChip(status: entry.status.apiValue),
            ],
          ),
          if (entry.estimatedWaitMinutes > 0) ...[
            const SizedBox(height: BBSpacing.sm),
            Row(
              children: [
                Icon(Icons.timer_outlined,
                    size: 13, color: colors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '~${entry.estimatedWaitMinutes} min wait',
                  style: BBTypography.textTheme.labelSmall
                      ?.copyWith(color: colors.textTertiary),
                ),
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
              ],
            ),
          ],
          if (entry.status.isActive) ...[
            const SizedBox(height: BBSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _actionsFor(entry.status).map(
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
                ).toList(),
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
