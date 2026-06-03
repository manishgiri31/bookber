import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import '../providers/queue_providers.dart';

class PositionCard extends ConsumerWidget {
  const PositionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queuePositionAsync = ref.watch(queuePositionProvider('shop_1'));

    return queuePositionAsync.when(
      data: (position) {
        if (position.status == QueueStatus.inService) {
          return const _InServiceCard();
        }
        return _WaitingCard(position: position);
      },
      loading: () => const _LoadingCard(),
      error: (error, stack) => const _ErrorCard(),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.position});

  final QueuePosition position;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0x0FFFFFFF),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Your Position',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: BookBerPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedCounter(
            value: position.position,
            duration: const Duration(milliseconds: 300),
          ),
          const SizedBox(height: 8),
          Text(
            'in queue',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: BookBerPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: BookBerPalette.bgElevated,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.access_time,
                  size: 20,
                  color: BookBerPalette.textSecondary,
                ),
                const SizedBox(width: 8),
                AnimatedWaitTime(
                  minutes: position.estimatedWaitMinutes,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InServiceCard extends StatelessWidget {
  const _InServiceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: BookBerPalette.warningAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: BookBerPalette.warningAmber,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PulsingBadge(),
              const SizedBox(width: 12),
              Text(
                'In Service',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: BookBerPalette.warningAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Haircut',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: BookBerPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'with Rahul',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: BookBerPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(BookBerPalette.warningAmber),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'In progress',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: BookBerPalette.textSecondary,
                    ),
                  ),
                  Text(
                    '~5 min remaining',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BookBerPalette.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0x0FFFFFFF),
          width: 1,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: BookBerPalette.primaryAccent),
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0x0FFFFFFF),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: BookBerPalette.urgentRed,
          ),
          const SizedBox(height: 16),
          Text(
            'Connection Error',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: BookBerPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to connect to queue',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: BookBerPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({
    required this.value,
    this.duration = const Duration(milliseconds: 300),
  });

  final int value;
  final Duration duration;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter> {
  int _displayValue = 0;

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      setState(() {
        _displayValue = widget.value;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: widget.duration,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.5),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Text(
        _displayValue.toString(),
        key: ValueKey(_displayValue),
        style: TextStyle(
          fontSize: 64,
          fontWeight: FontWeight.w700,
          color: BookBerPalette.primaryAccent,
        ),
      ),
    );
  }
}

class AnimatedWaitTime extends StatefulWidget {
  const AnimatedWaitTime({required this.minutes});

  final int minutes;

  @override
  State<AnimatedWaitTime> createState() => _AnimatedWaitTimeState();
}

class _AnimatedWaitTimeState extends State<AnimatedWaitTime> {
  int _displayMinutes = 0;

  @override
  void didUpdateWidget(AnimatedWaitTime oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minutes != widget.minutes) {
      setState(() {
        _displayMinutes = widget.minutes;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _displayMinutes = widget.minutes;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Text(
        '~$_displayMinutes minutes',
        key: ValueKey(_displayMinutes),
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: BookBerPalette.textPrimary,
        ),
      ),
    );
  }
}

class _PulsingBadge extends StatefulWidget {
  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: BookBerPalette.warningAmber,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
