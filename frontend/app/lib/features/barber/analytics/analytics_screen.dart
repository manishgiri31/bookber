import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/design/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_error_widget.dart';
import '../../../core/widgets/bb_loading.dart';
import '../dashboard/barber_provider.dart';
import 'analytics_provider.dart';

class BarberAnalyticsScreen extends ConsumerWidget {
  const BarberAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final dashState = ref.watch(barberDashProvider);
    final shopId = dashState.profile?.shopId;

    if (shopId == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          title: Text('Analytics',
              style: BBTypography.textTheme.titleLarge
                  ?.copyWith(color: colors.text, fontWeight: FontWeight.w700)),
        ),
        body: const BBSkeletonAnalytics(),
      );
    }

    final state = ref.watch(barberAnalyticsProvider(shopId));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Analytics',
          style: BBTypography.textTheme.titleLarge?.copyWith(
            color: colors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(AppIcons.refresh, color: colors.textSecondary),
            onPressed: () =>
                ref.read(barberAnalyticsProvider(shopId).notifier).refresh(),
          ),
        ],
      ),
      body: state.isLoading
          ? const BBSkeletonAnalytics()
          : state.error != null && state.daily == null
              ? BBErrorWidget(
                  error: state.error!,
                  onRetry: () =>
                      ref.read(barberAnalyticsProvider(shopId).notifier).refresh(),
                  fullScreen: true,
                )
              : RefreshIndicator(
                  color: BBColors.amber,
                  onRefresh: () =>
                      ref.read(barberAnalyticsProvider(shopId).notifier).refresh(),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BBSpacing.pageHorizontal,
                      vertical: BBSpacing.base,
                    ),
                    children: [
                      if (state.insights != null)
                        _WeeklyInsightsSection(insights: state.insights!),
                      if (state.daily != null) ...[
                        const SizedBox(height: BBSpacing.xl),
                        _TodayStatsSection(daily: state.daily!),
                      ],
                      if (state.peakHours != null) ...[
                        const SizedBox(height: BBSpacing.xl),
                        _PeakHoursSection(report: state.peakHours!),
                      ],
                      if (state.utilization != null) ...[
                        const SizedBox(height: BBSpacing.xl),
                        _UtilizationSection(report: state.utilization!),
                      ],
                      const SizedBox(height: BBSpacing.xl),
                      _RevenueChartSection(
                          weeklyRevenue: state.weeklyRevenue),
                      const SizedBox(height: BBSpacing.xl),
                      if (state.insights != null)
                        _WeeklyHighlightsSection(
                            insights: state.insights!),
                      const SizedBox(height: BBSpacing.xxl),
                    ],
                  ),
                ),
    );
  }
}

// ─── Weekly insights ─────────────────────────────────────────────────────────

class _WeeklyInsightsSection extends StatelessWidget {
  const _WeeklyInsightsSection({required this.insights});
  final WeeklyInsights insights;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('This Week'),
        const SizedBox(height: BBSpacing.md),
        Row(
          children: [
            Expanded(
              child: _InsightCard(
                label: 'Revenue',
                value: '₹${insights.revenue.toStringAsFixed(0)}',
                change: insights.revenueChange,
                icon: AppIcons.currencyRupee,
                color: BBColors.success,
              ),
            ),
            const SizedBox(width: BBSpacing.sm),
            Expanded(
              child: _InsightCard(
                label: 'Bookings',
                value: '${insights.totalBookings}',
                change: insights.bookingsChange,
                icon: AppIcons.calendar,
                color: BBColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: BBSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _InsightCard(
                label: 'Avg Wait',
                value: '${insights.avgWaitMinutes.toStringAsFixed(0)}m',
                change: -insights.waitChange,
                icon: AppIcons.timer,
                color: BBColors.amber,
                invertChange: true,
              ),
            ),
            const SizedBox(width: BBSpacing.sm),
            Expanded(
              child: _InsightCard(
                label: 'No-show Rate',
                value: '${(insights.noShowRate * 100).toStringAsFixed(1)}%',
                change: null,
                icon: AppIcons.personOff,
                color: BBColors.warning,
              ),
            ),
          ],
        ),
        if (insights.peakDay != null) ...[
          const SizedBox(height: BBSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(BBSpacing.md),
            decoration: BoxDecoration(
              color: BBColors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(BBRadius.lg),
              border: Border.all(color: BBColors.amber.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(AppIcons.starFill, size: 16, color: BBColors.amber),
                const SizedBox(width: BBSpacing.sm),
                Text(
                  'Busiest day: ${insights.peakDay}',
                  style: BBTypography.textTheme.labelMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (insights.lowUtilizationAlerts.isNotEmpty) ...[
          const SizedBox(height: BBSpacing.sm),
          ...insights.lowUtilizationAlerts.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: BBSpacing.xs),
              child: Container(
                padding: const EdgeInsets.all(BBSpacing.md),
                decoration: BoxDecoration(
                  color: BBColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(BBRadius.lg),
                  border:
                      Border.all(color: BBColors.warning.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(AppIcons.warning,
                        size: 16, color: BBColors.warning),
                    const SizedBox(width: BBSpacing.sm),
                    Expanded(
                      child: Text(
                        alert,
                        style: BBTypography.textTheme.labelSmall?.copyWith(
                          color: colors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.label,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
    this.invertChange = false,
  });

  final String label;
  final String value;
  final double? change;
  final IconData icon;
  final Color color;
  final bool invertChange;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final isPositive = (change ?? 0) >= 0;
    final effectivePositive = invertChange ? !isPositive : isPositive;
    final changeColor =
        change == null ? null : (effectivePositive ? BBColors.success : BBColors.error);

    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 16, color: color),
              if (change != null && change != 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      effectivePositive
                          ? AppIcons.arrowUpLarge
                          : AppIcons.arrowDownLarge,
                      size: 12,
                      color: changeColor,
                    ),
                    Text(
                      '${(change!.abs() * 100).toStringAsFixed(0)}%',
                      style: BBTypography.textTheme.labelSmall?.copyWith(
                        color: changeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: BBSpacing.sm),
          Text(
            value,
            style: BBTypography.textTheme.headlineSmall?.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: BBTypography.textTheme.labelSmall?.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Today stats ─────────────────────────────────────────────────────────────

class _TodayStatsSection extends StatelessWidget {
  const _TodayStatsSection({required this.daily});
  final DailyAnalytics daily;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Today'),
        const SizedBox(height: BBSpacing.md),
        Row(
          children: [
            _MiniStat(
              label: 'Total',
              value: '${daily.totalBookings}',
              color: colors.text,
            ),
            const SizedBox(width: BBSpacing.sm),
            _MiniStat(
              label: 'Done',
              value: '${daily.completedBookings}',
              color: BBColors.success,
            ),
            const SizedBox(width: BBSpacing.sm),
            _MiniStat(
              label: 'No-show',
              value: '${daily.noShows}',
              color: BBColors.error,
            ),
            const SizedBox(width: BBSpacing.sm),
            _MiniStat(
              label: 'Revenue',
              value: '₹${daily.totalRevenue.toStringAsFixed(0)}',
              color: BBColors.amber,
            ),
          ],
        ),
        const SizedBox(height: BBSpacing.md),
        Container(
          padding: const EdgeInsets.all(BBSpacing.base),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BBRadius.lg),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chair Utilization',
                style: BBTypography.textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: BBSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(BBRadius.full),
                      child: LinearProgressIndicator(
                        value: daily.chairUtilizationPct.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor:
                            BBColors.amber.withValues(alpha: 0.15),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(BBColors.amber),
                      ),
                    ),
                  ),
                  const SizedBox(width: BBSpacing.md),
                  Text(
                    '${(daily.chairUtilizationPct * 100).toStringAsFixed(0)}%',
                    style: BBTypography.textTheme.labelMedium?.copyWith(
                      color: BBColors.amber,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (daily.peakHour != null) ...[
                const SizedBox(height: BBSpacing.sm),
                Text(
                  'Peak hour today: ${_hourLabel(daily.peakHour!)}',
                  style: BBTypography.textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _hourLabel(int h) {
    final suffix = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:00 $suffix';
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: BBSpacing.sm,
          horizontal: BBSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(BBRadius.md),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: BBTypography.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: BBTypography.textTheme.labelSmall?.copyWith(
                color: colors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Peak hours bar chart ─────────────────────────────────────────────────────

class _PeakHoursSection extends StatelessWidget {
  const _PeakHoursSection({required this.report});
  final PeakHourReport report;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    // Show hours 7-22 only
    final buckets = report.byHour.where((b) => b.hour >= 7 && b.hour <= 22).toList()
      ..sort((a, b) => a.hour.compareTo(b.hour));

    final maxCount =
        buckets.fold<int>(1, (m, b) => math.max(m, b.bookingCount));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Peak Hours (last 7 days)'),
        const SizedBox(height: BBSpacing.md),
        Container(
          height: 180,
          padding: const EdgeInsets.all(BBSpacing.base),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BBRadius.lg),
            border: Border.all(color: colors.border),
          ),
          child: buckets.isEmpty
              ? Center(
                  child: Text(
                    'No data yet',
                    style: BBTypography.textTheme.bodySmall
                        ?.copyWith(color: colors.textTertiary),
                  ),
                )
              : BarChart(
                  BarChartData(
                    maxY: (maxCount + 1).toDouble(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: colors.border,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 20,
                          getTitlesWidget: (value, _) {
                            final h = value.toInt();
                            if (h % 3 != 0) return const SizedBox.shrink();
                            return Text(
                              '${h}h',
                              style: BBTypography.textTheme.labelSmall
                                  ?.copyWith(
                                      color: colors.textTertiary, fontSize: 9),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: buckets.map((b) {
                      final isPeak = b.hour == report.peakHour;
                      return BarChartGroupData(
                        x: b.hour,
                        barRods: [
                          BarChartRodData(
                            toY: b.bookingCount.toDouble(),
                            color: isPeak
                                ? BBColors.amber
                                : BBColors.amber.withValues(alpha: 0.35),
                            width: 8,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
        if (report.peakHour != null) ...[
          const SizedBox(height: BBSpacing.sm),
          Text(
            'Peak: ${_hourLabel(report.peakHour!)}${report.slowestHour != null ? '  ·  Slowest: ${_hourLabel(report.slowestHour!)}' : ''}',
            style: BBTypography.textTheme.labelSmall?.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  String _hourLabel(int h) {
    final suffix = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:00 $suffix';
  }
}

// ─── Utilization section ─────────────────────────────────────────────────────

class _UtilizationSection extends StatelessWidget {
  const _UtilizationSection({required this.report});
  final UtilizationReport report;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Barber Utilization'),
        const SizedBox(height: BBSpacing.md),
        Container(
          padding: const EdgeInsets.all(BBSpacing.base),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BBRadius.lg),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall chair utilization',
                    style: BBTypography.textTheme.labelMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    '${(report.overallChairPct * 100).toStringAsFixed(0)}%',
                    style: BBTypography.textTheme.labelMedium?.copyWith(
                      color: BBColors.amber,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BBSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(BBRadius.full),
                child: LinearProgressIndicator(
                  value: report.overallChairPct.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: BBColors.amber.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(BBColors.amber),
                ),
              ),
              if (report.barbers.isNotEmpty) ...[
                const SizedBox(height: BBSpacing.base),
                const Divider(height: 1),
                const SizedBox(height: BBSpacing.base),
                ...report.barbers.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: BBSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                b.barberName,
                                style: BBTypography.textTheme.labelMedium
                                    ?.copyWith(color: colors.text),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${b.servicesCount} services · ${(b.utilizationPct * 100).toStringAsFixed(0)}%',
                              style: BBTypography.textTheme.labelSmall
                                  ?.copyWith(color: colors.textTertiary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(BBRadius.full),
                          child: LinearProgressIndicator(
                            value: b.utilizationPct.clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor:
                                colors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              b.utilizationPct < 0.2
                                  ? BBColors.warning
                                  : BBColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Revenue Line Chart ───────────────────────────────────────────────────────

class _RevenueChartSection extends StatelessWidget {
  const _RevenueChartSection({required this.weeklyRevenue});

  final List<({String label, double revenue})> weeklyRevenue;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    if (weeklyRevenue.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('7-Day Revenue'),
          const SizedBox(height: BBSpacing.md),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(BBRadius.lg),
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: Text('No revenue data yet',
                  style: BBTypography.textTheme.bodySmall
                      ?.copyWith(color: colors.textTertiary)),
            ),
          ),
        ],
      );
    }

    final values = weeklyRevenue.map((e) => e.revenue).toList();
    final maxY = values.reduce(math.max) * 1.2;
    final effectiveMaxY = maxY < 100 ? 100.0 : maxY;
    final spots = values.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('7-Day Revenue'),
        const SizedBox(height: BBSpacing.md),
        Container(
          height: 180,
          padding: const EdgeInsets.fromLTRB(
              BBSpacing.sm, BBSpacing.base, BBSpacing.base, BBSpacing.base),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BBRadius.lg),
            border: Border.all(color: colors.border),
          ),
          child: LineChart(
            LineChartData(
              maxY: effectiveMaxY,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: colors.border,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= weeklyRevenue.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        weeklyRevenue[i].label,
                        style: BBTypography.textTheme.labelSmall?.copyWith(
                          color: colors.textTertiary,
                          fontSize: 9,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => colors.surfaceVariant,
                  getTooltipItems: (spots) => spots.map((s) {
                    return LineTooltipItem(
                      '₹${s.y.toStringAsFixed(0)}',
                      BBTypography.textTheme.labelSmall!.copyWith(
                        color: BBColors.amber,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: BBColors.amber,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (s, _, p, i) => FlDotCirclePainter(
                      radius: 3,
                      color: BBColors.amber,
                      strokeWidth: 1.5,
                      strokeColor: colors.surface,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        BBColors.amber.withValues(alpha: 0.15),
                        BBColors.amber.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Weekly Highlights ────────────────────────────────────────────────────────

class _WeeklyHighlightsSection extends StatelessWidget {
  const _WeeklyHighlightsSection({required this.insights});
  final WeeklyInsights insights;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    final items = [
      (
        label: 'Walk-ins',
        value: '${insights.walkIns}',
        icon: AppIcons.walk,
        color: BBColors.info,
      ),
      (
        label: 'Avg Wait',
        value: '${insights.avgWaitMinutes.toStringAsFixed(0)}m',
        icon: AppIcons.timer,
        color: BBColors.amber,
      ),
      (
        label: 'No-shows',
        value: '${(insights.noShowRate * insights.totalBookings).round()}',
        icon: AppIcons.personOff,
        color: BBColors.warning,
      ),
      (
        label: 'Abandoned',
        value:
            '${(insights.queueAbandonmentRate * 100).toStringAsFixed(0)}%',
        icon: AppIcons.removeCircle,
        color: BBColors.error,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Weekly Highlights'),
        const SizedBox(height: BBSpacing.md),
        Container(
          padding: const EdgeInsets.all(BBSpacing.base),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BBRadius.lg),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final item = e.value;
              return Padding(
                padding: EdgeInsets.only(
                    bottom: e.key < items.length - 1 ? BBSpacing.md : 0),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(BBRadius.md),
                      ),
                      child: Icon(item.icon, size: 16, color: item.color),
                    ),
                    const SizedBox(width: BBSpacing.md),
                    Expanded(
                      child: Text(
                        item.label,
                        style: BBTypography.textTheme.labelMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      item.value,
                      style: BBTypography.textTheme.titleMedium?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Text(
      title,
      style: BBTypography.textTheme.titleLarge?.copyWith(
        color: colors.text,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
