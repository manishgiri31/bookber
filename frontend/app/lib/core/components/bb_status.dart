import 'package:flutter/material.dart';
import '../design/tokens.dart';

// ─────────────────────────────────────────────────────────────
// PULSE INDICATOR — animated live dot
// ─────────────────────────────────────────────────────────────

class BBPulse extends StatefulWidget {
  const BBPulse({
    super.key,
    this.color = BBColors.success,
    this.size = 8.0,
  });

  final Color color;
  final double size;

  @override
  State<BBPulse> createState() => _BBPulseState();
}

class _BBPulseState extends State<BBPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: BBMotion.pulse)..repeat();

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.6), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.6, end: 0.8), weight: 45),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 45),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outer = widget.size * 2.2;
    return SizedBox(
      width: outer,
      height: outer,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATUS PILL — open / busy / closed / live
// ─────────────────────────────────────────────────────────────

enum BBStatusType { open, busy, closed, live, premium, urgent, info }

class BBStatusPill extends StatelessWidget {
  const BBStatusPill({
    super.key,
    required this.type,
    required this.label,
    this.showPulse = false,
  });

  final BBStatusType type;
  final String label;
  final bool showPulse;

  static Color _color(BBStatusType t) {
    switch (t) {
      case BBStatusType.open: return BBColors.success;
      case BBStatusType.busy: return BBColors.warning;
      case BBStatusType.closed: return BBColors.textDisabled;
      case BBStatusType.live: return BBColors.success;
      case BBStatusType.premium: return BBColors.brandSecondary;
      case BBStatusType.urgent: return BBColors.error;
      case BBStatusType.info: return BBColors.brandPrimary;
    }
  }

  static IconData _icon(BBStatusType t) {
    switch (t) {
      case BBStatusType.open: return Icons.check_circle_outline;
      case BBStatusType.busy: return Icons.schedule_outlined;
      case BBStatusType.closed: return Icons.do_not_disturb_on_outlined;
      case BBStatusType.live: return Icons.bolt;
      case BBStatusType.premium: return Icons.workspace_premium;
      case BBStatusType.urgent: return Icons.priority_high;
      case BBStatusType.info: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(type);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpacing.px12,
        vertical: BBSpacing.px6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BBRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showPulse)
            BBPulse(color: color, size: 6)
          else
            Icon(_icon(type), size: BBIconSize.xs, color: color),
          const SizedBox(width: BBSpacing.px6),
          Text(
            label,
            style: BBTypography.labelS.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WAIT TIME BADGE — queue severity color
// ─────────────────────────────────────────────────────────────

class BBWaitBadge extends StatelessWidget {
  const BBWaitBadge({super.key, required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final color = BBColors.queueColor(minutes);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpacing.px10,
        vertical: BBSpacing.px4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BBRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.av_timer, size: BBIconSize.xs, color: color),
          const SizedBox(width: BBSpacing.px4),
          Text(
            '~$minutes min',
            style: BBTypography.labelS.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RATING BADGE
// ─────────────────────────────────────────────────────────────

class BBRatingBadge extends StatelessWidget {
  const BBRatingBadge({
    super.key,
    required this.rating,
    this.reviewCount,
  });

  final double rating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: BBIconSize.sm, color: BBColors.warning),
        const SizedBox(width: BBSpacing.px4),
        Text(
          rating.toStringAsFixed(1),
          style: BBTypography.labelM.copyWith(color: BBColors.textPrimary),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: BBSpacing.px4),
          Text(
            '($reviewCount)',
            style: BBTypography.labelS,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// QUEUE POSITION COUNTER — large animated number
// ─────────────────────────────────────────────────────────────

class BBQueuePositionCounter extends StatefulWidget {
  const BBQueuePositionCounter({
    super.key,
    required this.position,
    this.color = BBColors.brandPrimary,
    this.size = BBQueueCounterSize.large,
  });

  final int position;
  final Color color;
  final BBQueueCounterSize size;

  @override
  State<BBQueuePositionCounter> createState() => _BBQueuePositionCounterState();
}

enum BBQueueCounterSize { large, medium, small }

class _BBQueuePositionCounterState extends State<BBQueuePositionCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  int _prevPosition = 0;

  @override
  void initState() {
    super.initState();
    _prevPosition = widget.position;
    _ctrl = AnimationController(vsync: this, duration: BBMotion.normal);
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: BBMotion.spring));
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(BBQueuePositionCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) {
      _ctrl.forward(from: 0);
      _prevPosition = oldWidget.position;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _fontSize {
    switch (widget.size) {
      case BBQueueCounterSize.large: return 72;
      case BBQueueCounterSize.medium: return 48;
      case BBQueueCounterSize.small: return 32;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Opacity(
            opacity: _opacity.value == 0 ? 1.0 : _opacity.value,
            child: Text(
              '#${widget.position}',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: _fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -2.0,
                height: 1.0,
                color: widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CONNECTION STATUS INDICATOR
// ─────────────────────────────────────────────────────────────

enum BBConnectionState { connected, reconnecting, disconnected }

class BBConnectionStatus extends StatelessWidget {
  const BBConnectionStatus({
    super.key,
    required this.state,
  });

  final BBConnectionState state;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case BBConnectionState.connected:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BBPulse(color: BBColors.success, size: 4),
            const SizedBox(width: BBSpacing.px6),
            Text(
              'Live',
              style: BBTypography.labelS.copyWith(color: BBColors.success),
            ),
          ],
        );
      case BBConnectionState.reconnecting:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation(BBColors.warning),
              ),
            ),
            const SizedBox(width: BBSpacing.px6),
            Text(
              'Reconnecting',
              style: BBTypography.labelS.copyWith(color: BBColors.warning),
            ),
          ],
        );
      case BBConnectionState.disconnected:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: BBColors.error,
              ),
            ),
            const SizedBox(width: BBSpacing.px6),
            Text(
              'Offline',
              style: BBTypography.labelS.copyWith(color: BBColors.error),
            ),
          ],
        );
    }
  }
}
