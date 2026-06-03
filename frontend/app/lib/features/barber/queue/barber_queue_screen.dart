import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import '../../../core/models/bookber_models.dart';
import '../../../core/providers/auth_provider.dart';
import '../providers/barber_providers.dart';
import '../../barber_dashboard/presentation/barber_dashboard_controller.dart';
import '../../../core/network/api_result.dart';
import '../widgets/barber_bottom_nav.dart';

class BarberQueueScreen extends ConsumerStatefulWidget {
  const BarberQueueScreen({super.key});

  @override
  ConsumerState<BarberQueueScreen> createState() => _BarberQueueScreenState();
}

class _BarberQueueScreenState extends ConsumerState<BarberQueueScreen> {
  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(barberQueueProvider);
    final chairsAsync = ref.watch(chairStatusProvider);

    return Scaffold(
      backgroundColor: BookBerPalette.bgPrimary,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            builder: (context) {
              final nameCtrl = TextEditingController();
              final servicesCtrl = TextEditingController();
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer name (optional)')),
                    TextField(controller: servicesCtrl, decoration: const InputDecoration(labelText: 'Service IDs (comma separated)')),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        final services = servicesCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                        Navigator.of(context).pop({'name': nameCtrl.text.trim(), 'services': services});
                      },
                      child: const Text('Add Walk-in'),
                    ),
                  ],
                ),
              );
            },
          );

          if (result != null) {
            final user = ref.read(currentUserProvider);
            final shopId = user?.id ?? '';
            try {
              final res = await ref.read(barberDashboardControllerProvider.notifier).addWalkIn(
                    shopId,
                    List<String>.from(result['services'] ?? []),
                    result['name']?.toString(),
                  );
              if (res is ApiSuccess<void>) {
                ref.invalidate(barberQueueProvider);
                ref.invalidate(barberStatsProvider);
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add walk-in: $e')));
            }
          }
        },
        child: const Icon(Icons.person_add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Live Queue',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: BookBerPalette.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      const _RotatingIcon(),
                      const SizedBox(width: 8),
                      queueAsync.when(
                        data: (queue) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: BookBerPalette.primaryAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${queue.length}',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: BookBerPalette.primaryAccent,
                            ),
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Chair Status Row
            chairsAsync.when(
              data: (chairs) => _ChairStatusRow(chairs: chairs),
              loading: () => const _ChairStatusLoading(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Queue List
            Expanded(
              child: queueAsync.when(
                data: (queue) {
                  if (queue.isEmpty) {
                    return const _EmptyQueueState();
                  }
                  return _QueueList(queue: queue);
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: BookBerPalette.primaryAccent),
                ),
                error: (_, __) => const Center(
                  child: Text(
                    'Error loading queue',
                    style: TextStyle(color: BookBerPalette.textSecondary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BarberBottomNav(
        currentIndex: 1,
        onTap: (index) {
          // TODO: Navigate to respective screens
        },
      ),
    );
  }
}

class _RotatingIcon extends StatefulWidget {
  const _RotatingIcon();

  @override
  State<_RotatingIcon> createState() => _RotatingIconState();
}

class _RotatingIconState extends State<_RotatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 6.28318).animate(_controller);
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
        return Transform.rotate(
          angle: _animation.value,
          child: const Icon(
            Icons.refresh,
            size: 20,
            color: BookBerPalette.primaryAccent,
          ),
        );
      },
    );
  }
}

class _ChairStatusRow extends StatelessWidget {
  const _ChairStatusRow({required this.chairs});

  final List<ChairStatus> chairs;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: chairs.map((chair) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _ChairCard(chair: chair),
          );
        }).toList(),
      ),
    );
  }
}

class _ChairStatusLoading extends StatelessWidget {
  const _ChairStatusLoading();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(3, (_) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _ChairCardSkeleton(),
          );
        }),
      ),
    );
  }
}

class _ChairCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 120,
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _ChairCard extends StatelessWidget {
  const _ChairCard({required this.chair});

  final ChairStatus chair;

  @override
  Widget build(BuildContext context) {
    Color ringColor;
    String statusText;

    switch (chair.status) {
      case ChairStatusType.available:
        ringColor = BookBerPalette.queueSafe;
        statusText = 'Available';
        break;
      case ChairStatusType.inService:
        ringColor = BookBerPalette.warningAmber;
        statusText = 'In Service';
        break;
      case ChairStatusType.onBreak:
        ringColor = BookBerPalette.urgentRed;
        statusText = 'On Break';
        break;
      case ChairStatusType.reserved:
        ringColor = BookBerPalette.primaryAccent;
        statusText = 'Reserved';
        break;
    }

    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ringColor,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chair ${chair.chairNumber}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: BookBerPalette.textPrimary,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: ringColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (chair.customerName != null) ...[
            Text(
              chair.customerName!,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: BookBerPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              chair.service ?? '',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: BookBerPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              chair.timeRemaining == null ? '' : '${chair.timeRemaining} min',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ringColor,
              ),
            ),
          ] else
            Text(
              statusText,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ringColor,
              ),
            ),
          const Spacer(),
          // Action buttons
          if (chair.status == ChairStatusType.available)
            SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Start service
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BookBerPalette.primaryAccent,
                  foregroundColor: BookBerPalette.bgPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  'Start',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else if (chair.status == ChairStatusType.inService)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Complete service
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BookBerPalette.primaryAccent,
                      foregroundColor: BookBerPalette.bgPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Complete',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Hold
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BookBerPalette.textPrimary,
                      side: BorderSide(color: const Color(0x0FFFFFFF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Hold',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _QueueList extends StatelessWidget {
  const _QueueList({required this.queue});

  final List<QueueEntry> queue;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: queue.length,
      itemBuilder: (context, index) {
        final entry = queue[index];
        return _QueueEntryTile(entry: entry);
      },
    );
  }
}

class _QueueEntryTile extends ConsumerWidget {
  const _QueueEntryTile({required this.entry});

  final QueueEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Position number
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BookBerPalette.primaryAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${entry.position}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: BookBerPalette.primaryAccent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Customer info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.customerName ?? 'Customer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: BookBerPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: entry.isWalkIn
                            ? BookBerPalette.warningAmber.withValues(alpha: 0.12)
                            : BookBerPalette.primaryAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        entry.isWalkIn ? 'Walk-in' : 'Booked',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: entry.isWalkIn
                              ? BookBerPalette.warningAmber
                              : BookBerPalette.primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.service,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: BookBerPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Wait: ${entry.waitTime}',
                  style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: BookBerPalette.textSecondary,
              ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              if (entry.status == QueueStatus.waiting)
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final res = await ref.read(barberDashboardControllerProvider.notifier).updateQueueEntryStatus(entry.bookingId, 'in_service');
                        if (res is ApiSuccess<void>) {
                          ref.invalidate(barberQueueProvider);
                          ref.invalidate(barberStatsProvider);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start: $e')));
                      }
                    },
                    child: const Text('Start'),
                  ),
                )
              else if (entry.status == QueueStatus.inService)
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final res = await ref.read(barberDashboardControllerProvider.notifier).updateQueueEntryStatus(entry.bookingId, 'completed');
                        if (res is ApiSuccess<void>) {
                          ref.invalidate(barberQueueProvider);
                          ref.invalidate(barberStatsProvider);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to complete: $e')));
                      }
                    },
                    child: const Text('Complete'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyQueueState extends StatelessWidget {
  const _EmptyQueueState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: BookBerPalette.bgElevated,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.content_cut,
              size: 40,
              color: BookBerPalette.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No one in queue',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: BookBerPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Add walk-in
            },
            icon: const Icon(Icons.person_add_outlined),
            label: Text(
              'Add Walk-in',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: BookBerPalette.primaryAccent,
              foregroundColor: BookBerPalette.bgPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
