import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../providers/queue_providers.dart';

class ActivityFeedWidget extends ConsumerStatefulWidget {
  const ActivityFeedWidget({super.key});

  @override
  ConsumerState<ActivityFeedWidget> createState() => _ActivityFeedWidgetState();
}

class _ActivityFeedWidgetState extends ConsumerState<ActivityFeedWidget> {
  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final activities = ref.watch(queueActivityProvider);

    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Queue Updates',
          style: BBTypography.headingS.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: BBSpacing.px16),
        ...activities.take(3).map((activity) {
          return _ActivityTile(
            key: ValueKey(activity.id),
            activity: activity,
            onDismiss: () {
              ref.read(queueActivityProvider.notifier).state = [
                for (final a in activities)
                  if (a.id != activity.id) a
              ];
            },
          );
        }),
      ],
    );
  }
}

class _ActivityTile extends StatefulWidget {
  const _ActivityTile({
    super.key,
    required this.activity,
    required this.onDismiss,
  });

  final QueueActivity activity;
  final VoidCallback onDismiss;

  @override
  State<_ActivityTile> createState() => _ActivityTileState();
}

class _ActivityTileState extends State<_ActivityTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    return Dismissible(
      key: ValueKey(widget.activity.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDismiss(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(opacity: _fadeAnimation, child: child),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: BBSpacing.px12),
          padding: const EdgeInsets.all(BBSpacing.px16),
          decoration: BoxDecoration(
            color: _getActivityColor(widget.activity.type).withValues(alpha: 0.12),
            borderRadius: BBRadius.md,
            border: Border.all(color: _getActivityColor(widget.activity.type)),
          ),
          child: Row(
            children: [
              Icon(
                _getActivityIcon(widget.activity.type),
                size: BBIconSize.sm,
                color: _getActivityColor(widget.activity.type),
              ),
              const SizedBox(width: BBSpacing.px12),
              Expanded(
                child: Text(
                  widget.activity.message,
                  style: BBTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getActivityColor(ActivityType type) => switch (type) {
        ActivityType.success => BBColors.success,
        ActivityType.warning => BBColors.warning,
        _ => BBColors.brandPrimary,
      };

  IconData _getActivityIcon(ActivityType type) => switch (type) {
        ActivityType.success => Icons.check_circle,
        ActivityType.warning => Icons.warning,
        _ => Icons.info,
      };
}
