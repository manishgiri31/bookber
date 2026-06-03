import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_bottom_nav.dart';

class AdminOverviewScreen extends ConsumerStatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  ConsumerState<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends ConsumerState<AdminOverviewScreen> {
  bool _showTodayUsers = false;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);
    final activityAsync = ref.watch(platformActivityProvider);
    final alertsAsync = ref.watch(platformAlertsProvider);
    final adminAccent = const Color(0xFF8B5CF6);

    return Scaffold(
      backgroundColor: BookBerPalette.bgPrimary,
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
                    'Admin Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: BookBerPalette.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: adminAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Admin',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: adminAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Platform Stats
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    statsAsync.when(
                      data: (stats) => _PlatformStatsGrid(
                        stats: stats,
                        showTodayUsers: _showTodayUsers,
                        onToggleUsers: () => setState(() => _showTodayUsers = !_showTodayUsers),
                      ),
                      loading: () => const _StatsLoading(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),

                    // Recent Activity Feed
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: BookBerPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    activityAsync.when(
                      data: (activities) => _ActivityFeed(activities: activities),
                      loading: () => const _ActivityLoading(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),

                    // Alerts Section
                    Text(
                      'Alerts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: BookBerPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    alertsAsync.when(
                      data: (alerts) => _AlertsSection(alerts: alerts),
                      loading: () => const _AlertsLoading(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: 0,
        onTap: (index) {
          // TODO: Navigate to respective screens
        },
      ),
    );
  }
}

class _PlatformStatsGrid extends StatelessWidget {
  const _PlatformStatsGrid({
    required this.stats,
    required this.showTodayUsers,
    required this.onToggleUsers,
  });

  final AdminStats stats;
  final bool showTodayUsers;
  final VoidCallback onToggleUsers;

  @override
  Widget build(BuildContext context) {
    final adminAccent = const Color(0xFF8B5CF6);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          label: 'Total Users',
          value: showTodayUsers ? stats.usersToday.toString() : stats.usersAllTime.toString(),
          subtitle: showTodayUsers ? 'Today' : 'All time',
          color: adminAccent,
          onToggle: onToggleUsers,
        ),
        _StatCard(
          label: 'Active Shops',
          value: stats.activeShops.toString(),
          color: BookBerPalette.primaryAccent,
        ),
        _StatCard(
          label: 'Bookings Today',
          value: stats.bookingsToday.toString(),
          color: BookBerPalette.primaryAccent,
        ),
        _StatCard(
          label: 'Revenue Today',
          value: '₹${stats.revenueToday}',
          color: BookBerPalette.queueSafe,
        ),
        _StatCard(
          label: 'Platform Commission',
          value: '₹${stats.platformCommission}',
          color: adminAccent,
        ),
        _StatCard(
          label: 'Active Queue Entries',
          value: stats.activeQueueEntries.toString(),
          color: BookBerPalette.primaryAccent,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
    this.onToggle,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Color color;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: BookBerPalette.textSecondary,
                ),
              ),
              if (onToggle != null)
                GestureDetector(
                  onTap: onToggle,
                  child: Icon(
                    Icons.swap_horiz,
                    size: 16,
                    color: BookBerPalette.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: BookBerPalette.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: List.generate(6, (_) => _StatCardSkeleton()),
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: BookBerPalette.bgElevated,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 24,
            decoration: BoxDecoration(
              color: BookBerPalette.bgElevated,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.activities});

  final List<PlatformActivity> activities;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: activities.map((activity) {
        return _ActivityTile(activity: activity);
      }).toList(),
    );
  }
}

class _ActivityLoading extends StatelessWidget {
  const _ActivityLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (_) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 60,
          decoration: BoxDecoration(
            color: BookBerPalette.bgSurface,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final PlatformActivity activity;

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    switch (activity.type) {
      case ActivityType.success:
        borderColor = BookBerPalette.queueSafe;
        break;
      case ActivityType.warning:
        borderColor = BookBerPalette.warningAmber;
        break;
      case ActivityType.alert:
        borderColor = BookBerPalette.urgentRed;
        break;
      case ActivityType.info:
        borderColor = BookBerPalette.primaryAccent;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: borderColor,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.message,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: BookBerPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(activity.timestamp),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: BookBerPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: BookBerPalette.textMuted,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({required this.alerts});

  final List<PlatformAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: alerts.map((alert) {
        return _AlertCard(alert: alert);
      }).toList(),
    );
  }
}

class _AlertsLoading extends StatelessWidget {
  const _AlertsLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (_) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            color: BookBerPalette.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: BookBerPalette.urgentRed,
              width: 1,
            ),
          ),
        );
      }),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final PlatformAlert alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BookBerPalette.urgentRed,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BookBerPalette.urgentRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: BookBerPalette.urgentRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.entityName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: BookBerPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: BookBerPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: BookBerPalette.textMuted,
          ),
        ],
      ),
    );
  }
}
