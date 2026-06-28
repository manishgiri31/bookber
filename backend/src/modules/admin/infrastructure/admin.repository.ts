import { prisma } from "../../../shared/prisma/client.js";
import { Prisma } from "@prisma/client";
import type {
  AnalyticsOverview,
  BookingAnalytics,
  EarningsOverview,
  BarberModeration,
  Report,
  FraudDetectionAlert,
  ActiveQueueMonitoring,
  PaginationResult
} from "../domain/admin.types.js";

export class PrismaAdminRepository {
  async getAnalyticsOverview(fromDate?: Date, toDate?: Date): Promise<AnalyticsOverview> {
    const dateFilter = this.buildDateFilter(fromDate, toDate);

    const [
      totalUsers,
      totalBarbers,
      totalShops,
      totalBookings,
      activeBookings,
      completedBookings,
      cancelledBookings,
      totalRevenue,
      averageRating,
      totalReviews
    ] = await Promise.all([
      prisma.user.count({ where: { role: "CLIENT" } }),
      prisma.user.count({ where: { role: "BARBER" } }),
      prisma.shop.count({ where: { isActive: true } }),
      prisma.booking.count({ where: dateFilter }),
      prisma.booking.count({ where: { ...dateFilter, status: { in: ["QUEUED", "READY", "CALLED", "IN_SERVICE"] } } }),
      prisma.booking.count({ where: { ...dateFilter, status: "COMPLETED" } }),
      prisma.booking.count({ where: { ...dateFilter, status: { in: ["CANCELLED", "NO_SHOW"] } } }),
      this.getTotalRevenue(fromDate, toDate),
      this.getAverageRating(),
      prisma.review.count()
    ]);

    return {
      totalUsers,
      totalBarbers,
      totalShops,
      totalBookings,
      totalRevenue,
      activeBookings,
      completedBookings,
      cancelledBookings,
      averageRating,
      totalReviews
    };
  }

  async getBookingAnalytics(fromDate?: Date, toDate?: Date, shopId?: string): Promise<BookingAnalytics> {
    const dateFilter = this.buildDateFilter(fromDate, toDate);
    const shopFilter = shopId ? { shopId } : {};

    const bookingsByStatus = await prisma.booking.groupBy({
      by: ["status"],
      where: { ...dateFilter, ...shopFilter },
      _count: true
    });

    const bookingsByDay = await prisma.$queryRaw<Array<{ date: string; count: number }>>`
      SELECT
        DATE("createdAt") as date,
        COUNT(*) as count
      FROM "Booking"
      WHERE TRUE
        ${fromDate ? Prisma.sql`AND "createdAt" >= ${fromDate}` : Prisma.empty}
        ${toDate ? Prisma.sql`AND "createdAt" <= ${toDate}` : Prisma.empty}
        ${shopId ? Prisma.sql`AND "shopId" = ${shopId}` : Prisma.empty}
      GROUP BY DATE("createdAt")
      ORDER BY date DESC
      LIMIT 30
    `;

    const bookingsByHour = await prisma.$queryRaw<Array<{ hour: number; count: number }>>`
      SELECT
        EXTRACT(HOUR FROM "createdAt") as hour,
        COUNT(*) as count
      FROM "Booking"
      WHERE TRUE
        ${fromDate ? Prisma.sql`AND "createdAt" >= ${fromDate}` : Prisma.empty}
        ${toDate ? Prisma.sql`AND "createdAt" <= ${toDate}` : Prisma.empty}
        ${shopId ? Prisma.sql`AND "shopId" = ${shopId}` : Prisma.empty}
      GROUP BY EXTRACT(HOUR FROM "createdAt")
      ORDER BY hour
    `;

    const averageServiceDuration = await this.getAverageServiceDuration(shopId);

    const totalBookings = await prisma.booking.count({ where: { ...dateFilter, ...shopFilter } });
    const cancellationRate = totalBookings > 0 ? (await prisma.booking.count({ where: { ...dateFilter, ...shopFilter, status: { in: ["CANCELLED", "NO_SHOW"] } } })) / totalBookings : 0;
    const noShowRate = totalBookings > 0 ? (await prisma.booking.count({ where: { ...dateFilter, ...shopFilter, status: "NO_SHOW" } })) / totalBookings : 0;

    const topServices = await prisma.$queryRaw<Array<{ serviceId: string; serviceName: string; count: number; revenue: number }>>`
      SELECT
        s.id as "serviceId",
        s.name as "serviceName",
        COUNT(b.id) as count,
        COALESCE(SUM(p.amount), 0) as revenue
      FROM "Booking" b
      LEFT JOIN "Service" s ON s.id = b."serviceId"
      LEFT JOIN "Payment" p ON p."bookingId" = b.id
      WHERE TRUE
        ${fromDate ? Prisma.sql`AND b."createdAt" >= ${fromDate}` : Prisma.empty}
        ${toDate ? Prisma.sql`AND b."createdAt" <= ${toDate}` : Prisma.empty}
        ${shopId ? Prisma.sql`AND b."shopId" = ${shopId}` : Prisma.empty}
      GROUP BY s.id, s.name
      ORDER BY count DESC
      LIMIT 10
    `;

    const topShops = await prisma.$queryRaw<Array<{ shopId: string; shopName: string; count: number; revenue: number }>>`
      SELECT
        s.id as "shopId",
        s.name as "shopName",
        COUNT(b.id) as count,
        COALESCE(SUM(p.amount), 0) as revenue
      FROM "Booking" b
      INNER JOIN "Shop" s ON s.id = b."shopId"
      LEFT JOIN "Payment" p ON p."bookingId" = b.id
      WHERE TRUE
        ${fromDate ? Prisma.sql`AND b."createdAt" >= ${fromDate}` : Prisma.empty}
        ${toDate ? Prisma.sql`AND b."createdAt" <= ${toDate}` : Prisma.empty}
      GROUP BY s.id, s.name
      ORDER BY count DESC
      LIMIT 10
    `;

    return {
      totalBookings,
      bookingsByStatus: Object.fromEntries(bookingsByStatus.map(b => [b.status, b._count])),
      bookingsByDay: bookingsByDay.map(b => ({ date: String(b.date), count: Number(b.count) })),
      bookingsByHour: bookingsByHour.map(b => ({ hour: Number(b.hour), count: Number(b.count) })),
      averageServiceDuration,
      cancellationRate,
      noShowRate,
      topServices: topServices.map(s => ({ serviceId: s.serviceId, serviceName: s.serviceName, count: Number(s.count), revenue: Number(s.revenue) })),
      topShops: topShops.map(s => ({ shopId: s.shopId, shopName: s.shopName, count: Number(s.count), revenue: Number(s.revenue) }))
    };
  }

  async getEarningsOverview(fromDate?: Date, toDate?: Date): Promise<EarningsOverview> {
    const dateFilter = this.buildDateFilter(fromDate, toDate);

    const totalRevenue = await this.getTotalRevenue(fromDate, toDate);

    const revenueByPeriod = await prisma.$queryRaw<Array<{ period: string; revenue: number }>>`
      SELECT
        DATE_TRUNC('day', p."createdAt") as period,
        COALESCE(SUM(p.amount), 0) as revenue
      FROM "Payment" p
      WHERE p.status = 'PAID'
        ${fromDate ? Prisma.sql`AND p."createdAt" >= ${fromDate}` : Prisma.empty}
        ${toDate ? Prisma.sql`AND p."createdAt" <= ${toDate}` : Prisma.empty}
      GROUP BY DATE_TRUNC('day', p."createdAt")
      ORDER BY period DESC
      LIMIT 30
    `;

    const revenueByPaymentMethod = await prisma.payment.groupBy({
      by: ["method"],
      where: { status: "PAID", ...dateFilter },
      _sum: { amount: true }
    });

    const revenueByShop = await prisma.$queryRaw<Array<{ shopId: string; shopName: string; revenue: number; commission: number }>>`
      SELECT
        s.id as "shopId",
        s.name as "shopName",
        COALESCE(SUM(p.amount), 0) as revenue,
        COALESCE(SUM(p.amount) * 0.1, 0) as commission
      FROM "Payment" p
      INNER JOIN "Booking" b ON b.id = p."bookingId"
      INNER JOIN "Shop" s ON s.id = b."shopId"
      WHERE p.status = 'PAID'
        ${fromDate ? Prisma.sql`AND p."createdAt" >= ${fromDate}` : Prisma.empty}
        ${toDate ? Prisma.sql`AND p."createdAt" <= ${toDate}` : Prisma.empty}
      GROUP BY s.id, s.name
      ORDER BY revenue DESC
    `;

    const pendingPayouts = await prisma.$queryRaw<Array<{ count: bigint }>>`
      SELECT COUNT(*) as count
      FROM "Payment"
      WHERE status = 'PAID' AND "completedAt" IS NULL
    `;
    const completedPayouts = await prisma.$queryRaw<Array<{ count: bigint }>>`
      SELECT COUNT(*) as count
      FROM "Payment"
      WHERE status = 'PAID' AND "completedAt" IS NOT NULL
    `;
    const averageOrderValue = await prisma.payment.aggregate({
      where: { status: "PAID", ...dateFilter },
      _avg: { amount: true }
    });

    return {
      totalRevenue,
      revenueByPeriod: revenueByPeriod.map(r => ({ period: String(r.period), revenue: Number(r.revenue) })),
      revenueByPaymentMethod: Object.fromEntries(revenueByPaymentMethod.map(r => [r.method, Number(r._sum.amount)])),
      revenueByShop: revenueByShop.map(r => ({ shopId: r.shopId, shopName: r.shopName, revenue: Number(r.revenue), commission: Number(r.commission) })),
      pendingPayouts: Number(pendingPayouts[0]?.count || 0),
      completedPayouts: Number(completedPayouts[0]?.count || 0),
      averageOrderValue: averageOrderValue._avg.amount || 0
    };
  }

  async getBarberModerationList(status?: string, shopId?: string, flaggedOnly?: boolean, limit: number = 20, offset: number = 0): Promise<PaginationResult<BarberModeration>> {
    const where: any = { role: "BARBER" };
    if (shopId) {
      where.barber = { shopId };
    }

    const barbers = await prisma.user.findMany({
      where,
      include: {
        barber: {
          include: {
            shop: true
          }
        },
        bookings: {
          where: { status: "COMPLETED" },
          select: { id: true }
        }
      },
      take: limit,
      skip: offset
    });

    const total = await prisma.user.count({ where });

    const barberData: BarberModeration[] = barbers.map(barber => ({
      barberId: barber.id,
      barberName: barber.fullName,
      email: barber.email,
      phoneNumber: barber.phoneNumber || "",
      shopId: barber.barber?.shopId || "",
      shopName: barber.barber?.shop?.name || "",
      status: "ACTIVE",
      totalBookings: barber.bookings.length,
      completedBookings: barber.bookings.length,
      cancelledBookings: 0,
      averageRating: 0,
      totalRevenue: 0,
      flaggedForReview: false,
      lastActiveAt: barber.createdAt,
      createdAt: barber.createdAt
    }));

    return {
      data: barberData,
      total,
      limit,
      offset,
      hasMore: (offset + limit) < total
    };
  }

  async getActiveQueueMonitoring(): Promise<ActiveQueueMonitoring[]> {
    const activeQueues = await prisma.$queryRaw<Array<{
      shopId: string;
      shopName: string;
      totalQueued: number;
      averageWaitTime: number;
      longestWaitTime: number;
      activeBarbers: number;
      availableChairs: number;
      lastUpdated: Date;
    }>>`
      SELECT
        s.id as "shopId",
        s.name as "shopName",
        COUNT(qe.id) as "totalQueued",
        COALESCE(AVG(qe."estimatedWaitMinutes"), 0) as "averageWaitTime",
        COALESCE(MAX(qe."estimatedWaitMinutes"), 0) as "longestWaitTime",
        COUNT(DISTINCT b.id) as "activeBarbers",
        COUNT(DISTINCT CASE WHEN c.status = 'AVAILABLE' THEN c.id END) as "availableChairs",
        NOW() as "lastUpdated"
      FROM "Shop" s
      LEFT JOIN "QueueEntry" qe ON qe."shopId" = s.id
        AND qe."queueStatus" IN ('WAITING', 'READY')
      LEFT JOIN "Barber" b ON b."shopId" = s.id
      LEFT JOIN "Chair" c ON c."shopId" = s.id
      WHERE s."isActive" = true
      GROUP BY s.id, s.name
      HAVING COUNT(qe.id) > 0
      ORDER BY "totalQueued" DESC
    `;

    return activeQueues.map(q => ({
      shopId: q.shopId,
      shopName: q.shopName,
      totalQueued: Number(q.totalQueued),
      averageWaitTime: Number(q.averageWaitTime),
      longestWaitTime: Number(q.longestWaitTime),
      activeBarbers: Number(q.activeBarbers),
      availableChairs: Number(q.availableChairs),
      queueByBarber: [],
      lastUpdated: q.lastUpdated
    }));
  }

  private buildDateFilter(fromDate?: Date, toDate?: Date): any {
    const filter: any = {};
    if (fromDate) filter.createdAt = { ...filter.createdAt, gte: fromDate };
    if (toDate) filter.createdAt = { ...filter.createdAt, lte: toDate };
    return filter;
  }

  private async getTotalRevenue(fromDate?: Date, toDate?: Date): Promise<number> {
    const result = await prisma.payment.aggregate({
      where: { status: "PAID", ...this.buildDateFilter(fromDate, toDate) },
      _sum: { amount: true }
    });
    return result._sum.amount || 0;
  }

  private async getAverageRating(): Promise<number> {
    const result = await prisma.review.aggregate({
      _avg: { rating: true }
    });
    return result._avg.rating || 0;
  }

  private async getAverageServiceDuration(shopId?: string): Promise<number> {
    const aggregateArgs: any = { _avg: { durationMinutes: true } };
    if (shopId) {
      aggregateArgs.where = { shopId };
    }
    const result = await prisma.service.aggregate(aggregateArgs);
    return result._avg?.durationMinutes || 0;
  }
}
