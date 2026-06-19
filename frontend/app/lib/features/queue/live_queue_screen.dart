import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/components/bb_button.dart';
import '../../core/components/bb_card.dart';
import '../../core/components/bb_skeleton.dart';
import '../../core/components/bb_status.dart';
import 'providers/queue_providers.dart';

// ─────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────

class LiveQueueScreen extends ConsumerStatefulWidget {
  const LiveQueueScreen({super.key, required this.shopId});

  final String shopId;

  @override
  ConsumerState<LiveQueueScreen> createState() => _LiveQueueScreenState();
}

class _LiveQueueScreenState extends ConsumerState<LiveQueueScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryOpacity;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _entryCtrl = AnimationController(vsync: this, duration: BBMotion.xslow);
    _entryOpacity = CurvedAnimation(parent: _entryCtrl, curve: BBMotion.enter);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(queuePositionProvider(widget.shopId));
    final connStatus = ref.watch(connectionStatusProvider);
    final activities = ref.watch(queueActivityProvider);

    return Scaffold(
      backgroundColor: BBColors.bgCanvas,
      body: SafeArea(
        child: Column(
          children: [
            _QueueAppBar(
              connectionStatus: connStatus,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: queueAsync.when(
                data: (position) => FadeTransition(
                  opacity: _entryOpacity,
                  child: _QueueBody(
                    position: position,
                    activities: activities,
                    shopId: widget.shopId,
                    onLeaveQueue: () => _handleLeaveQueue(context),
                  ),
                ),
                loading: () => const _QueueLoadingState(),
                error: (_, __) => _QueueErrorState(
                  onRetry: () => ref.invalidate(queuePositionProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLeaveQueue(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      backgroundColor: BBColors.bgSurface,
      shape: const RoundedRectangleBorder(borderRadius: BBRadius.sheet),
      builder: (_) => const _LeaveQueueSheet(),
    ).then((confirmed) {
      if (confirmed == true && mounted) context.pop();
    });
  }
}

// ─────────────────────────────────────────────────────────────
// APP BAR
// ─────────────────────────────────────────────────────────────

class _QueueAppBar extends StatelessWidget {
  const _QueueAppBar({required this.connectionStatus, required this.onBack});

  final ConnectionStatus connectionStatus;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BBSpacing.px8,
        BBSpacing.px8,
        BBSpacing.px20,
        BBSpacing.px8,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: BBIconSize.md,
              color: BBColors.textPrimary,
            ),
            onPressed: onBack,
          ),
          const Expanded(
            child: Text('Your Queue', style: BBTypography.headingL),
          ),
          BBConnectionStatus(
            state: _connStateToBB(connectionStatus),
          ),
        ],
      ),
    );
  }

  BBConnectionState _connStateToBB(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return BBConnectionState.connected;
      case ConnectionStatus.reconnecting:
        return BBConnectionState.reconnecting;
      case ConnectionStatus.offline:
        return BBConnectionState.disconnected;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// BODY
// ─────────────────────────────────────────────────────────────

class _QueueBody extends StatelessWidget {
  const _QueueBody({
    required this.position,
    required this.activities,
    required this.shopId,
    required this.onLeaveQueue,
  });

  final QueuePosition position;
  final List<QueueActivity> activities;
  final String shopId;
  final VoidCallback onLeaveQueue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        BBSpacing.px20,
        BBSpacing.px4,
        BBSpacing.px20,
        BBSpacing.px24,
      ),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // ── Hero card ─────────────────────────────────────
          if (position.status == QueueStatus.inService)
            _InServiceHeroCard(position: position)
          else
            _WaitingHeroCard(position: position),

          const SizedBox(height: BBSpacing.px20),

          // ── Chair assignment banner ───────────────────────
          if (position.chairNumber != null) ...[
            _ChairBanner(chairNumber: position.chairNumber!),
            const SizedBox(height: BBSpacing.px16),
          ],

          // ── Timeline ──────────────────────────────────────
          _QueueTimeline(status: position.status),

          const SizedBox(height: BBSpacing.px20),

          // ── Activity feed ─────────────────────────────────
          if (activities.isNotEmpty) ...[
            _ActivityFeed(activities: activities.take(5).toList()),
            const SizedBox(height: BBSpacing.px20),
          ],

          // ── Leave queue ───────────────────────────────────
          if (position.status != QueueStatus.inService &&
              position.status != QueueStatus.completed)
            BBButton.ghost(
              label: 'Leave Queue',
              icon: Icons.exit_to_app_rounded,
              onPressed: onLeaveQueue,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WAITING HERO CARD
// ─────────────────────────────────────────────────────────────

class _WaitingHeroCard extends StatelessWidget {
  const _WaitingHeroCard({required this.position});

  final QueuePosition position;

  @override
  Widget build(BuildContext context) {
    final isNext = position.status == QueueStatus.next;
    final isDone = position.status == QueueStatus.completed;
    final accent = isDone
        ? BBColors.success
        : isNext
            ? BBColors.warning
            : BBColors.brandPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BBSpacing.px28),
      decoration: BoxDecoration(
        color: BBColors.bgSurface,
        borderRadius: BBRadius.xxl,
        border: Border.all(
          color: isNext
              ? BBColors.warning.withValues(alpha: 0.4)
              : BBColors.borderDefault,
          width: isNext ? 1.5 : 1,
        ),
        boxShadow: isNext
            ? BBElevation.brandGlow(BBColors.warning, intensity: 0.12)
            : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BBPulse(color: accent, size: 7),
              const SizedBox(width: BBSpacing.px8),
              Text(
                isDone
                    ? 'All done!'
                    : isNext
                        ? "You're next!"
                        : 'In queue',
                style: BBTypography.labelL.copyWith(color: accent),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.px20),

          if (position.position > 0 && !isDone) ...[
            BBQueuePositionCounter(position: position.position, color: accent),
            const SizedBox(height: BBSpacing.px6),
            Text(
              'in line',
              style: BBTypography.bodyM.copyWith(color: BBColors.textDisabled),
            ),
          ] else if (isDone)
            Icon(Icons.check_circle_rounded, size: 56, color: accent),

          const SizedBox(height: BBSpacing.px24),

          if (position.estimatedWaitMinutes > 0)
            _EtaPill(minutes: position.estimatedWaitMinutes),

          if (position.totalInQueue > 0) ...[
            const SizedBox(height: BBSpacing.px16),
            _QueueProgress(
              position: position.position,
              total: position.totalInQueue,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// IN SERVICE HERO CARD
// ─────────────────────────────────────────────────────────────

class _InServiceHeroCard extends StatelessWidget {
  const _InServiceHeroCard({required this.position});

  final QueuePosition position;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BBSpacing.px28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BBColors.brandPrimary.withValues(alpha: 0.15),
            BBColors.bgSurface,
          ],
        ),
        borderRadius: BBRadius.xxl,
        border: Border.all(
          color: BBColors.brandPrimary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: BBElevation.brandGlow(BBColors.brandPrimary, intensity: 0.15),
      ),
      child: Column(
        children: [
          const BBStatusPill(type: BBStatusType.live, label: 'In Service', showPulse: true),
          const SizedBox(height: BBSpacing.px20),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: BBColors.brandPrimaryDim,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.content_cut_rounded,
              size: BBIconSize.xxl,
              color: BBColors.brandPrimary,
            ),
          ),
          const SizedBox(height: BBSpacing.px16),
          if (position.serviceName != null) ...[
            Text(position.serviceName!, style: BBTypography.headingL),
            const SizedBox(height: BBSpacing.px4),
          ],
          if (position.barberName != null)
            Text(
              'with ${position.barberName}',
              style: BBTypography.bodyM,
            ),
          if (position.estimatedCompletionTime != null) ...[
            const SizedBox(height: BBSpacing.px20),
            _CompletionTimer(completionTime: position.estimatedCompletionTime!),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ETA PILL
// ─────────────────────────────────────────────────────────────

class _EtaPill extends StatelessWidget {
  const _EtaPill({required this.minutes});
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final color = BBColors.queueColor(minutes);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpacing.px20,
        vertical: BBSpacing.px10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BBRadius.pill,
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: BBIconSize.sm, color: color),
          const SizedBox(width: BBSpacing.px8),
          Text(
            'Est. $minutes min wait',
            style: BBTypography.labelL.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// QUEUE PROGRESS BAR
// ─────────────────────────────────────────────────────────────

class _QueueProgress extends StatelessWidget {
  const _QueueProgress({required this.position, required this.total});
  final int position;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (total - position + 1) / total : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$position of $total in queue',
              style: BBTypography.labelS,
            ),
            Text(
              '${((1 - progress.clamp(0.0, 1.0)) * 100).round()}% done',
              style: BBTypography.labelS,
            ),
          ],
        ),
        const SizedBox(height: BBSpacing.px8),
        ClipRRect(
          borderRadius: BBRadius.pill,
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: BBColors.bgElevated,
            color: BBColors.brandPrimary,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CHAIR ASSIGNMENT BANNER
// ─────────────────────────────────────────────────────────────

class _ChairBanner extends StatelessWidget {
  const _ChairBanner({required this.chairNumber});
  final int chairNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BBSpacing.px16),
      decoration: BoxDecoration(
        color: BBColors.brandPrimaryDim,
        borderRadius: BBRadius.md,
        border: Border.all(
          color: BBColors.brandPrimary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BBColors.brandPrimary.withValues(alpha: 0.15),
              borderRadius: BBRadius.sm,
            ),
            child: const Icon(
              Icons.chair_outlined,
              size: BBIconSize.md,
              color: BBColors.brandPrimary,
            ),
          ),
          const SizedBox(width: BBSpacing.px12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chair Assigned',
                style: BBTypography.labelM.copyWith(
                  color: BBColors.brandPrimary,
                ),
              ),
              Text(
                'Please head to Chair #$chairNumber',
                style: BBTypography.headingS,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// QUEUE TIMELINE
// ─────────────────────────────────────────────────────────────

class _QueueTimeline extends StatelessWidget {
  const _QueueTimeline({required this.status});
  final QueueStatus status;

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(status);
    return BBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Journey', style: BBTypography.headingM),
          const SizedBox(height: BBSpacing.px16),
          ...steps.asMap().entries.map((e) => _TimelineStep(
                step: e.value,
                isLast: e.key == steps.length - 1,
              )),
        ],
      ),
    );
  }

  List<_StepData> _buildSteps(QueueStatus s) {
    final isDone = s == QueueStatus.completed;
    final isService = s == QueueStatus.inService || isDone;
    final isNext = s == QueueStatus.next || isService;
    final isWaiting = true;

    return [
      _StepData(
        icon: Icons.login_rounded,
        label: 'Joined queue',
        sub: 'Your spot is reserved',
        state: _StepState.done,
      ),
      _StepData(
        icon: Icons.people_outline_rounded,
        label: 'Waiting in line',
        sub: 'Heads up when it\'s your turn',
        state: isWaiting && !isNext
            ? _StepState.active
            : isNext
                ? _StepState.done
                : _StepState.pending,
      ),
      _StepData(
        icon: Icons.notifications_active_outlined,
        label: "You're next!",
        sub: 'Get ready — almost your turn',
        state: isNext && !isService
            ? _StepState.active
            : isService
                ? _StepState.done
                : _StepState.pending,
      ),
      _StepData(
        icon: Icons.content_cut_rounded,
        label: 'Getting serviced',
        sub: 'Sit back and enjoy',
        state: isService && !isDone
            ? _StepState.active
            : isDone
                ? _StepState.done
                : _StepState.pending,
      ),
      _StepData(
        icon: Icons.star_outline_rounded,
        label: 'All done!',
        sub: "We'd love your feedback",
        state: isDone ? _StepState.active : _StepState.pending,
      ),
    ];
  }
}

enum _StepState { done, active, pending }

class _StepData {
  const _StepData({
    required this.icon,
    required this.label,
    required this.sub,
    required this.state,
  });
  final IconData icon;
  final String label;
  final String sub;
  final _StepState state;
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.step, required this.isLast});
  final _StepData step;
  final bool isLast;

  Color get _iconColor {
    switch (step.state) {
      case _StepState.done:
        return BBColors.success;
      case _StepState.active:
        return BBColors.brandPrimary;
      case _StepState.pending:
        return BBColors.textDisabled;
    }
  }

  Color get _iconBg {
    switch (step.state) {
      case _StepState.done:
        return BBColors.successDim;
      case _StepState.active:
        return BBColors.brandPrimaryDim;
      case _StepState.pending:
        return BBColors.bgElevated;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = step.state == _StepState.pending;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _iconBg,
                  shape: BoxShape.circle,
                ),
                child: step.state == _StepState.active
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: 0.15,
                            child: BBPulse(color: _iconColor, size: 28),
                          ),
                          Icon(step.icon,
                              size: BBIconSize.sm, color: _iconColor),
                        ],
                      )
                    : Icon(step.icon, size: BBIconSize.sm, color: _iconColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: BBSpacing.px4),
                    decoration: BoxDecoration(
                      color: step.state == _StepState.done
                          ? BBColors.success.withValues(alpha: 0.3)
                          : BBColors.borderSubtle,
                      borderRadius: BBRadius.pill,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: BBSpacing.px14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : BBSpacing.px16,
                top: BBSpacing.px6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: isPending
                        ? BBTypography.headingS.copyWith(
                            color: BBColors.textDisabled,
                          )
                        : BBTypography.headingS,
                  ),
                  const SizedBox(height: BBSpacing.px2),
                  Text(step.sub, style: BBTypography.bodyS),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ACTIVITY FEED
// ─────────────────────────────────────────────────────────────

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.activities});
  final List<QueueActivity> activities;

  @override
  Widget build(BuildContext context) {
    return BBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Updates', style: BBTypography.headingM),
          const SizedBox(height: BBSpacing.px12),
          ...activities.map(_ActivityTile.new),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile(this.activity);
  final QueueActivity activity;

  Color get _dotColor {
    switch (activity.type) {
      case ActivityType.success:
        return BBColors.success;
      case ActivityType.warning:
        return BBColors.warning;
      case ActivityType.info:
        return BBColors.textDisabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final diff = DateTime.now().difference(activity.timestamp);
    final timeAgo = diff.inMinutes < 1
        ? 'just now'
        : diff.inMinutes < 60
            ? '${diff.inMinutes}m ago'
            : '${diff.inHours}h ago';

    return Padding(
      padding: const EdgeInsets.only(bottom: BBSpacing.px10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: BBSpacing.px10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.message, style: BBTypography.bodyM),
                Text(timeAgo, style: BBTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// COMPLETION TIMER
// ─────────────────────────────────────────────────────────────

class _CompletionTimer extends StatefulWidget {
  const _CompletionTimer({required this.completionTime});
  final DateTime completionTime;

  @override
  State<_CompletionTimer> createState() => _CompletionTimerState();
}

class _CompletionTimerState extends State<_CompletionTimer> {
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _update();
    _tick();
  }

  void _update() {
    final diff = widget.completionTime.difference(DateTime.now());
    _remainingSeconds = diff.inSeconds.clamp(0, 5999);
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(_update);
      if (_remainingSeconds > 0) _tick();
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    final isDone = _remainingSeconds == 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpacing.px20,
        vertical: BBSpacing.px10,
      ),
      decoration: BoxDecoration(
        color: isDone ? BBColors.successDim : BBColors.bgElevated,
        borderRadius: BBRadius.pill,
      ),
      child: Text(
        isDone
            ? 'Finishing up...'
            : '~${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} remaining',
        style: BBTypography.labelL.copyWith(
          color: isDone ? BBColors.success : BBColors.textPrimary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LEAVE QUEUE SHEET
// ─────────────────────────────────────────────────────────────

class _LeaveQueueSheet extends StatelessWidget {
  const _LeaveQueueSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        BBSpacing.px24,
        BBSpacing.px20,
        BBSpacing.px24,
        BBSpacing.px24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: BBSpacing.px20),
            decoration: BoxDecoration(
              color: BBColors.borderDefault,
              borderRadius: BBRadius.pill,
            ),
          ),
          const Text('Leave the queue?', style: BBTypography.displayS),
          const SizedBox(height: BBSpacing.px8),
          const Text(
            "You'll lose your spot and will need to rejoin from the end.",
            style: BBTypography.bodyM,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BBSpacing.px28),
          Row(
            children: [
              Expanded(
                child: BBButton.secondary(
                  label: 'Stay in queue',
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: BBSpacing.px12),
              Expanded(
                child: BBButton.danger(
                  label: 'Leave',
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LOADING / ERROR STATES
// ─────────────────────────────────────────────────────────────

class _QueueLoadingState extends StatelessWidget {
  const _QueueLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(BBSpacing.px20),
      child: Column(
        children: [
          BBSkeleton(width: double.infinity, height: 220),
          SizedBox(height: BBSpacing.px16),
          BBSkeleton(width: double.infinity, height: 160),
          SizedBox(height: BBSpacing.px16),
          BBSkeleton(width: double.infinity, height: 120),
        ],
      ),
    );
  }
}

class _QueueErrorState extends StatelessWidget {
  const _QueueErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BBSpacing.px40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: BBColors.errorDim,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: BBIconSize.xl,
              color: BBColors.error,
            ),
          ),
          const SizedBox(height: BBSpacing.px16),
          const Text('Connection Lost', style: BBTypography.headingL),
          const SizedBox(height: BBSpacing.px8),
          const Text(
            "We couldn't reach the queue. Check your connection.",
            style: BBTypography.bodyM,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BBSpacing.px24),
          BBButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
            size: BBButtonSize.medium,
          ),
        ],
      ),
    );
  }
}
