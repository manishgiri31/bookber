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
import 'barber_provider.dart';

class BarberDashboardScreen extends ConsumerWidget {
  const BarberDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final state = ref.watch(barberDashProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: state.isLoading
          ? const BBLoadingScreen()
          : state.error != null && state.profile == null
              ? BBErrorWidget(
                  error: state.error!,
                  onRetry: () =>
                      ref.read(barberDashProvider.notifier).refresh(),
                  fullScreen: true,
                )
              : RefreshIndicator(
                  color: BBColors.amber,
                  onRefresh: () =>
                      ref.read(barberDashProvider.notifier).refresh(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _Header(state: state),
                      ),
                      if (state.stats != null) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: BBSpacing.pageHorizontal,
                            ),
                            child: _StatsRow(stats: state.stats!),
                          ),
                        ),
                        const SliverToBoxAdapter(
                            child: SizedBox(height: BBSpacing.xl)),
                      ],

                      // Quick actions
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BBSpacing.pageHorizontal,
                          ),
                          child: _QuickActions(),
                        ),
                      ),
                      const SliverToBoxAdapter(
                          child: SizedBox(height: BBSpacing.xl)),

                      // Live queue header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BBSpacing.pageHorizontal,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Live Queue',
                                style: BBTypography.textTheme.titleLarge
                                    ?.copyWith(
                                  color: colors.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: state.queueEntries
                                          .where((e) => e.status.isActive)
                                          .isNotEmpty
                                      ? BBColors.amber.withValues(alpha: 0.12)
                                      : colors.surfaceVariant,
                                  borderRadius:
                                      BorderRadius.circular(BBRadius.full),
                                ),
                                child: Text(
                                  '${state.queueEntries.where((e) => e.status.isActive).length} active',
                                  style: BBTypography.textTheme.labelSmall
                                      ?.copyWith(
                                    color: state.queueEntries
                                            .where((e) => e.status.isActive)
                                            .isNotEmpty
                                        ? BBColors.amber
                                        : colors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                          child: SizedBox(height: BBSpacing.md)),

                      state.queueEntries.isEmpty
                          ? SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: BBSpacing.pageHorizontal,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(BBSpacing.xl),
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius:
                                        BorderRadius.circular(BBRadius.lg),
                                    border:
                                        Border.all(color: colors.border),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.queue_outlined,
                                          size: 40,
                                          color: colors.textTertiary),
                                      const SizedBox(height: BBSpacing.md),
                                      Text(
                                        'Queue is empty',
                                        style: BBTypography
                                            .textTheme.titleMedium
                                            ?.copyWith(
                                                color: colors.textSecondary),
                                      ),
                                      const SizedBox(height: BBSpacing.xs),
                                      Text(
                                        'Customers will appear here when they join.',
                                        style: BBTypography
                                            .textTheme.bodySmall
                                            ?.copyWith(
                                                color: colors.textTertiary),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: BBSpacing.pageHorizontal,
                              ),
                              sliver: SliverList.separated(
                                itemCount: state.queueEntries.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: BBSpacing.sm),
                                itemBuilder: (ctx, i) => _QueueCard(
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
                                        showBBSnackbar(ctx,
                                            message: 'Status updated',
                                            isSuccess: true);
                                      }
                                    } catch (e) {
                                      if (ctx.mounted) {
                                        showBBSnackbar(ctx,
                                            message: e.toString(),
                                            isError: true);
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                      const SliverToBoxAdapter(
                          child: SizedBox(height: BBSpacing.xxl)),
                    ],
                  ),
                ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.state});
  final BarberDashState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BBSpacing.pageHorizontal,
          BBSpacing.base,
          BBSpacing.pageHorizontal,
          BBSpacing.xl,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: BBTypography.textTheme.bodyLarge?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    state.profile?.name.split(' ').first ?? 'Barber',
                    style: BBTypography.textTheme.displaySmall?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (state.profile != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.store_outlined,
                            size: 13, color: colors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          state.profile!.shopName,
                          style: BBTypography.textTheme.bodySmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: () =>
                  ref.read(barberDashProvider.notifier).toggleAvailability(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: state.profile?.isAvailable == true
                      ? BBColors.success.withValues(alpha: 0.15)
                      : colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(BBRadius.full),
                  border: Border.all(
                    color: state.profile?.isAvailable == true
                        ? BBColors.success.withValues(alpha: 0.4)
                        : colors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: state.profile?.isAvailable == true
                            ? BBColors.success
                            : colors.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.profile?.isAvailable == true
                          ? 'Available'
                          : 'Away',
                      style: BBTypography.textTheme.labelMedium?.copyWith(
                        color: state.profile?.isAvailable == true
                            ? BBColors.success
                            : colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final BarberStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_today_rounded,
            label: 'Today',
            value: '${stats.todayBookings}',
            suffix: 'bookings',
          ),
        ),
        const SizedBox(width: BBSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.queue_rounded,
            label: 'In Queue',
            value: '${stats.activeQueue}',
            suffix: 'waiting',
            highlight: stats.activeQueue > 0,
          ),
        ),
        const SizedBox(width: BBSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline_rounded,
            label: 'Done',
            value: '${stats.completedToday}',
            suffix: 'today',
            color: BBColors.success,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.suffix,
    this.highlight = false,
    this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final String suffix;
  final bool highlight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final accent = color ?? (highlight ? BBColors.amber : colors.text);
    return Container(
      padding: const EdgeInsets.all(BBSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(
          color: highlight
              ? BBColors.amber.withValues(alpha: 0.4)
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(height: BBSpacing.sm),
          Text(
            value,
            style: BBTypography.textTheme.headlineMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            suffix,
            style: BBTypography.textTheme.labelSmall?.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: BBTypography.textTheme.titleLarge?.copyWith(
            color: colors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: BBSpacing.md),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.queue_rounded,
                label: 'Manage Queue',
                color: BBColors.amber,
                onTap: () => context.go('/barber/queue'),
              ),
            ),
            const SizedBox(width: BBSpacing.sm),
            Expanded(
              child: _ActionCard(
                icon: Icons.calendar_month_rounded,
                label: 'Bookings',
                color: BBColors.info,
                onTap: () => context.go('/barber/bookings'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(BBSpacing.base),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(BBRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: BBSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: BBTypography.textTheme.labelLarge?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.entry, required this.onAction});
  final QueueEntry entry;
  final void Function(String status) onAction;

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
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: BBColors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#${entry.position}',
                    style: BBTypography.textTheme.labelMedium?.copyWith(
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
                      entry.customerName ?? 'Walk-in Customer',
                      style: BBTypography.textTheme.titleMedium?.copyWith(
                        color: colors.text,
                      ),
                    ),
                    if (entry.serviceNames.isNotEmpty)
                      Text(
                        entry.serviceNames,
                        style: BBTypography.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BBStatusChip(status: entry.status.apiValue),
                  if (entry.isWalkIn) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: BBColors.info.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(BBRadius.full),
                      ),
                      child: Text(
                        'Walk-in',
                        style: BBTypography.textTheme.labelSmall?.copyWith(
                          color: BBColors.info,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (entry.status.isActive) ...[
            const SizedBox(height: BBSpacing.md),
            Row(
              children: _actions.map(
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
          ],
        ],
      ),
    );
  }

  List<(String, String, BBButtonVariant)> get _actions =>
      switch (entry.status) {
        QueueStatus.waiting => [
            ('Ready', 'READY', BBButtonVariant.primary),
            ('No Show', 'NO_SHOW', BBButtonVariant.destructive),
          ],
        QueueStatus.ready || QueueStatus.called => [
            ('Start', 'IN_SERVICE', BBButtonVariant.primary),
          ],
        QueueStatus.inService => [
            ('Complete', 'COMPLETED', BBButtonVariant.primary),
          ],
        _ => [],
      };
}
