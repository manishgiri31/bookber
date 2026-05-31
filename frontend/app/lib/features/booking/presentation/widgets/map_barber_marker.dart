import 'package:flutter/material.dart';

import '../home_discovery_controller.dart';

class BarberMarkerPalette {
  const BarberMarkerPalette({
    required this.base,
    required this.glow,
    required this.surface,
    required this.text,
  });

  final Color base;
  final Color glow;
  final Color surface;
  final Color text;
}

class BarberMarkerColors {
  static const available = BarberMarkerPalette(
    base: Color(0xFF22C55E),
    glow: Color(0xFF86EFAC),
    surface: Color(0xFF0F172A),
    text: Colors.white,
  );

  static const busy = BarberMarkerPalette(
    base: Color(0xFFF59E0B),
    glow: Color(0xFFFCD34D),
    surface: Color(0xFF1F2937),
    text: Colors.white,
  );

  static const premium = BarberMarkerPalette(
    base: Color(0xFF8B5CF6),
    glow: Color(0xFFC4B5FD),
    surface: Color(0xFF111827),
    text: Colors.white,
  );

  static const trending = BarberMarkerPalette(
    base: Color(0xFF3B82F6),
    glow: Color(0xFF93C5FD),
    surface: Color(0xFF0B1220),
    text: Colors.white,
  );

  static const instantBooking = BarberMarkerPalette(
    base: Color(0xFF10B981),
    glow: Color(0xFF6EE7B7),
    surface: Color(0xFF052E16),
    text: Colors.white,
  );

  static const unavailable = BarberMarkerPalette(
    base: Color(0xFFEF4444),
    glow: Color(0xFFFCA5A5),
    surface: Color(0xFF1F2937),
    text: Colors.white,
  );
}

class MapBarberMarker extends StatefulWidget {
  const MapBarberMarker({
    super.key,
    required this.name,
    required this.waitMinutes,
    required this.isAvailable,
    required this.isPremium,
    required this.isSelected,
    required this.isTrending,
    required this.hasInstantBooking,
    required this.operationalState,
  });

  final String name;
  final int waitMinutes;
  final bool isAvailable;
  final bool isPremium;
  final bool isSelected;
  final bool isTrending;
  final bool hasInstantBooking;
  final BarberOperationalState operationalState;

  @override
  State<MapBarberMarker> createState() => _MapBarberMarkerState();
}

class _MapBarberMarkerState extends State<MapBarberMarker> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _pulseAnimation = Tween<double>(
      begin: 0.45,
      end: 1,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  BarberMarkerPalette get palette {
    if (!widget.isAvailable) return BarberMarkerColors.unavailable;
    if (widget.operationalState == BarberOperationalState.instantBooking || widget.hasInstantBooking) {
      return BarberMarkerColors.instantBooking;
    }
    if (widget.operationalState == BarberOperationalState.premium || widget.isPremium) {
      return BarberMarkerColors.premium;
    }
    if (widget.operationalState == BarberOperationalState.trending || widget.isTrending) {
      return BarberMarkerColors.trending;
    }
    if (widget.waitMinutes <= 12) return BarberMarkerColors.available;
    return BarberMarkerColors.busy;
  }

  String get statusLabel {
    switch (widget.operationalState) {
      case BarberOperationalState.availableNow:
        return 'OPEN';
      case BarberOperationalState.busy:
        return 'BUSY';
      case BarberOperationalState.premium:
        return 'PREMIUM';
      case BarberOperationalState.trending:
        return 'TRENDING';
      case BarberOperationalState.instantBooking:
        return 'INSTANT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = this.palette;
    final waitLabel = widget.waitMinutes <= 0 ? 'NOW' : '${widget.waitMinutes}m';
    final selected = widget.isSelected;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: selected ? _scaleAnimation.value : 1,
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              if (widget.isAvailable)
                Positioned(
                  top: 22,
                  child: Opacity(
                    opacity: 0.18 + (_pulseAnimation.value * 0.2),
                    child: Container(
                      width: 62 + (_pulseAnimation.value * 18),
                      height: 62 + (_pulseAnimation.value * 18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.glow.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          palette.surface.withValues(alpha: 0.98),
                          palette.surface.withValues(alpha: 0.84),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.24),
                        width: selected ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: palette.base.withValues(alpha: selected ? 0.42 : 0.28),
                          blurRadius: selected ? 26 : 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StatusDot(color: palette.base),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: palette.text,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            if (widget.isPremium || widget.operationalState == BarberOperationalState.premium)
                              ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.workspace_premium, size: 12, color: Color(0xFFFBBF24)),
                              ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          waitLabel,
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          widget.isAvailable ? 'Live wait' : 'Paused',
                          style: TextStyle(
                            color: palette.text.withValues(alpha: 0.75),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  _PinTail(color: palette.base, selected: selected),
                ],
              ),
              if (widget.hasInstantBooking)
                Positioned(
                  right: -2,
                  top: 16,
                  child: _BadgeChip(
                    label: 'INSTANT',
                    color: BarberMarkerColors.instantBooking.base,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _PinTail extends StatelessWidget {
  const _PinTail({
    required this.color,
    required this.selected,
  });

  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: selected ? 18 : 16,
      height: selected ? 18 : 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
