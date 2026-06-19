import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../providers/admin_providers.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String _selectedPeriod = '7D';

  @override
  Widget build(BuildContext context) {
    final range = _selectedPeriod.toLowerCase();
    final statsAsync = ref.watch(adminReportProvider(range));

    return Scaffold(
      backgroundColor: context.bbColors.bgCanvas,
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
                    'Reports',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: context.bbColors.textPrimary,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final url = await ref.read(adminActionsProvider.notifier).exportReport('bookings', range);
                      if (url.isEmpty) return;
                      final uri = Uri.tryParse(url);
                      if (uri != null) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: Icon(Icons.download_outlined, size: 18),
                    label: Text(
                      'Export CSV',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BBColors.brandPrimary,
                      side: BorderSide(color: BBColors.brandPrimary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Revenue Chart
            statsAsync.when(
              data: (stats) => _RevenueChartSection(
                selectedPeriod: _selectedPeriod,
                stats: stats,
                onPeriodChanged: (period) => setState(() => _selectedPeriod = period),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: BBColors.brandPrimary),
              ),
              error: (_, __) => _RevenueChartSection(
                selectedPeriod: _selectedPeriod,
                stats: const AdminStats(
                  totalUsers: 0,
                  activeShops: 0,
                  bookingsToday: 0,
                  revenueToday: 0,
                  platformCommission: 0,
                  activeQueueEntries: 0,
                  usersToday: 0,
                  usersAllTime: 0,
                ),
                onPeriodChanged: (period) => setState(() => _selectedPeriod = period),
              ),
            ),
            const SizedBox(height: 24),

            // Bookings by Status
            _BookingsByStatusSection(),
            const SizedBox(height: 24),

            // Top Shops by Revenue
            _TopShopsSection(),
            const SizedBox(height: 24),

            // Top Services
            _TopServicesSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _RevenueChartSection extends StatelessWidget {
  const _RevenueChartSection({
    required this.selectedPeriod,
    required this.stats,
    required this.onPeriodChanged,
  });

  final String selectedPeriod;
  final AdminStats stats;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bbColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.bbColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  _PeriodChip(
                    label: '7D',
                    isSelected: selectedPeriod == '7D',
                    onTap: () => onPeriodChanged('7D'),
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: '30D',
                    isSelected: selectedPeriod == '30D',
                    onTap: () => onPeriodChanged('30D'),
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: '90D',
                    isSelected: selectedPeriod == '90D',
                    onTap: () => onPeriodChanged('90D'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: context.bbColors.bgElevated.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 48,
                    color: context.bbColors.textDisabled,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rs. ${stats.revenueToday}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: BBColors.brandPrimary,
                    ),
                  ),
                  Text(
                    '${stats.bookingsToday} bookings - ${stats.activeQueueEntries} active queue entries',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.bbColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? BBColors.brandPrimary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? context.bbColors.bgCanvas : context.bbColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _BookingsByStatusSection extends StatelessWidget {
  const _BookingsByStatusSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bbColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bookings by Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.bbColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          // Placeholder for donut chart
          Row(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: context.bbColors.bgElevated.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'Donut\nChart',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.bbColors.textDisabled,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendItem(color: BBColors.brandPrimary, label: 'Confirmed', value: '45%'),
                    const SizedBox(height: 12),
                    _LegendItem(color: BBColors.warning, label: 'In Progress', value: '15%'),
                    const SizedBox(height: 12),
                    _LegendItem(color: BBColors.success, label: 'Completed', value: '30%'),
                    const SizedBox(height: 12),
                    _LegendItem(color: context.bbColors.textDisabled, label: 'Cancelled', value: '10%'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: context.bbColors.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.bbColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TopShopsSection extends StatelessWidget {
  const _TopShopsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bbColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Shops by Revenue',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.bbColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          // Placeholder for horizontal bar chart
          Column(
            children: List.generate(5, (index) {
              final revenue = [50000, 42000, 35000, 28000, 22000][index];
              final maxRevenue = 50000;
              final percentage = revenue / maxRevenue;
              final shopNames = ['Style Studio', 'Style Zone', 'Quick Cuts', 'Classic Cuts', 'Modern Barber'];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          shopNames[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.bbColors.textPrimary,
                          ),
                        ),
                        Text(
                          '₹${revenue}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: BBColors.brandPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: context.bbColors.bgElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: BBColors.brandPrimary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TopServicesSection extends StatelessWidget {
  const _TopServicesSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bbColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.bbColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: List.generate(5, (index) {
              final services = ['Haircut', 'Beard Trim', 'Fade', 'Hair Color', 'Shave'];
              final counts = [1200, 850, 650, 420, 380];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(
                      '${index + 1}.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.bbColors.textDisabled,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        services[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.bbColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${counts[index]} bookings',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BBColors.brandPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
