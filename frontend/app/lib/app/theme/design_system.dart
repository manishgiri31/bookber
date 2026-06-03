import 'package:flutter/material.dart';

enum AvailabilityState { open, busy, offline, premium, urgent }

enum QueueSeverity { safe, warm, critical }

class BookBerPalette {
  BookBerPalette._();

  // Backgrounds — per BookBer design tokens
  static const Color bgPrimary = Color(0xFF0D0D0F); // near-black obsidian
  static const Color bgSurface = Color(0xFF141417); // card surface
  static const Color bgElevated = Color(0xFF1C1C21); // elevated card
  
  // Text
  static const Color textPrimary = Color(0xFFF5F5F7); // warm white
  static const Color textSecondary = Color(0xFF8A8A9A); // muted
  static const Color textMuted = Color(0xFF4A4A5A); // disabled
  
  // Accents
  static const Color primaryAccent = Color(0xFF00E5C3); // electric teal
  static const Color primaryAccentSoft = Color(0x6600E5C3); // 25% opacity for glows
  static const Color operationalAccent = Color(0xFF00E5C3); // teal secondary
  
  // Semantic colors
  static const Color liveGlow = Color(0xFF22C55E); // success
  static const Color liveShadow = Color(0xFF22C55E);
  static const Color premiumGold = Color(0xFFFF6B35); // warm coral (alerts/warnings)
  static const Color premiumGoldSoft = Color(0xFFFF6B35);
  static const Color urgentRed = Color(0xFFEF4444); // error
  static const Color warningAmber = Color(0xFFF59E0B); // warning
  static const Color busyOrange = Color(0xFFF59E0B);
  static const Color offlineSlate = Color(0xFF4A4A5A);
  static const Color queueSafe = Color(0xFF22C55E);
  static const Color queueWarm = Color(0xFFF59E0B);
  static const Color queueCritical = Color(0xFFEF4444);
  static const Color availabilityOpen = Color(0xFF22C55E);
}

class BookBerShadow {
  BookBerShadow._();

  static const BoxShadow heavy = BoxShadow(
    color: Color(0x29000000),
    blurRadius: 26,
    offset: Offset(0, 14),
  );

  static const BoxShadow soft = BoxShadow(
    color: Color(0x16000000),
    blurRadius: 18,
    offset: Offset(0, 8),
  );
}

class BookBerTypography {
  BookBerTypography._();

  static TextTheme light() {
    return const TextTheme(
      // Display styles (Satoshi)
      displayLarge: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.0,
        color: BookBerPalette.textPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        color: BookBerPalette.textPrimary,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        color: BookBerPalette.textPrimary,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.0,
        color: BookBerPalette.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.0,
        color: BookBerPalette.textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: BookBerPalette.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: BookBerPalette.textPrimary,
      ),
      titleSmall: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: BookBerPalette.textPrimary,
      ),
      // Body styles (DM Sans)
      bodyLarge: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: BookBerPalette.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: BookBerPalette.textSecondary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: BookBerPalette.textMuted,
      ),
      labelLarge: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: BookBerPalette.textPrimary,
      ),
      labelMedium: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: BookBerPalette.textSecondary,
      ),
      labelSmall: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: BookBerPalette.textMuted,
      ),
    );
  }

  static TextTheme dark() {
    return light();
  }
}

class BookBerWaitTime {
  BookBerWaitTime._();

  static Color color(int minutes) {
    if (minutes <= 8) return BookBerPalette.queueSafe;
    if (minutes <= 14) return BookBerPalette.queueWarm;
    return BookBerPalette.queueCritical;
  }

  static QueueSeverity severity(int minutes) {
    if (minutes <= 8) return QueueSeverity.safe;
    if (minutes <= 14) return QueueSeverity.warm;
    return QueueSeverity.critical;
  }

  static String label(int minutes) {
    final severity = BookBerWaitTime.severity(minutes);
    switch (severity) {
      case QueueSeverity.safe:
        return 'Fast';
      case QueueSeverity.warm:
        return 'Busy';
      case QueueSeverity.critical:
        return 'Heavy';
    }
  }
}

class OperationalBadge extends StatelessWidget {
  const OperationalBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.prefix = '',
  });

  final String label;
  final String prefix;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$prefix$label',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class LiveStatusPill extends StatelessWidget {
  const LiveStatusPill({
    super.key,
    required this.label,
    this.color = BookBerPalette.liveGlow,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulseIndicator(color: color, size: 10),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class PulseIndicator extends StatefulWidget {
  const PulseIndicator({
    super.key,
    this.size = 12,
    this.color = BookBerPalette.liveGlow,
  });

  final double size;
  final Color color;

  @override
  State<PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<PulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _scale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.5), weight: 60),
          TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 40),
        ]).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _opacity =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.85, end: 0.18), weight: 60),
          TweenSequenceItem(tween: Tween(begin: 0.18, end: 0.0), weight: 40),
        ]).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
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
              );
            },
          ),
          Container(
            width: widget.size * 0.8,
            height: widget.size * 0.8,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.25),
                  blurRadius: 10,
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

class WaitTimeChip extends StatelessWidget {
  const WaitTimeChip({super.key, required this.waitMinutes});

  final int waitMinutes;

  @override
  Widget build(BuildContext context) {
    final color = BookBerWaitTime.color(waitMinutes);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.av_timer, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '${BookBerWaitTime.label(waitMinutes)} • $waitMinutes min',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class QueueIndicator extends StatelessWidget {
  const QueueIndicator({
    super.key,
    required this.position,
    required this.waitMinutes,
    required this.estimatedEnd,
  });

  final int position;
  final int waitMinutes;
  final DateTime estimatedEnd;

  @override
  Widget build(BuildContext context) {
    final severityColor = BookBerWaitTime.color(waitMinutes);
    final progress = (position / 6).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BookBerPalette.bgElevated,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BookBerShadow.soft],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Queue status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.white10,
                  color: severityColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '#$position',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QueueSummaryLabel(
                label: 'Wait',
                value: '$waitMinutes min',
                color: severityColor,
              ),
              _QueueSummaryLabel(
                label: 'End',
                value: _formatTime(estimatedEnd),
                color: BookBerPalette.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            children: [
              OperationalBadge(
                label: 'Live',
                icon: Icons.flash_on,
                color: BookBerPalette.liveGlow,
              ),
              OperationalBadge(
                label: 'Urgent',
                icon: Icons.notifications_active,
                color: BookBerPalette.urgentRed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QueueSummaryLabel extends StatelessWidget {
  const _QueueSummaryLabel({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: BookBerPalette.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class AvailabilityStateIndicator extends StatelessWidget {
  const AvailabilityStateIndicator({super.key, required this.state});

  final AvailabilityState state;

  @override
  Widget build(BuildContext context) {
    final data = _indicatorData(state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 16, color: data.color),
          const SizedBox(width: 8),
          Text(
            data.label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: data.color),
          ),
          if (state == AvailabilityState.open) ...[
            const SizedBox(width: 8),
            PulseIndicator(color: data.color, size: 8),
          ],
        ],
      ),
    );
  }

  _AvailabilityIndicatorData _indicatorData(AvailabilityState state) {
    switch (state) {
      case AvailabilityState.open:
        return _AvailabilityIndicatorData(
          'Open now',
          Icons.check_circle_outline,
          BookBerPalette.availabilityOpen,
        );
      case AvailabilityState.busy:
        return _AvailabilityIndicatorData(
          'Busy',
          Icons.schedule,
          BookBerPalette.busyOrange,
        );
      case AvailabilityState.offline:
        return _AvailabilityIndicatorData(
          'Offline',
          Icons.do_not_disturb_on,
          BookBerPalette.offlineSlate,
        );
      case AvailabilityState.premium:
        return _AvailabilityIndicatorData(
          'Premium',
          Icons.workspace_premium,
          BookBerPalette.premiumGold,
        );
      case AvailabilityState.urgent:
        return _AvailabilityIndicatorData(
          'Urgent',
          Icons.priority_high,
          BookBerPalette.urgentRed,
        );
    }
  }
}

class _AvailabilityIndicatorData {
  const _AvailabilityIndicatorData(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

class PremiumIndicator extends StatelessWidget {
  const PremiumIndicator({super.key, this.label = 'Premium'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BookBerPalette.premiumGoldSoft, BookBerPalette.premiumGold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33F7D070),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium, size: 16, color: Colors.black87),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

String _formatTime(DateTime timestamp) {
  final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
  final minute = timestamp.minute.toString().padLeft(2, '0');
  final suffix = timestamp.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}
