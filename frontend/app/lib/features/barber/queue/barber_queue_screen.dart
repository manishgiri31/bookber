import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../../../core/models/bookber_models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/network/api_result.dart';
import '../providers/barber_providers.dart';
import '../../barber_dashboard/presentation/barber_dashboard_controller.dart';

class BarberQueueScreen extends ConsumerStatefulWidget {
  const BarberQueueScreen({super.key});

  @override
  ConsumerState<BarberQueueScreen> createState() => _BarberQueueScreenState();
}

class _BarberQueueScreenState extends ConsumerState<BarberQueueScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final queueAsync = ref.watch(barberQueueProvider);
    final chairsAsync = ref.watch(chairStatusProvider);

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      floatingActionButton: FloatingActionButton(
        backgroundColor: BBColors.brandPrimary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddWalkInSheet(context),
        child: const Icon(Icons.person_add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  BBSpacing.px20, BBSpacing.px20, BBSpacing.px20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Live Queue',
                    style: BBTypography.displayS.copyWith(color: colors.textPrimary),
                  ),
                  Row(
                    children: [
                      const _RotatingIcon(),
                      const SizedBox(width: BBSpacing.px8),
                      queueAsync.when(
                        data: (queue) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: BBSpacing.px12, vertical: BBSpacing.px6),
                          decoration: BoxDecoration(
                            color: BBColors.brandPrimaryDim,
                            borderRadius: BBRadius.pill,
                          ),
                          child: Text(
                            '${queue.length}',
                            style: BBTypography.labelM.copyWith(
                                color: BBColors.brandPrimary),
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: BBSpacing.px20),

            // Chair status row
            chairsAsync.when(
              data: (chairs) => _ChairStatusRow(chairs: chairs),
              loading: () => const _ChairStatusLoading(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: BBSpacing.px16),

            // Queue list
            Expanded(
              child: queueAsync.when(
                data: (queue) {
                  if (queue.isEmpty) return const _EmptyQueueState();
                  return _QueueList(queue: queue);
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: BBColors.brandPrimary),
                ),
                error: (_, __) => Center(
                  child: Text('Error loading queue',
                      style: BBTypography.bodyM
                          .copyWith(color: context.bbColors.textSecondary)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWalkInSheet(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final servicesCtrl = TextEditingController();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        final colors = context.bbColors;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: BBSpacing.px24,
            right: BBSpacing.px24,
            top: BBSpacing.px8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: colors.border, borderRadius: BBRadius.pill)),
              const SizedBox(height: BBSpacing.px16),
              Text('Add Walk-in',
                  style: BBTypography.headingL.copyWith(color: colors.textPrimary)),
              const SizedBox(height: BBSpacing.px16),
              TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Customer name (optional)')),
              const SizedBox(height: BBSpacing.px12),
              TextField(
                  controller: servicesCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Service IDs (comma separated)')),
              const SizedBox(height: BBSpacing.px20),
              SizedBox(
                width: double.infinity,
                height: BBTouchTarget.button,
                child: ElevatedButton(
                  onPressed: () {
                    final services = servicesCtrl.text
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                    Navigator.of(context)
                        .pop({'name': nameCtrl.text.trim(), 'services': services});
                  },
                  child: const Text('Add Walk-in'),
                ),
              ),
              const SizedBox(height: BBSpacing.px24),
            ],
          ),
        );
      },
    );

    if (result != null && mounted) {
      final user = ref.read(currentUserProvider);
      final shopId = user?.id ?? '';
      try {
        final res = await ref
            .read(barberDashboardControllerProvider.notifier)
            .addWalkIn(
              shopId,
              List<String>.from(result['services'] ?? []),
              result['name']?.toString(),
            );
        if (res is ApiSuccess<void>) {
          ref.invalidate(barberQueueProvider);
          ref.invalidate(barberStatsProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed to add walk-in: $e')));
        }
      }
    }
  }
}

class _RotatingIcon extends StatefulWidget {
  const _RotatingIcon();

  @override
  State<_RotatingIcon> createState() => _RotatingIconState();
}

class _RotatingIconState extends State<_RotatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(seconds: 2), vsync: this)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Transform.rotate(
        angle: _controller.value * 6.28318,
        child: child,
      ),
      child: const Icon(Icons.refresh, size: 20, color: BBColors.brandPrimary),
    );
  }
}

class _ChairStatusRow extends ConsumerWidget {
  const _ChairStatusRow({required this.chairs});
  final List<ChairStatus> chairs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(barberQueueProvider).valueOrNull ?? [];

    QueueEntry? _entryForChair(int chairNumber) {
      try {
        return queue.firstWhere((e) => e.chairNumber == chairNumber);
      } catch (_) {
        return null;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
      child: Row(
        children: chairs.map((chair) {
          final entry = _entryForChair(chair.chairNumber);
          return Padding(
            padding: const EdgeInsets.only(right: BBSpacing.px12),
            child: _ChairCard(
              chair: chair,
              onStart: entry == null
                  ? null
                  : () async {
                      await ref
                          .read(barberDashboardControllerProvider.notifier)
                          .updateQueueEntryStatus(entry.id, 'IN_SERVICE');
                      ref.invalidate(barberQueueProvider);
                    },
              onDone: entry == null
                  ? null
                  : () async {
                      await ref
                          .read(barberDashboardControllerProvider.notifier)
                          .updateQueueEntryStatus(entry.id, 'COMPLETED');
                      ref.invalidate(barberQueueProvider);
                    },
              onHold: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chair placed on hold')),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChairStatusLoading extends StatelessWidget {
  const _ChairStatusLoading();

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
      child: Row(
        children: List.generate(3, (_) {
          return Padding(
            padding: const EdgeInsets.only(right: BBSpacing.px12),
            child: Container(
              width: 140,
              height: 120,
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BBRadius.md,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ChairCard extends StatelessWidget {
  const _ChairCard({
    required this.chair,
    this.onStart,
    this.onDone,
    this.onHold,
  });
  final ChairStatus chair;
  final VoidCallback? onStart;
  final VoidCallback? onDone;
  final VoidCallback? onHold;

  static Color _ringColor(ChairStatusType status) => switch (status) {
        ChairStatusType.available => BBColors.success,
        ChairStatusType.inService => BBColors.warning,
        ChairStatusType.onBreak => BBColors.error,
        ChairStatusType.reserved => BBColors.brandPrimary,
      };

  static String _label(ChairStatusType status) => switch (status) {
        ChairStatusType.available => 'Available',
        ChairStatusType.inService => 'In Service',
        ChairStatusType.onBreak => 'On Break',
        ChairStatusType.reserved => 'Reserved',
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final ringColor = _ringColor(chair.status);
    final statusText = _label(chair.status);

    return Container(
      width: 140,
      padding: const EdgeInsets.all(BBSpacing.px16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BBRadius.md,
        border: Border.all(color: ringColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Chair ${chair.chairNumber}',
                  style: BBTypography.headingS.copyWith(color: colors.textPrimary)),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: ringColor, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.px12),
          if (chair.customerName != null) ...[
            Text(chair.customerName!,
                style: BBTypography.labelM.copyWith(color: colors.textPrimary)),
            const SizedBox(height: BBSpacing.px4),
            Text(chair.service ?? '',
                style: BBTypography.bodyS.copyWith(color: colors.textSecondary)),
            const SizedBox(height: BBSpacing.px8),
            Text(
              chair.timeRemaining == null ? '' : '${chair.timeRemaining} min',
              style: BBTypography.labelS.copyWith(color: ringColor),
            ),
          ] else
            Text(statusText,
                style: BBTypography.labelS.copyWith(color: ringColor)),
          const SizedBox(height: BBSpacing.px12),
          if (chair.status == ChairStatusType.available)
            SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                ),
                child: Text('Start',
                    style: BBTypography.labelS.copyWith(color: Colors.white)),
              ),
            )
          else if (chair.status == ChairStatusType.inService)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: onDone,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                      ),
                      child: Text('Done',
                          style: BBTypography.labelS.copyWith(color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(width: BBSpacing.px6),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: onHold,
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        side: BorderSide(color: colors.border),
                      ),
                      child: Text('Hold',
                          style:
                              BBTypography.labelS.copyWith(color: colors.textPrimary)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _QueueList extends StatelessWidget {
  const _QueueList({required this.queue});
  final List<QueueEntry> queue;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
      itemCount: queue.length,
      itemBuilder: (context, index) =>
          _QueueEntryTile(entry: queue[index]),
    );
  }
}

class _QueueEntryTile extends ConsumerWidget {
  const _QueueEntryTile({required this.entry});
  final QueueEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    return Container(
      margin: const EdgeInsets.only(bottom: BBSpacing.px12),
      padding: const EdgeInsets.all(BBSpacing.px16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BBRadius.md,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          // Position
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BBColors.brandPrimaryDim,
              borderRadius: BBRadius.md,
            ),
            child: Center(
              child: Text(
                '${entry.position}',
                style:
                    BBTypography.displayS.copyWith(color: BBColors.brandPrimary),
              ),
            ),
          ),
          const SizedBox(width: BBSpacing.px16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.customerName ?? 'Customer',
                      style: BBTypography.headingS.copyWith(color: colors.textPrimary),
                    ),
                    const SizedBox(width: BBSpacing.px8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: BBSpacing.px8, vertical: BBSpacing.px2),
                      decoration: BoxDecoration(
                        color: entry.isWalkIn
                            ? BBColors.warningDim
                            : BBColors.brandPrimaryDim,
                        borderRadius: BBRadius.pill,
                      ),
                      child: Text(
                        entry.isWalkIn ? 'Walk-in' : 'Booked',
                        style: BBTypography.caption.copyWith(
                          color: entry.isWalkIn
                              ? BBColors.warning
                              : BBColors.brandPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BBSpacing.px4),
                Text(entry.service,
                    style: BBTypography.bodyS.copyWith(color: colors.textSecondary)),
                const SizedBox(height: BBSpacing.px2),
                Text('Wait: ${entry.waitTime}',
                    style: BBTypography.bodyS.copyWith(color: colors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: BBSpacing.px12),
          Column(
            children: [
              if (entry.status == QueueStatus.waiting)
                SizedBox(
                  width: 88,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final res = await ref
                            .read(barberDashboardControllerProvider.notifier)
                            .updateQueueEntryStatus(entry.bookingId, 'in_service');
                        if (res is ApiSuccess<void>) {
                          ref.invalidate(barberQueueProvider);
                          ref.invalidate(barberStatsProvider);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e')));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(88, 36), padding: EdgeInsets.zero),
                    child: const Text('Start'),
                  ),
                )
              else if (entry.status == QueueStatus.inService)
                SizedBox(
                  width: 88,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final res = await ref
                            .read(barberDashboardControllerProvider.notifier)
                            .updateQueueEntryStatus(entry.bookingId, 'completed');
                        if (res is ApiSuccess<void>) {
                          ref.invalidate(barberQueueProvider);
                          ref.invalidate(barberStatsProvider);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e')));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(88, 36), padding: EdgeInsets.zero),
                    child: const Text('Done'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyQueueState extends StatelessWidget {
  const _EmptyQueueState();

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.bgElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.content_cut, size: 40, color: colors.textDisabled),
          ),
          const SizedBox(height: BBSpacing.px16),
          Text('Queue is empty',
              style: BBTypography.headingM.copyWith(color: colors.textPrimary)),
          const SizedBox(height: BBSpacing.px8),
          Text('No customers waiting right now',
              style: BBTypography.bodyM.copyWith(color: colors.textSecondary)),
        ],
      ),
    );
  }
}
