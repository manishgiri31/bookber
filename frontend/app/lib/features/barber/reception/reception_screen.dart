import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/bb_button.dart';
import '../../../core/widgets/bb_snackbar.dart';
import '../../../core/widgets/bb_text_field.dart';
import '../../shared/domain/shop_models.dart';
import '../dashboard/barber_provider.dart';

// ─────────────── Providers ───────────────

final _receptionQueueProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.get<Map<String, dynamic>>(ApiEndpoints.receptionQueue);
  return (data['queue'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
});

final _receptionScheduledProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.get<Map<String, dynamic>>(ApiEndpoints.receptionScheduled);
  return (data['bookings'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
});

// ─────────────── Screen ───────────────

class ReceptionScreen extends ConsumerStatefulWidget {
  const ReceptionScreen({super.key});

  @override
  ConsumerState<ReceptionScreen> createState() => _ReceptionScreenState();
}

class _ReceptionScreenState extends ConsumerState<ReceptionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Reception'),
        backgroundColor: colors.background,
        bottom: TabBar(
          controller: _tab,
          labelColor: colors.text,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: context.bbColors.accent,
          tabs: const [
            Tab(text: 'Walk-In'),
            Tab(text: 'Queue'),
            Tab(text: 'Scheduled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _WalkInTab(),
          _QueueTab(),
          _ScheduledTab(),
        ],
      ),
    );
  }
}

// ── Walk-In Tab ───────────────────────────────────────────────────────────────

class _WalkInTab extends ConsumerStatefulWidget {
  const _WalkInTab();

  @override
  ConsumerState<_WalkInTab> createState() => _WalkInTabState();
}

class _WalkInTabState extends ConsumerState<_WalkInTab> {
  final _nameCtrl = TextEditingController();
  ServiceItem? _selectedService;
  bool _adding = false;
  List<ServiceItem> _services = [];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final dash = ref.read(barberDashProvider);
      if (dash.profile == null) return;
      final api = ref.read(apiClientProvider);
      final data = await api.get<Map<String, dynamic>>(
        ApiEndpoints.shopServices(dash.profile!.shopId),
      );
      final list = (data['services'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ServiceItem.fromJson)
          .toList();
      if (mounted) setState(() => _services = list);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: BBSpacing.base),
          Container(
            padding: const EdgeInsets.all(BBSpacing.base),
            decoration: BoxDecoration(
              color: context.bbColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(BBRadius.lg),
              border: Border.all(color: context.bbColors.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(AppIcons.personAdd, color: context.bbColors.accent, size: 24),
                const SizedBox(width: BBSpacing.md),
                Expanded(
                  child: Text(
                    'Add a walk-in customer directly to the queue',
                    style: BBTypography.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BBSpacing.xl),
          BBTextField(
            label: 'Customer Name',
            hint: 'e.g. Rahul Kumar',
            controller: _nameCtrl,
            prefixIcon: AppIcons.personOutline,
          ),
          const SizedBox(height: BBSpacing.md),
          Text(
            'SERVICE',
            style: BBTypography.textTheme.labelSmall?.copyWith(
              color: colors.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: BBSpacing.sm),
          Wrap(
            spacing: BBSpacing.sm,
            runSpacing: BBSpacing.sm,
            children: _services
                .map((s) => GestureDetector(
                      onTap: () => setState(() => _selectedService = s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedService == s
                              ? context.bbColors.accent
                              : colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(BBRadius.full),
                          border: Border.all(
                            color: _selectedService == s
                                ? context.bbColors.accent
                                : colors.border,
                          ),
                        ),
                        child: Text(
                          s.name,
                          style: BBTypography.textTheme.labelMedium?.copyWith(
                            color: _selectedService == s
                                ? colors.background
                                : colors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: BBSpacing.xl),
          BBButton(
            label: 'Add to Queue',
            icon: AppIcons.queue,
            loading: _adding,
            onPressed: _selectedService == null || _nameCtrl.text.isEmpty
                ? null
                : _addToQueue,
          ),
        ],
      ),
    );
  }

  Future<void> _addToQueue() async {
    if (_nameCtrl.text.isEmpty || _selectedService == null) return;
    setState(() => _adding = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<void>(
        ApiEndpoints.receptionWalkIn,
        body: {
          'serviceId': _selectedService!.id,
          'customerName': _nameCtrl.text.trim(),
        },
      );
      if (mounted) {
        _nameCtrl.clear();
        setState(() => _selectedService = null);
        showBBSnackbar(context,
            message: 'Walk-in added to queue!', isSuccess: true);
        ref.invalidate(_receptionQueueProvider);
      }
    } catch (e) {
      if (mounted) showBBSnackbar(context, message: e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }
}

// ── Queue Tab ─────────────────────────────────────────────────────────────────

class _QueueTab extends ConsumerWidget {
  const _QueueTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final async = ref.watch(_receptionQueueProvider);

    return async.when(
      loading: () => Center(
          child: CircularProgressIndicator(color: context.bbColors.accent)),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 48, color: colors.textTertiary),
            const SizedBox(height: BBSpacing.md),
            Text(e.toString(),
                style: BBTypography.textTheme.bodyMedium
                    ?.copyWith(color: colors.textSecondary)),
            const SizedBox(height: BBSpacing.base),
            TextButton(
              onPressed: () => ref.invalidate(_receptionQueueProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (queue) => queue.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.queue, size: 48, color: colors.textTertiary),
                  const SizedBox(height: BBSpacing.md),
                  Text(
                    'Queue is empty',
                    style: BBTypography.textTheme.titleMedium
                        ?.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: context.bbColors.accent,
              onRefresh: () async => ref.invalidate(_receptionQueueProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
                itemCount: queue.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: BBSpacing.sm),
                itemBuilder: (ctx, i) => _QueueEntryCard(
                  entry: queue[i],
                  onCheckIn: () async {
                    try {
                      final api = ref.read(apiClientProvider);
                      final bookingId =
                          (queue[i]['bookingId'] ?? queue[i]['booking']?['id'])
                              ?.toString() ??
                              '';
                      await api.post<void>(
                        ApiEndpoints.receptionCheckIn,
                        body: {'bookingId': bookingId},
                      );
                      if (ctx.mounted) {
                        showBBSnackbar(ctx,
                            message: 'Customer checked in!', isSuccess: true);
                        ref.invalidate(_receptionQueueProvider);
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

class _QueueEntryCard extends StatelessWidget {
  const _QueueEntryCard({required this.entry, required this.onCheckIn});
  final Map<String, dynamic> entry;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final booking = entry['booking'] as Map<String, dynamic>? ?? {};
    final user = booking['user'] as Map<String, dynamic>? ?? {};
    final service = booking['service'] as Map<String, dynamic>? ?? {};
    final status = (entry['queueStatus']?.toString() ?? '').toUpperCase();
    final position = entry['position'] ?? 0;
    final name = user['fullName']?.toString() ?? 'Walk-in Customer';
    final serviceName = service['name']?.toString() ?? '';
    final canCheckIn = status == 'WAITING';

    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(
          color: status == 'IN_SERVICE'
              ? context.bbColors.accent.withValues(alpha: 0.5)
              : colors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.bbColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$position',
                style: BBTypography.textTheme.labelMedium?.copyWith(
                  color: context.bbColors.accent,
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
                  name,
                  style: BBTypography.textTheme.titleSmall?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (serviceName.isNotEmpty)
                  Text(
                    serviceName,
                    style: BBTypography.textTheme.bodySmall
                        ?.copyWith(color: colors.textSecondary),
                  ),
              ],
            ),
          ),
          _StatusBadge(status: status),
          if (canCheckIn) ...[
            const SizedBox(width: BBSpacing.sm),
            TextButton(
              onPressed: onCheckIn,
              child: Text('Check In',
                  style: TextStyle(color: context.bbColors.accent)),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'WAITING' => (BBColors.info, 'Waiting'),
      'READY' => (context.bbColors.accent, 'Ready'),
      'CALLED' => (context.bbColors.accent, 'Called'),
      'IN_SERVICE' => (BBColors.success, 'In Service'),
      _ => (context.bbColors.textTertiary, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BBRadius.full),
      ),
      child: Text(
        label,
        style: BBTypography.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Scheduled Tab ─────────────────────────────────────────────────────────────

class _ScheduledTab extends ConsumerWidget {
  const _ScheduledTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final async = ref.watch(_receptionScheduledProvider);

    return async.when(
      loading: () => Center(
          child: CircularProgressIndicator(color: context.bbColors.accent)),
      error: (e, _) => Center(
        child: Text(e.toString(),
            style: BBTypography.textTheme.bodyMedium
                ?.copyWith(color: colors.textSecondary)),
      ),
      data: (bookings) => bookings.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.calendar, size: 48, color: colors.textTertiary),
                  const SizedBox(height: BBSpacing.md),
                  Text(
                    'No scheduled bookings today',
                    style: BBTypography.textTheme.titleMedium
                        ?.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: context.bbColors.accent,
              onRefresh: () async =>
                  ref.invalidate(_receptionScheduledProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
                itemCount: bookings.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: BBSpacing.sm),
                itemBuilder: (_, i) =>
                    _ScheduledBookingCard(booking: bookings[i]),
              ),
            ),
    );
  }
}

class _ScheduledBookingCard extends StatelessWidget {
  const _ScheduledBookingCard({required this.booking});
  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final user = booking['user'] as Map<String, dynamic>? ?? {};
    final service = booking['service'] as Map<String, dynamic>? ?? {};
    final barber = booking['barber'] as Map<String, dynamic>?;
    final barberUser = barber?['user'] as Map<String, dynamic>?;
    final name = user['fullName']?.toString() ?? 'Customer';
    final phone = user['phoneNumber']?.toString();
    final serviceName = service['name']?.toString() ?? '';
    final barberName = barberUser?['fullName']?.toString();
    final scheduledStart = booking['scheduledStart']?.toString();
    final status = booking['status']?.toString() ?? '';
    final isScheduled = status == 'SCHEDULED';

    String timeStr = '—';
    if (scheduledStart != null) {
      try {
        final dt = DateTime.parse(scheduledStart).toLocal();
        final h = dt.hour;
        final m = dt.minute.toString().padLeft(2, '0');
        final period = h >= 12 ? 'PM' : 'AM';
        final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
        timeStr = '$dh:$m $period';
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(
          color: isScheduled
              ? context.bbColors.accent.withValues(alpha: 0.3)
              : colors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isScheduled
                  ? context.bbColors.accent.withValues(alpha: 0.10)
                  : colors.surfaceVariant,
              borderRadius: BorderRadius.circular(BBRadius.md),
            ),
            child: Center(
              child: Text(
                timeStr,
                textAlign: TextAlign.center,
                style: BBTypography.textTheme.labelSmall?.copyWith(
                  color: isScheduled ? context.bbColors.accent : colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
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
                  name,
                  style: BBTypography.textTheme.titleSmall?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  [
                    serviceName,
                    ?barberName,
                  ].join(' · '),
                  style: BBTypography.textTheme.bodySmall
                      ?.copyWith(color: colors.textSecondary),
                ),
                if (phone != null)
                  Text(
                    phone,
                    style: BBTypography.textTheme.labelSmall
                        ?.copyWith(color: colors.textTertiary),
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isScheduled ? context.bbColors.accent : BBColors.info)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(BBRadius.full),
            ),
            child: Text(
              isScheduled ? 'Scheduled' : 'Queued',
              style: BBTypography.textTheme.labelSmall?.copyWith(
                color: isScheduled ? context.bbColors.accent : BBColors.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
