import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tokens.dart';
import '../../../core/components/bb_status.dart';
import '../providers/queue_providers.dart';

// ─────────────────────────────────────────────────────────────
// POSITION CARD — embeddable live queue position widget
// ─────────────────────────────────────────────────────────────

class PositionCard extends ConsumerWidget {
  const PositionCard({super.key, required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queuePositionAsync = ref.watch(queuePositionProvider(shopId));

    return queuePositionAsync.when(
      data: (position) {
        if (position.status == QueueStatus.inService) {
          return _InServiceCard(position: position);
        }
        if (position.status == QueueStatus.completed) {
          return const _CompletedCard();
        }
        return _WaitingCard(position: position);
      },
      loading: () => const _LoadingCard(),
      error: (_, __) => const _ErrorCard(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WAITING CARD
// ─────────────────────────────────────────────────────────────

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.position});
  final QueuePosition position;

  @override
  Widget build(BuildContext context) {
    final isNext = position.status == QueueStatus.next;
    final accent = isNext ? BBColors.warning : BBColors.brandPrimary;

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
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            isNext ? "You're next!" : 'Your Position',
            style: BBTypography.labelL.copyWith(color: BBColors.textSecondary),
          ),
          const SizedBox(height: BBSpacing.px16),
          BBQueuePositionCounter(position: position.position, color: accent),
          const SizedBox(height: BBSpacing.px6),
          Text(
            'in queue',
            style: BBTypography.bodyM.copyWith(color: BBColors.textDisabled),
          ),
          const SizedBox(height: BBSpacing.px20),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: BBSpacing.px20,
              vertical: BBSpacing.px10,
            ),
            decoration: BoxDecoration(
              color: BBColors.bgElevated,
              borderRadius: BBRadius.pill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: BBIconSize.sm,
                  color: BBColors.textSecondary,
                ),
                const SizedBox(width: BBSpacing.px8),
                _AnimatedWaitTime(minutes: position.estimatedWaitMinutes),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// IN SERVICE CARD
// ─────────────────────────────────────────────────────────────

class _InServiceCard extends StatelessWidget {
  const _InServiceCard({required this.position});
  final QueuePosition position;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BBSpacing.px28),
      decoration: BoxDecoration(
        color: BBColors.bgSurface,
        borderRadius: BBRadius.xxl,
        border: Border.all(
          color: BBColors.brandPrimary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: BBElevation.brandGlow(BBColors.brandPrimary, intensity: 0.12),
      ),
      child: Column(
        children: [
          const BBStatusPill(type: BBStatusType.live, label: 'In Service', showPulse: true),
          const SizedBox(height: BBSpacing.px20),
          Container(
            width: 64,
            height: 64,
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
          if (position.serviceName != null)
            Text(position.serviceName!, style: BBTypography.headingL),
          if (position.barberName != null) ...[
            const SizedBox(height: BBSpacing.px4),
            Text('with ${position.barberName}', style: BBTypography.bodyM),
          ],
        ],
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  const _CompletedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BBSpacing.px28),
      decoration: BoxDecoration(
        color: BBColors.successDim,
        borderRadius: BBRadius.xxl,
        border: Border.all(
          color: BBColors.success.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_rounded, size: 56, color: BBColors.success),
          SizedBox(height: BBSpacing.px12),
          Text('All done!', style: BBTypography.headingL),
          SizedBox(height: BBSpacing.px4),
          Text('Hope you loved the experience', style: BBTypography.bodyM),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: BBColors.bgSurface,
        borderRadius: BBRadius.xxl,
        border: Border.all(color: BBColors.borderDefault, width: 1),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: BBColors.brandPrimary,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BBSpacing.px28),
      decoration: BoxDecoration(
        color: BBColors.bgSurface,
        borderRadius: BBRadius.xxl,
        border: Border.all(color: BBColors.borderDefault, width: 1),
      ),
      child: const Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: BBColors.error),
          SizedBox(height: BBSpacing.px12),
          Text('Connection Error', style: BBTypography.headingM),
          SizedBox(height: BBSpacing.px6),
          Text(
            'Unable to connect to the queue',
            style: BBTypography.bodyM,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ANIMATED WAIT TIME
// ─────────────────────────────────────────────────────────────

class _AnimatedWaitTime extends StatefulWidget {
  const _AnimatedWaitTime({required this.minutes});
  final int minutes;

  @override
  State<_AnimatedWaitTime> createState() => _AnimatedWaitTimeState();
}

class _AnimatedWaitTimeState extends State<_AnimatedWaitTime> {
  late int _display;

  @override
  void initState() {
    super.initState();
    _display = widget.minutes;
  }

  @override
  void didUpdateWidget(_AnimatedWaitTime old) {
    super.didUpdateWidget(old);
    if (old.minutes != widget.minutes) setState(() => _display = widget.minutes);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: BBMotion.normal,
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: Text(
        '~$_display min',
        key: ValueKey(_display),
        style: BBTypography.labelL,
      ),
    );
  }
}
