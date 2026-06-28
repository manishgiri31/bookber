import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_loading.dart';
import '../queue/queue_provider.dart';

class SmartArrivalScreen extends ConsumerStatefulWidget {
  const SmartArrivalScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<SmartArrivalScreen> createState() => _SmartArrivalScreenState();
}

class _SmartArrivalScreenState extends ConsumerState<SmartArrivalScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _refreshTimer;

  // Simulated travel time (in a real app, use Directions API)
  int _travelMinutes = 12;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) ref.read(myQueueProvider(widget.bookingId).notifier).refresh();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final queueState = ref.watch(myQueueProvider(widget.bookingId));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Smart Arrival'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(myQueueProvider(widget.bookingId).notifier).refresh(),
          ),
        ],
      ),
      body: queueState.isLoading && queueState.myPosition == null
          ? const BBSkeletonListView(itemCount: 4, padding: EdgeInsets.all(20))
          : queueState.myPosition == null
              ? _NoPosView(onGoBack: () => context.pop())
              : _ArrivalView(
                  position: queueState.myPosition!,
                  travelMinutes: _travelMinutes,
                  onChangeTravelTime: (v) => setState(() => _travelMinutes = v),
                  pulse: _pulse,
                ),
    );
  }
}

class _ArrivalView extends StatelessWidget {
  const _ArrivalView({
    required this.position,
    required this.travelMinutes,
    required this.onChangeTravelTime,
    required this.pulse,
  });
  final dynamic position;
  final int travelMinutes;
  final ValueChanged<int> onChangeTravelTime;
  final AnimationController pulse;

  int get _queueWait => (position.estimatedWaitMinutes as int?) ?? 0;
  int get _leaveIn => (_queueWait - travelMinutes).clamp(0, 999);
  int get _serviceDuration => 30; // default; real app uses selected service
  DateTime get _expectedChairTime =>
      DateTime.now().add(Duration(minutes: _queueWait));
  DateTime get _expectedFinishTime =>
      _expectedChairTime.add(Duration(minutes: _serviceDuration));

  double get _confidence {
    if (_queueWait == 0) return 1.0;
    final deviation = (travelMinutes / _queueWait).clamp(0.0, 1.0);
    return ((1.0 - deviation * 0.6) * 100).clamp(20.0, 98.0) / 100;
  }

  String _fmt(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final conf = _confidence;
    final confColor = conf > 0.75
        ? BBColors.success
        : conf > 0.5
            ? const Color(0xFFF59E0B)
            : BBColors.error;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      child: Column(
        children: [
          // ── Departure countdown ─────────────────────────────────────────
          AnimatedBuilder(
            animation: pulse,
            builder: (_, child) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(BBSpacing.xl),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(BBRadius.xl),
                border: Border.all(
                  color: _leaveIn < 5
                      ? BBColors.error.withValues(alpha: 0.4 + pulse.value * 0.3)
                      : colors.border,
                ),
              ),
              child: child,
            ),
            child: Column(
              children: [
                Text(
                  _leaveIn == 0 ? 'Leave Now!' : 'Leave in',
                  style: BBTypography.textTheme.bodyLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: BBSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$_leaveIn',
                      style: BBTypography.textTheme.displayLarge?.copyWith(
                        color: _leaveIn < 5 ? BBColors.error : colors.text,
                        fontSize: 72,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 6),
                      child: Text(
                        'min',
                        style: BBTypography.textTheme.titleLarge?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BBSpacing.sm),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: confColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(BBRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speed_rounded, size: 14, color: confColor),
                      const SizedBox(width: 5),
                      Text(
                        '${(conf * 100).round()}% confidence',
                        style: BBTypography.textTheme.labelMedium?.copyWith(
                          color: confColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BBSpacing.base),

          // ── Timeline grid ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _TimelineCard(
                  icon: Icons.directions_walk_rounded,
                  label: 'Travel',
                  value: '${travelMinutes}m',
                  color: BBColors.info,
                ),
              ),
              const SizedBox(width: BBSpacing.sm),
              Expanded(
                child: _TimelineCard(
                  icon: Icons.queue_rounded,
                  label: 'Queue Wait',
                  value: _queueWait > 0 ? '~${_queueWait}m' : 'Ready',
                  color: BBColors.amber,
                ),
              ),
              const SizedBox(width: BBSpacing.sm),
              Expanded(
                child: _TimelineCard(
                  icon: Icons.content_cut_rounded,
                  label: 'Service',
                  value: '~${_serviceDuration}m',
                  color: BBColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.base),

          // ── Expected times ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(BBSpacing.base),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(BBRadius.lg),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXPECTED TIMES',
                  style: BBTypography.textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: BBSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _ExpectedRow(
                        icon: Icons.chair_rounded,
                        label: 'Chair Time',
                        time: _fmt(_expectedChairTime),
                      ),
                    ),
                    Container(
                        width: 1, height: 40, color: colors.border),
                    Expanded(
                      child: _ExpectedRow(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Finish Time',
                        time: _fmt(_expectedFinishTime),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: BBSpacing.base),

          // ── Travel time adjuster ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(BBSpacing.base),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(BBRadius.lg),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADJUST TRAVEL TIME',
                  style: BBTypography.textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: BBSpacing.sm),
                Text(
                  '$travelMinutes minutes to shop',
                  style: BBTypography.textTheme.bodyMedium
                      ?.copyWith(color: colors.text),
                ),
                Slider(
                  value: travelMinutes.toDouble(),
                  min: 1,
                  max: 60,
                  divisions: 59,
                  activeColor: BBColors.amber,
                  inactiveColor: colors.border,
                  onChanged: (v) => onChangeTravelTime(v.round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1m',
                        style: BBTypography.textTheme.labelSmall
                            ?.copyWith(color: colors.textTertiary)),
                    Text('60m',
                        style: BBTypography.textTheme.labelSmall
                            ?.copyWith(color: colors.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: BBSpacing.base),

          // ── Queue info ──────────────────────────────────────────────────
          if (position.barberName != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(BBSpacing.base),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(BBRadius.lg),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: BBColors.amber.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.person_rounded,
                          color: BBColors.amber, size: 22),
                    ),
                  ),
                  const SizedBox(width: BBSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          position.barberName!,
                          style: BBTypography.textTheme.titleMedium?.copyWith(
                            color: colors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Your barber',
                          style: BBTypography.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '#${position.position}',
                    style: BBTypography.textTheme.headlineSmall?.copyWith(
                      color: BBColors.amber,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: BBSpacing.xl),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: BBTypography.textTheme.titleMedium?.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: BBTypography.textTheme.labelSmall?.copyWith(
              color: colors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ExpectedRow extends StatelessWidget {
  const _ExpectedRow({
    required this.icon,
    required this.label,
    required this.time,
  });
  final IconData icon;
  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Column(
      children: [
        Icon(icon, size: 18, color: colors.textSecondary),
        const SizedBox(height: 4),
        Text(
          time,
          style: BBTypography.textTheme.titleMedium?.copyWith(
            color: colors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: BBTypography.textTheme.labelSmall?.copyWith(
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _NoPosView extends StatelessWidget {
  const _NoPosView({required this.onGoBack});
  final VoidCallback onGoBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BBSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.near_me_disabled_rounded,
                size: 64, color: colors.textTertiary),
            const SizedBox(height: BBSpacing.base),
            Text(
              'No active queue position',
              style: BBTypography.textTheme.headlineSmall
                  ?.copyWith(color: colors.text),
            ),
            const SizedBox(height: BBSpacing.sm),
            Text(
              'Join a queue to see your smart arrival time.',
              style: BBTypography.textTheme.bodyMedium
                  ?.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BBSpacing.xl),
            TextButton(
              onPressed: onGoBack,
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
