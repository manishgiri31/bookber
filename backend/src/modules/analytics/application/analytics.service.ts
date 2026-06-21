import type { AnalyticsRepository } from "../infrastructure/analytics.repository.js";
import type {
  DailyAnalytic,
  HourlyBucket,
  PeakHourReport,
  UtilizationReport,
  WeeklyInsights,
  LowUtilizationAlert,
} from "../domain/analytics.types.js";
import { createModuleLogger } from "../../../infrastructure/logging/structured-logger.js";

const log = createModuleLogger("analytics-service");

const LOW_UTILIZATION_THRESHOLD = 0.2;

export class AnalyticsService {
  constructor(private readonly repo: AnalyticsRepository) {}

  async aggregateDay(shopId: string, date: Date): Promise<DailyAnalytic> {
    const dayStart = startOfDay(date);
    const dayEnd = endOfDay(date);

    const bookings = await this.repo.getBookingsForDay(shopId, dayStart, dayEnd);
    const totalChairs = await this.repo.getChairCountForShop(shopId);
    const shopOpenMinutes = 8 * 60;

    let completedBookings = 0;
    let cancelledBookings = 0;
    let noShows = 0;
    let totalWalkIns = 0;
    let totalRevenue = 0;
    let totalWaitMinutes = 0;
    let waitSamples = 0;
    let totalServiceMinutes = 0;
    let serviceSamples = 0;
    let queueAbandonments = 0;
    const hourCounts: Record<number, number> = {};

    for (const booking of bookings) {
      if (booking.walkIn) totalWalkIns++;

      switch (booking.status) {
        case "COMPLETED": {
          completedBookings++;
          if (booking.payment?.status === "PAID") {
            totalRevenue += booking.payment.amount;
          }
          if (booking.queueEntry?.estimatedWaitMinutes) {
            totalWaitMinutes += booking.queueEntry.estimatedWaitMinutes;
            waitSamples++;
          }
          const alloc = booking.chairAllocations[0];
          if (alloc?.activeServiceStart && alloc.activeServiceEnd) {
            const mins = (alloc.activeServiceEnd.getTime() - alloc.activeServiceStart.getTime()) / 60_000;
            if (mins > 0 && mins < 180) {
              totalServiceMinutes += mins;
              serviceSamples++;
            }
          }
          const hour = booking.createdAt.getHours();
          hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
          break;
        }
        case "NO_SHOW":
          noShows++;
          break;
        case "CANCELLED":
          cancelledBookings++;
          if (booking.status === "CANCELLED" && booking.queueEntry) {
            queueAbandonments++;
          }
          break;
      }
    }

    const peakHour = peakHourFrom(hourCounts);
    const avgWaitMinutes = waitSamples > 0 ? totalWaitMinutes / waitSamples : 0;
    const avgServiceMinutes = serviceSamples > 0 ? totalServiceMinutes / serviceSamples : 0;
    const chairUtilizationPct =
      totalChairs > 0 && shopOpenMinutes > 0
        ? Math.min(1, totalServiceMinutes / (totalChairs * shopOpenMinutes))
        : 0;

    return {
      shopId,
      date: dayStart,
      totalBookings: bookings.length,
      totalWalkIns,
      completedBookings,
      cancelledBookings,
      noShows,
      avgWaitMinutes: round2(avgWaitMinutes),
      avgServiceMinutes: round2(avgServiceMinutes),
      totalRevenue: round2(totalRevenue),
      peakHour,
      chairUtilizationPct: round2(chairUtilizationPct),
      queueAbandonments,
    };
  }

  async getPeakHours(shopId: string, from: Date, to: Date): Promise<PeakHourReport> {
    const rows = await this.repo.getDailyRange(shopId, from, to);
    const hourlyMap = new Map<number, { bookings: number; walkIns: number; waitSum: number; waitCount: number }>();

    for (let h = 0; h < 24; h++) {
      hourlyMap.set(h, { bookings: 0, walkIns: 0, waitSum: 0, waitCount: 0 });
    }

    for (const row of rows) {
      const hour = row.peakHour;
      if (hour != null) {
        const bucket = hourlyMap.get(hour)!;
        bucket.bookings += row.totalBookings;
        bucket.walkIns += row.totalWalkIns;
        if (row.avgWaitMinutes > 0) {
          bucket.waitSum += row.avgWaitMinutes;
          bucket.waitCount++;
        }
      }
    }

    const byHour: HourlyBucket[] = Array.from(hourlyMap.entries()).map(([hour, b]) => ({
      hour,
      bookingCount: b.bookings,
      walkInCount: b.walkIns,
      avgWaitMinutes: b.waitCount > 0 ? round2(b.waitSum / b.waitCount) : 0,
    }));

    const sorted = [...byHour].sort((a, b) => b.bookingCount - a.bookingCount);
    const first = sorted[0];
    const last = sorted[sorted.length - 1];
    const peakHour = first && first.bookingCount > 0 ? first.hour : null;
    const slowestHour = last && last.bookingCount > 0 ? last.hour : null;

    return { shopId, from, to, byHour, peakHour, slowestHour };
  }

  async getUtilization(shopId: string, from: Date, to: Date): Promise<UtilizationReport> {
    const rows = await this.repo.getDailyRange(shopId, from, to);
    const barberStats = await this.repo.getBarberStats(shopId, from, to);

    const totalDays = daysBetween(from, to) || 1;
    const totalChairs = await this.repo.getChairCountForShop(shopId);
    const shopOpenMinutesPerDay = 8 * 60;

    const totalAvailableMinutes = totalChairs * shopOpenMinutesPerDay * totalDays;
    const totalServiceMinutes = rows.reduce(
      (sum, r) => sum + r.avgServiceMinutes * r.completedBookings,
      0
    );
    const overallChairPct = totalAvailableMinutes > 0 ? totalServiceMinutes / totalAvailableMinutes : 0;

    // Barber utilization from wait_time_metrics
    const barberMap = new Map<string, { name: string; minutes: number; count: number }>();
    for (const m of barberStats) {
      const entry = barberMap.get(m.barberId) ?? {
        name: m.barber.user.fullName,
        minutes: 0,
        count: 0,
      };
      entry.minutes += m.actualMinutes;
      entry.count++;
      barberMap.set(m.barberId, entry);
    }

    const totalBarberAvailableMinutes = shopOpenMinutesPerDay * totalDays;
    const barbers = Array.from(barberMap.entries()).map(([barberId, b]) => ({
      barberId,
      barberName: b.name,
      utilizationPct: round2(b.minutes / totalBarberAvailableMinutes),
      totalServiceMinutes: b.minutes,
      servicesCount: b.count,
      avgServiceMinutes: b.count > 0 ? round2(b.minutes / b.count) : 0,
    }));

    return {
      shopId,
      from,
      to,
      chairs: [],
      barbers,
      overallChairPct: round2(overallChairPct),
    };
  }

  async getWeeklyInsights(shopId: string): Promise<WeeklyInsights> {
    const now = new Date();
    const weekStart = startOfWeek(now);
    const weekEnd = new Date(weekStart.getTime() + 7 * 86400_000);
    const prevWeekStart = new Date(weekStart.getTime() - 7 * 86400_000);
    const prevWeekEnd = weekStart;

    const [current, previous] = await Promise.all([
      this.repo.getWeeklyInsights(shopId, weekStart, weekEnd),
      this.repo.getPreviousWeekInsights(shopId, prevWeekStart, prevWeekEnd),
    ]);

    const sum = (rows: typeof current, field: keyof (typeof rows)[number]) =>
      rows.reduce((s, r) => s + (Number(r[field]) || 0), 0);

    const revenue = sum(current, "totalRevenue");
    const prevRevenue = sum(previous, "totalRevenue");
    const totalBookings = sum(current, "totalBookings") + sum(current, "totalWalkIns");
    const prevBookings = sum(previous, "totalBookings") + sum(previous, "totalWalkIns");
    const walkIns = sum(current, "totalWalkIns");
    const prevWalkIns = sum(previous, "totalWalkIns");
    const completed = sum(current, "completedBookings");
    const noShows = sum(current, "noShows");
    const abandonments = sum(current, "queueAbandonments");

    const avgWait =
      current.length > 0
        ? current.reduce((s, r) => s + r.avgWaitMinutes, 0) / current.length
        : 0;
    const prevAvgWait =
      previous.length > 0
        ? previous.reduce((s, r) => s + r.avgWaitMinutes, 0) / previous.length
        : 0;

    const peakDay = peakDayFrom(current);
    const abandonmentRate = completed + abandonments > 0 ? abandonments / (completed + abandonments) : 0;
    const prevAbandonment = sum(previous, "queueAbandonments");
    const prevCompleted = sum(previous, "completedBookings");
    const prevAbandonmentRate =
      prevCompleted + prevAbandonment > 0 ? prevAbandonment / (prevCompleted + prevAbandonment) : 0;

    const noShowRate = totalBookings > 0 ? noShows / totalBookings : 0;

    const utilizationReport = await this.getUtilization(shopId, weekStart, weekEnd);
    const lowUtilizationAlerts: LowUtilizationAlert[] = [];

    for (const barber of utilizationReport.barbers) {
      if (barber.utilizationPct < LOW_UTILIZATION_THRESHOLD) {
        lowUtilizationAlerts.push({
          entityType: "BARBER",
          entityId: barber.barberId,
          label: barber.barberName,
          utilizationPct: barber.utilizationPct,
          message: `${barber.barberName} was only ${Math.round(barber.utilizationPct * 100)}% utilized this week`,
        });
      }
    }

    return {
      shopId,
      weekStart,
      weekEnd,
      revenue: round2(revenue),
      revenueChange: prevRevenue > 0 ? round2((revenue - prevRevenue) / prevRevenue) : 0,
      totalBookings,
      bookingsChange: prevBookings > 0 ? round2((totalBookings - prevBookings) / prevBookings) : 0,
      walkIns,
      walkInsChange: prevWalkIns > 0 ? round2((walkIns - prevWalkIns) / prevWalkIns) : 0,
      avgWaitMinutes: round2(avgWait),
      waitChange: prevAvgWait > 0 ? round2((avgWait - prevAvgWait) / prevAvgWait) : 0,
      queueAbandonmentRate: round2(abandonmentRate),
      abandonmentChange: round2(abandonmentRate - prevAbandonmentRate),
      noShowRate: round2(noShowRate),
      peakDay,
      lowUtilizationAlerts,
    };
  }

  async runDailyAggregation(): Promise<{ shops: number; errors: number }> {
    const shopIds = await this.repo.getActiveShopIds();
    const yesterday = new Date(Date.now() - 86400_000);
    let errors = 0;

    for (const shopId of shopIds) {
      try {
        const analytic = await this.aggregateDay(shopId, yesterday);
        await this.repo.upsertDaily(analytic);
      } catch (err) {
        errors++;
        log.error({ err, shopId }, "daily aggregation failed for shop");
      }
    }

    log.info({ shops: shopIds.length, errors }, "daily analytics aggregation complete");
    return { shops: shopIds.length, errors };
  }
}

function startOfDay(d: Date): Date {
  const r = new Date(d);
  r.setHours(0, 0, 0, 0);
  return r;
}

function endOfDay(d: Date): Date {
  const r = new Date(d);
  r.setHours(23, 59, 59, 999);
  return r;
}

function startOfWeek(d: Date): Date {
  const r = new Date(d);
  const day = r.getDay();
  r.setDate(r.getDate() - day);
  r.setHours(0, 0, 0, 0);
  return r;
}

function peakHourFrom(hourCounts: Record<number, number>): number | null {
  let max = 0;
  let peak: number | null = null;
  for (const [hourStr, count] of Object.entries(hourCounts)) {
    if (count > max) {
      max = count;
      peak = Number(hourStr);
    }
  }
  return peak;
}

function peakDayFrom(rows: Array<{ date: Date; totalBookings: number; totalWalkIns: number }>): string | null {
  if (rows.length === 0) return null;
  const sorted = [...rows].sort(
    (a, b) => b.totalBookings + b.totalWalkIns - (a.totalBookings + a.totalWalkIns)
  );
  return sorted[0]!.date.toLocaleDateString("en-US", { weekday: "long" });
}

function daysBetween(from: Date, to: Date): number {
  return Math.max(1, Math.round((to.getTime() - from.getTime()) / 86400_000));
}

function round2(n: number): number {
  return Math.round(n * 100) / 100;
}
