import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/models/bookber_models.dart';
import '../../domain/booking_flow_state.dart';

class AppleMapsBarberSheet extends StatefulWidget {
  const AppleMapsBarberSheet({
    super.key,
    required this.selectedBarber,
    required this.availableServices,
    required this.bookingFlow,
    required this.onBookNow,
  });

  final Barber? selectedBarber;
  final List<ServiceItem> availableServices;
  final BookingFlowState bookingFlow;
  final VoidCallback onBookNow;

  @override
  State<AppleMapsBarberSheet> createState() => _AppleMapsBarberSheetState();
}

class _AppleMapsBarberSheetState extends State<AppleMapsBarberSheet> {
  double _extent = 0.18;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        setState(() => _extent = notification.extent);
        return false;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.18,
        minChildSize: 0.18,
        maxChildSize: 0.82,
        snap: true,
        snapSizes: const [0.18, 0.42, 0.82],
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Material(
                color: Colors.white.withValues(alpha: 0.84),
                child: SafeArea(
                  top: false,
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: _SheetHeader(
                          extent: _extent,
                          barber: widget.selectedBarber,
                          bookingFlow: widget.bookingFlow,
                        ),
                      ),
                      if (widget.selectedBarber != null) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _LiveStatsRow(
                              extent: _extent,
                              bookingFlow: widget.bookingFlow,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(child: SizedBox(height: _extent > 0.3 ? 14 : 8)),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverToBoxAdapter(
                            child: _ServiceList(
                              services: widget.availableServices,
                              bookingFlow: widget.bookingFlow,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(child: SizedBox(height: _extent > 0.3 ? 14 : 10)),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverToBoxAdapter(
                            child: _BookingCta(
                              barberName: widget.selectedBarber!.name,
                              onBookNow: widget.onBookNow,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ] else
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 6, 16, 24),
                            child: _EmptyState(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.extent,
    required this.barber,
    required this.bookingFlow,
  });

  final double extent;
  final Barber? barber;
  final BookingFlowState bookingFlow;

  @override
  Widget build(BuildContext context) {
    final collapsed = extent < 0.3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          if (barber == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white),
              ),
              child: const Text(
                'Tap a barber pin to see live wait, services, and booking options.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          else
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.black,
                  child: Text(
                    barber!.name.substring(0, 1),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barber!.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: collapsed ? 18 : 20,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${barber!.rating} rating · ${barber!.distanceKm} km away',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                _LiveDot(label: barber!.isAvailable ? 'Open' : 'Busy'),
              ],
            ),
        ],
      ),
    );
  }
}

class _LiveStatsRow extends StatelessWidget {
  const _LiveStatsRow({
    required this.extent,
    required this.bookingFlow,
  });

  final double extent;
  final BookingFlowState bookingFlow;

  @override
  Widget build(BuildContext context) {
    final booking = bookingFlow.booking;
    final queueStatus = booking?.status ?? (bookingFlow.selectedBarber == null ? 'LIVE' : 'ACTIVE');
    final wait = booking?.estimatedWaitMinutes ?? 12;
    final queuePosition = booking?.queuePosition ?? 1;
    final scheduledAt = booking?.scheduledAt;
    final completion = scheduledAt == null ? 'Today' : '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: extent < 0.22 ? 0.88 : 1,
      child: Row(
        children: [
          Expanded(
            child: _GlassStat(
              label: 'ETA',
              value: '$wait min',
              accent: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _GlassStat(
              label: 'Queue',
              value: '#$queuePosition',
              accent: const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _GlassStat(
              label: 'Status',
              value: queueStatus,
              accent: const Color(0xFF22C55E),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _GlassStat(
              label: 'Finish',
              value: completion,
              accent: const Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassStat extends StatelessWidget {
  const _GlassStat({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
          const SizedBox(height: 10),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.black54)),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ServiceList extends StatelessWidget {
  const _ServiceList({
    required this.services,
    required this.bookingFlow,
  });

  final List<ServiceItem> services;
  final BookingFlowState bookingFlow;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Services', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...services.map((service) {
          final selected = bookingFlow.selectedServices.any((item) => item.id == service.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? Colors.black : Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: selected ? Colors.black : Colors.white),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${service.category} · ${service.durationMin} min',
                          style: TextStyle(
                            color: selected ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Rs. ${service.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _BookingCta extends StatelessWidget {
  const _BookingCta({
    required this.barberName,
    required this.onBookNow,
  });

  final String barberName;
  final VoidCallback onBookNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book with $barberName',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Instant booking with live queue awareness',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            onPressed: onBookNow,
            child: const Text('Book now'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Text(
      'No barber selected',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      textAlign: TextAlign.center,
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
