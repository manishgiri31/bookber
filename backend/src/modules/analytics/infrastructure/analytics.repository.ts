import { prisma } from "../../../shared/prisma/client.js";
import type { DailyAnalytic } from "../domain/analytics.types.js";

export class AnalyticsRepository {
  async upsertDaily(data: DailyAnalytic): Promise<void> {
    await prisma.shopAnalyticDaily.upsert({
      where: { shopId_date: { shopId: data.shopId, date: data.date } },
      create: data,
      update: {
        totalBookings: data.totalBookings,
        totalWalkIns: data.totalWalkIns,
        completedBookings: data.completedBookings,
        cancelledBookings: data.cancelledBookings,
        noShows: data.noShows,
        avgWaitMinutes: data.avgWaitMinutes,
        avgServiceMinutes: data.avgServiceMinutes,
        totalRevenue: data.totalRevenue,
        peakHour: data.peakHour,
        chairUtilizationPct: data.chairUtilizationPct,
        queueAbandonments: data.queueAbandonments,
      },
    });
  }

  async getDailyRange(shopId: string, from: Date, to: Date) {
    return prisma.shopAnalyticDaily.findMany({
      where: { shopId, date: { gte: from, lte: to } },
      orderBy: { date: "asc" },
    });
  }

  async getActiveShopIds(): Promise<string[]> {
    const shops = await prisma.shop.findMany({
      where: { isActive: true },
      select: { id: true },
    });
    return shops.map((s) => s.id);
  }

  async getBookingsForDay(shopId: string, dayStart: Date, dayEnd: Date) {
    return prisma.booking.findMany({
      where: {
        shopId,
        createdAt: { gte: dayStart, lt: dayEnd },
      },
      include: {
        queueEntry: { select: { estimatedWaitMinutes: true, createdAt: true } },
        chairAllocations: {
          select: { allocatedAt: true, releasedAt: true, activeServiceStart: true, activeServiceEnd: true },
        },
        payment: { select: { amount: true, status: true } },
        chair: { select: { id: true, number: true } },
        barber: { select: { id: true, user: { select: { fullName: true } } } },
      },
    });
  }

  async getChairCountForShop(shopId: string): Promise<number> {
    return prisma.chair.count({ where: { shopId, status: { not: "BLOCKED" } } });
  }

  async getWeeklyInsights(shopId: string, weekStart: Date, weekEnd: Date) {
    return prisma.shopAnalyticDaily.findMany({
      where: { shopId, date: { gte: weekStart, lte: weekEnd } },
      orderBy: { date: "asc" },
    });
  }

  async getPreviousWeekInsights(shopId: string, prevWeekStart: Date, prevWeekEnd: Date) {
    return prisma.shopAnalyticDaily.findMany({
      where: { shopId, date: { gte: prevWeekStart, lte: prevWeekEnd } },
    });
  }

  async getBarberStats(shopId: string, from: Date, to: Date) {
    return prisma.waitTimeMetric.findMany({
      where: {
        shopId,
        recordedAt: { gte: from, lte: to },
      },
      include: {
        barber: { select: { id: true, user: { select: { fullName: true } } } },
      },
    });
  }
}
