import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/tokens.dart';
import '../providers/queue_providers.dart';

class QueueProgressWidget extends ConsumerWidget {
  const QueueProgressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queuePositionAsync = ref.watch(queuePositionProvider('shop_1'));

    return queuePositionAsync.when(
      data: (position) {
        if (position.status == QueueStatus.inService) {
          return const SizedBox.shrink();
        }
        return _QueueProgressRow(
          userPosition: position.position,
          totalInQueue: position.totalInQueue,
        );
      },
      loading: () => const _LoadingProgress(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _QueueProgressRow extends StatelessWidget {
  const _QueueProgressRow({
    required this.userPosition,
    required this.totalInQueue,
  });

  final int userPosition;
  final int totalInQueue;

  @override
  Widget build(BuildContext context) {
    final visibleCount = totalInQueue > 8 ? 8 : totalInQueue;
    final showMore = totalInQueue > 8;

    return Row(
      children: [
        ...List.generate(visibleCount, (index) {
          final isUser = index + 1 == userPosition;
          final isAhead = index + 1 < userPosition;
          final isBehind = index + 1 > userPosition;

          return _PersonIcon(isAhead: isAhead, isUser: isUser, isBehind: isBehind);
        }),
        if (showMore) ...[
          const SizedBox(width: BBSpacing.px8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: BBSpacing.px12, vertical: BBSpacing.px8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BBRadius.pill,
            ),
            child: Text(
              '+${totalInQueue - 8} more',
              style: BBTypography.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PersonIcon extends StatefulWidget {
  const _PersonIcon({
    required this.isAhead,
    required this.isUser,
    required this.isBehind,
  });

  final bool isAhead;
  final bool isUser;
  final bool isBehind;

  @override
  State<_PersonIcon> createState() => _PersonIconState();
}

class _PersonIconState extends State<_PersonIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.isUser) {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      )..repeat(reverse: true);

      _glowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
    } else {
      _controller = AnimationController(vsync: this);
      _glowAnimation = const AlwaysStoppedAnimation(1.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isUser ? 32.0 : 24.0;
    final color = widget.isAhead
        ? BBColors.brandPrimary
        : widget.isUser
            ? BBColors.brandPrimary
            : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Padding(
      padding: const EdgeInsets.only(right: BBSpacing.px8),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isUser ? _glowAnimation.value : 1.0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(size / 2),
                boxShadow: widget.isUser
                    ? [
                        BoxShadow(
                          color: BBColors.brandPrimary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.person,
                size: size * 0.6,
                color: (widget.isUser || widget.isAhead)
                    ? Colors.white
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingProgress extends StatelessWidget {
  const _LoadingProgress();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(8, (index) {
        return Padding(
          padding: const EdgeInsets.only(right: BBSpacing.px8),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }),
    );
  }
}
