import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import 'providers/queue_providers.dart';
import 'widgets/connection_status_widget.dart';
import 'widgets/position_card.dart';
import 'widgets/queue_progress_widget.dart';
import 'widgets/activity_feed_widget.dart';
import 'widgets/chair_assignment_modal.dart';

class LiveQueueScreen extends ConsumerStatefulWidget {
  const LiveQueueScreen({super.key, required this.shopId});

  final String shopId;

  @override
  ConsumerState<LiveQueueScreen> createState() => _LiveQueueScreenState();
}

class _LiveQueueScreenState extends ConsumerState<LiveQueueScreen> {
  @override
  void initState() {
    super.initState();
    // TODO: Emit queue:join event via Socket.io
    _addInitialActivities();
  }

  void _addInitialActivities() {
    // Add some initial activities for demo
    ref.read(queueActivityProvider.notifier).state = [
      QueueActivity(
        id: '1',
        message: 'Ravi just got seated — 1 person ahead of you',
        timestamp: DateTime.now(),
        type: ActivityType.info,
      ),
      QueueActivity(
        id: '2',
        message: 'Estimated wait updated to 6 minutes',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        type: ActivityType.warning,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final chairAssignment = ref.watch(chairAssignmentProvider);

    return Scaffold(
      backgroundColor: BookBerPalette.bgPrimary,
      appBar: AppBar(
        backgroundColor: BookBerPalette.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BookBerPalette.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Style Studio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BookBerPalette.textPrimary,
              ),
            ),
            const ConnectionStatusWidget(),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Position Card (hero element)
                const PositionCard(),
                const SizedBox(height: 32),

                // Queue Progress Visualization
                const QueueProgressWidget(),
                const SizedBox(height: 32),

                // Live Activity Feed
                const ActivityFeedWidget(),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Chair Assignment Modal (shows when user is next)
          if (chairAssignment != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  ref.read(chairAssignmentProvider.notifier).state = null;
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: ChairAssignmentModal(),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: BookBerPalette.bgSurface,
          border: Border(
            top: BorderSide(
              color: const Color(0x0FFFFFFF),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: OutlinedButton.icon(
            onPressed: () => _showLeaveQueueDialog(context),
            icon: const Icon(Icons.exit_to_app, color: BookBerPalette.urgentRed),
            label: Text(
              'Leave Queue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: BookBerPalette.urgentRed,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: BookBerPalette.urgentRed,
              side: BorderSide(
                color: BookBerPalette.urgentRed,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  void _showLeaveQueueDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BookBerPalette.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Leave Queue?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BookBerPalette.textPrimary,
          ),
        ),
        content: Text(
          'You will lose your position in the queue. Are you sure?',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: BookBerPalette.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: BookBerPalette.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Emit queue:leave event via Socket.io
              context.pop();
            },
            child: Text(
              'Leave',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BookBerPalette.urgentRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
