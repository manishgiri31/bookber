import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/providers/providers.dart';

// ─── Daily analytics ─────────────────────────────────────────────────────────

class DailyAnalytics {
  const DailyAnalytics({
    required this.totalBookings,
    required this.totalWalkIns,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.noShows,
    required this.avgWaitMinutes,
    required this.avgServiceMinutes,
    required this.totalRevenue,
    this.peakHour,
    required this.chairUtilizationPct,
    required this.queueAbandonments,
  });

  final int totalBookings;
  final int totalWalkIns;
  final int completedBookings;
  final int cancelledBookings;
  final int noShows;
  final double avgWaitMinutes;
  final double avgServiceMinutes;
  final double totalRevenue;
  final int? peakHour;
  final double chairUtilizationPct;
  final int queueAbandonments;

  factory DailyAnalytics.fromJson(Map<String, dynamic> j) => DailyAnalytics(
        totalBookings: _i(j['totalBookings']),
        totalWalkIns: _i(j['totalWalkIns']),
        completedBookings: _i(j['completedBookings']),
        cancelledBookings: _i(j['cancelledBookings']),
        noShows: _i(j['noShows']),
        avgWaitMinutes: _d(j['avgWaitMinutes']),
        avgServiceMinutes: _d(j['avgServiceMinutes']),
        totalRevenue: _d(j['totalRevenue']),
        peakHour: j['peakHour'] as int?,
        chairUtilizationPct: _d(j['chairUtilizationPct']),
        queueAbandonments: _i(j['queueAbandonments']),
      );

  static int _i(dynamic v) => (v as num?)?.toInt() ?? 0;
  static double _d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
}

// ─── Peak hours ──────────────────────────────────────────────────────────────

class HourlyBucket {
  const HourlyBucket({
    required this.hour,
    required this.bookingCount,
    required this.walkInCount,
    required this.avgWaitMinutes,
  });

  final int hour;
  final int bookingCount;
  final int walkInCount;
  final double avgWaitMinutes;

  factory HourlyBucket.fromJson(Map<String, dynamic> j) => HourlyBucket(
        hour: (j['hour'] as num?)?.toInt() ?? 0,
        bookingCount: (j['bookingCount'] as num?)?.toInt() ?? 0,
        walkInCount: (j['walkInCount'] as num?)?.toInt() ?? 0,
        avgWaitMinutes: (j['avgWaitMinutes'] as num?)?.toDouble() ?? 0.0,
      );
}

class PeakHourReport {
  const PeakHourReport({required this.byHour, this.peakHour, this.slowestHour});
  final List<HourlyBucket> byHour;
  final int? peakHour;
  final int? slowestHour;

  factory PeakHourReport.fromJson(Map<String, dynamic> j) => PeakHourReport(
        byHour: (j['byHour'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(HourlyBucket.fromJson)
            .toList(),
        peakHour: j['peakHour'] as int?,
        slowestHour: j['slowestHour'] as int?,
      );
}

// ─── Utilization ─────────────────────────────────────────────────────────────

class BarberUtilization {
  const BarberUtilization({
    required this.barberName,
    required this.utilizationPct,
    required this.servicesCount,
    required this.avgServiceMinutes,
  });

  final String barberName;
  final double utilizationPct;
  final int servicesCount;
  final double avgServiceMinutes;

  factory BarberUtilization.fromJson(Map<String, dynamic> j) =>
      BarberUtilization(
        barberName: j['barberName']?.toString() ?? '',
        utilizationPct: (j['utilizationPct'] as num?)?.toDouble() ?? 0.0,
        servicesCount: (j['servicesCount'] as num?)?.toInt() ?? 0,
        avgServiceMinutes: (j['avgServiceMinutes'] as num?)?.toDouble() ?? 0.0,
      );
}

class UtilizationReport {
  const UtilizationReport({
    required this.overallChairPct,
    required this.barbers,
  });

  final double overallChairPct;
  final List<BarberUtilization> barbers;

  factory UtilizationReport.fromJson(Map<String, dynamic> j) =>
      UtilizationReport(
        overallChairPct: (j['overallChairPct'] as num?)?.toDouble() ?? 0.0,
        barbers: (j['barbers'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(BarberUtilization.fromJson)
            .toList(),
      );
}

// ─── Weekly insights ─────────────────────────────────────────────────────────

class WeeklyInsights {
  const WeeklyInsights({
    required this.revenue,
    required this.revenueChange,
    required this.totalBookings,
    required this.bookingsChange,
    required this.walkIns,
    required this.avgWaitMinutes,
    required this.waitChange,
    required this.noShowRate,
    required this.queueAbandonmentRate,
    this.peakDay,
    required this.lowUtilizationAlerts,
  });

  final double revenue;
  final double revenueChange;
  final int totalBookings;
  final double bookingsChange;
  final int walkIns;
  final double avgWaitMinutes;
  final double waitChange;
  final double noShowRate;
  final double queueAbandonmentRate;
  final String? peakDay;
  final List<String> lowUtilizationAlerts;

  factory WeeklyInsights.fromJson(Map<String, dynamic> j) => WeeklyInsights(
        revenue: (j['revenue'] as num?)?.toDouble() ?? 0.0,
        revenueChange: (j['revenueChange'] as num?)?.toDouble() ?? 0.0,
        totalBookings: (j['totalBookings'] as num?)?.toInt() ?? 0,
        bookingsChange: (j['bookingsChange'] as num?)?.toDouble() ?? 0.0,
        walkIns: (j['walkIns'] as num?)?.toInt() ?? 0,
        avgWaitMinutes: (j['avgWaitMinutes'] as num?)?.toDouble() ?? 0.0,
        waitChange: (j['waitChange'] as num?)?.toDouble() ?? 0.0,
        noShowRate: (j['noShowRate'] as num?)?.toDouble() ?? 0.0,
        queueAbandonmentRate:
            (j['queueAbandonmentRate'] as num?)?.toDouble() ?? 0.0,
        peakDay: j['peakDay']?.toString(),
        lowUtilizationAlerts: (j['lowUtilizationAlerts'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((a) => a['message']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList(),
      );
}

// ─── Analytics state ─────────────────────────────────────────────────────────

class AnalyticsState {
  const AnalyticsState({
    this.daily,
    this.peakHours,
    this.utilization,
    this.insights,
    this.weeklyRevenue = const [],
    this.isLoading = false,
    this.error,
  });

  final DailyAnalytics? daily;
  final PeakHourReport? peakHours;
  final UtilizationReport? utilization;
  final WeeklyInsights? insights;
  final List<({String label, double revenue})> weeklyRevenue;
  final bool isLoading;
  final String? error;

  AnalyticsState copyWith({
    DailyAnalytics? daily,
    PeakHourReport? peakHours,
    UtilizationReport? utilization,
    WeeklyInsights? insights,
    List<({String label, double revenue})>? weeklyRevenue,
    bool? isLoading,
    String? error,
  }) =>
      AnalyticsState(
        daily: daily ?? this.daily,
        peakHours: peakHours ?? this.peakHours,
        utilization: utilization ?? this.utilization,
        insights: insights ?? this.insights,
        weeklyRevenue: weeklyRevenue ?? this.weeklyRevenue,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class BarberAnalyticsNotifier
    extends AutoDisposeFamilyNotifier<AnalyticsState, String> {
  @override
  AnalyticsState build(String shopId) {
    _load(shopId);
    return const AnalyticsState(isLoading: true);
  }

  Future<void> _load(String shopId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiClientProvider);
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final rangeQ =
          '?from=${weekAgo.toIso8601String()}&to=${now.toIso8601String()}';

      // Fetch main analytics + 7 individual daily records in parallel
      const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dailyDateFutures = List.generate(7, (i) {
        final date = now.subtract(Duration(days: 6 - i));
        final iso = Uri.encodeComponent(date.toIso8601String());
        return api.get<Map<String, dynamic>>(
          '${ApiEndpoints.shopAnalytics(shopId, 'daily')}?date=$iso',
        );
      });

      final allResults = await Future.wait([
        api.get<Map<String, dynamic>>(
            ApiEndpoints.shopAnalytics(shopId, 'daily')),
        api.get<Map<String, dynamic>>(
            '${ApiEndpoints.shopAnalytics(shopId, 'peak-hours')}$rangeQ'),
        api.get<Map<String, dynamic>>(
            '${ApiEndpoints.shopAnalytics(shopId, 'utilization')}$rangeQ'),
        api.get<Map<String, dynamic>>(
            ApiEndpoints.shopAnalytics(shopId, 'insights')),
        ...dailyDateFutures,
      ]);

      final weeklyRevenue = List.generate(7, (i) {
        final date = now.subtract(Duration(days: 6 - i));
        final label = dayLabels[date.weekday - 1];
        final rev =
            (allResults[4 + i]['totalRevenue'] as num?)?.toDouble() ?? 0.0;
        return (label: label, revenue: rev);
      });

      state = AnalyticsState(
        daily: DailyAnalytics.fromJson(allResults[0]),
        peakHours: PeakHourReport.fromJson(allResults[1]),
        utilization: UtilizationReport.fromJson(allResults[2]),
        insights: WeeklyInsights.fromJson(allResults[3]),
        weeklyRevenue: weeklyRevenue,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load(arg);
}

final barberAnalyticsProvider = AutoDisposeNotifierProviderFamily<
    BarberAnalyticsNotifier, AnalyticsState, String>(
  BarberAnalyticsNotifier.new,
);
