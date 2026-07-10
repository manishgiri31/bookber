import { randomBytes } from "node:crypto";
import type { FastifyPluginAsync } from "fastify";
import { z } from "zod";
import { getAuthUser } from "../../auth/presentation/auth-user.js";

const queueStatusSchema = z.enum(["WAITING", "READY", "CALLED", "IN_SERVICE", "COMPLETED", "SKIPPED", "NO_SHOW", "CANCELLED"]);

export const barberRoutes: FastifyPluginAsync = async (app) => {
  // GET /api/barbers/me
  app.get("/barbers/me", { preHandler: app.authorizeRoles(["BARBER", "OWNER"]) }, async (request) => {
    let barber = await app.prisma.barber.findUnique({
      where: { userId: request.user.sub },
      include: {
        user: { select: { id: true, fullName: true, email: true, profileImage: true } },
        shop: { select: { id: true, name: true, address: true, city: true } }
      }
    });
    if (!barber) throw app.httpErrors.notFound("Barber profile not found");

    // Lazily generate a permanent, unguessable QR check-in token on first fetch
    if (!barber.checkInToken) {
      const token = randomBytes(20).toString("hex");
      barber = await app.prisma.barber.update({
        where: { id: barber.id },
        data: { checkInToken: token },
        include: {
          user: { select: { id: true, fullName: true, email: true, profileImage: true } },
          shop: { select: { id: true, name: true, address: true, city: true } }
        }
      });
    }

    return { barber };
  });

  // GET /api/barbers/:barberId/stats
  app.get("/barbers/:barberId/stats", { preHandler: app.authorizeRoles(["BARBER", "OWNER", "ADMIN"]) }, async (request) => {
    const { barberId } = request.params as { barberId: string };
    const barber = await app.prisma.barber.findUnique({ where: { id: barberId }, select: { shopId: true } });
    if (!barber) throw app.httpErrors.notFound("Barber not found");
    const today = new Date();
    const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const endOfDay = new Date(startOfDay.getTime() + 86400000);

    const startOfWeek = new Date(startOfDay.getTime() - startOfDay.getDay() * 86400000);

    const [todayBookings, activeQueue, completedToday, paidToday, paidThisWeek] = await Promise.all([
      app.prisma.booking.count({ where: { barberId, arrivalWindowStart: { gte: startOfDay, lt: endOfDay } } }),
      app.prisma.queueEntry.count({
        where: {
          shopId: barber.shopId,
          OR: [{ barberId }, { barberId: null }],
          queueStatus: { in: ["WAITING", "CALLED", "READY"] }
        }
      }),
      app.prisma.booking.count({ where: { barberId, status: "COMPLETED", updatedAt: { gte: startOfDay, lt: endOfDay } } }),
      app.prisma.payment.findMany({
        where: {
          status: "PAID",
          booking: { barberId, status: "COMPLETED", updatedAt: { gte: startOfDay, lt: endOfDay } }
        },
        select: { amount: true }
      }),
      app.prisma.payment.findMany({
        where: {
          status: "PAID",
          booking: { barberId, status: "COMPLETED", updatedAt: { gte: startOfWeek, lt: endOfDay } }
        },
        select: { amount: true }
      })
    ]);

    const revenueToday = paidToday.reduce((sum, p) => sum + p.amount, 0);
    const revenueWeek = paidThisWeek.reduce((sum, p) => sum + p.amount, 0);

    return {
      todayBookings,
      activeQueue,
      completedToday,
      revenueToday,
      revenueWeek,
      date: today.toISOString().split("T")[0]
    };
  });

  // GET /api/barbers/:barberId/queue
  app.get("/barbers/:barberId/queue", { preHandler: app.authorizeRoles(["BARBER", "OWNER", "ADMIN"]) }, async (request) => {
    const { barberId } = request.params as { barberId: string };
    const barber = await app.prisma.barber.findUnique({ where: { id: barberId }, select: { shopId: true } });
    if (!barber) throw app.httpErrors.notFound("Barber not found");
    // Include entries already assigned to this barber, plus unassigned shop-wide
    // entries (e.g. reception walk-ins) so any barber at the shop can pick them up.
    const entries = await app.prisma.queueEntry.findMany({
      where: {
        shopId: barber.shopId,
        OR: [{ barberId }, { barberId: null }],
        queueStatus: { in: ["WAITING", "CALLED", "READY", "IN_SERVICE"] }
      },
      orderBy: { position: "asc" },
      include: {
        booking: {
          include: {
            service: true,
            user: { select: { id: true, fullName: true } }
          }
        }
      }
    });
    return { queue: entries };
  });

  // GET /api/barbers/:barberId/bookings
  app.get("/barbers/:barberId/bookings", { preHandler: app.authorizeRoles(["BARBER", "OWNER", "ADMIN"]) }, async (request) => {
    const { barberId } = request.params as { barberId: string };
    const barber = await app.prisma.barber.findUnique({ where: { id: barberId }, select: { shopId: true } });
    if (!barber) throw app.httpErrors.notFound("Barber not found");
    const q = request.query as { date?: string };
    const dateStr = !q.date || q.date === "today" ? new Date().toISOString().split("T")[0] : q.date;
    const day = new Date(`${dateStr}T00:00:00.000Z`);
    const nextDay = new Date(day.getTime() + 86400000);

    // Include bookings already assigned to this barber, plus unassigned
    // shop-wide bookings (customer chose "any barber") so they're visible somewhere.
    const bookings = await app.prisma.booking.findMany({
      where: {
        shopId: barber.shopId,
        OR: [{ barberId }, { barberId: null }],
        arrivalWindowStart: { gte: day, lt: nextDay }
      },
      orderBy: { arrivalWindowStart: "asc" },
      include: { service: true, user: { select: { id: true, fullName: true } } }
    });
    return { bookings };
  });

  // PATCH /api/barbers/:barberId/status
  app.patch("/barbers/:barberId/status", { preHandler: app.authorizeRoles(["BARBER", "OWNER", "ADMIN"]) }, async (request) => {
    const { barberId } = request.params as { barberId: string };
    if (request.user.role === "BARBER") {
      const ownBarber = await app.prisma.barber.findUnique({
        where: { userId: request.user.sub },
        select: { id: true }
      });
      if (!ownBarber || ownBarber.id !== barberId) {
        throw app.httpErrors.forbidden("Cannot modify another barber's status");
      }
    }
    const { isAvailable } = z.object({ isAvailable: z.boolean() }).parse(request.body);
    const barber = await app.prisma.barber.update({ where: { id: barberId }, data: { isAvailable } });
    return { barber };
  });

  // PATCH /api/barbers/:barberId/break — toggle on-break status
  app.patch("/barbers/:barberId/break", { preHandler: app.authorizeRoles(["BARBER", "OWNER", "ADMIN"]) }, async (request) => {
    const { barberId } = request.params as { barberId: string };
    if (request.user.role === "BARBER") {
      const ownBarber = await app.prisma.barber.findUnique({
        where: { userId: request.user.sub },
        select: { id: true }
      });
      if (!ownBarber || ownBarber.id !== barberId) {
        throw app.httpErrors.forbidden("Cannot modify another barber's break status");
      }
    }
    const { onBreak } = z.object({ onBreak: z.boolean() }).parse(request.body);
    const barber = await app.prisma.barber.update({ where: { id: barberId }, data: { onBreak } });
    return { barber };
  });

  // GET /api/barbers/:barberId/working-hours (proxies shop operating hours)
  app.get("/barbers/:barberId/working-hours", { preHandler: app.authorizeRoles(["BARBER", "OWNER", "ADMIN"]) }, async (request) => {
    const { barberId } = request.params as { barberId: string };
    const barber = await app.prisma.barber.findUnique({ where: { id: barberId }, select: { shopId: true } });
    if (!barber) throw app.httpErrors.notFound("Barber not found");
    const hours = await app.prisma.shopOperatingHour.findMany({ where: { shopId: barber.shopId } });
    return { hours };
  });

  // POST /api/barbers/:barberId/working-hours (placeholder)
  app.post("/barbers/:barberId/working-hours", { preHandler: app.authorizeRoles(["BARBER", "OWNER", "ADMIN"]) }, async (_request, reply) => {
    return reply.status(204).send();
  });

  // PATCH /api/queue/:entryId/status (entryId may be the queue entry id OR the bookingId)
  app.patch("/queue/:entryId/status", { preHandler: app.authorizeRoles(["BARBER", "OWNER", "ADMIN"]) }, async (request) => {
    const { entryId } = request.params as { entryId: string };
    const rawStatus = ((request.body as { status?: string })?.status ?? "").toUpperCase();
    const status = queueStatusSchema.parse(rawStatus);
    const existing = await app.prisma.queueEntry.findFirst({
      where: { OR: [{ id: entryId }, { bookingId: entryId }] },
      include: { booking: { select: { id: true, shopId: true, status: true } } }
    });
    if (!existing) throw app.httpErrors.notFound("Queue entry not found");
    if (request.user.role === "BARBER") {
      const ownBarber = await app.prisma.barber.findFirst({
        where: { userId: request.user.sub, shopId: existing.booking.shopId }
      });
      if (!ownBarber) throw app.httpErrors.forbidden("Not authorized to manage this queue");
    }

    if (status === "IN_SERVICE") {
      // Delegate to the real start-service flow so the QR check-in requirement
      // and chair bookkeeping are actually enforced — this dashboard action
      // used to just flip QueueEntry.queueStatus directly, bypassing both.
      // Earlier dashboard actions (Ready) only sync QueueEntry.queueStatus, not
      // Booking.status, so repair that here before startService()'s own
      // CALLED/READY precondition is checked.
      if (
        existing.booking.status !== existing.queueStatus &&
        (existing.queueStatus === "READY" || existing.queueStatus === "CALLED")
      ) {
        await app.prisma.booking.update({
          where: { id: existing.booking.id },
          data: { status: existing.queueStatus }
        });
      }
      const booking = await app.bookingDeps.service.startService(getAuthUser(request), existing.booking.id);
      return { booking };
    }

    if (status === "COMPLETED") {
      // Delegate to the real booking-completion flow so payment/invoice/loyalty
      // actually run — this dashboard action used to just flip
      // QueueEntry.queueStatus directly, silently skipping payment creation.
      // Earlier dashboard actions (Ready/Start) only sync QueueEntry.queueStatus,
      // not Booking.status, so repair that here before the strict IN_SERVICE
      // precondition inside completeService() is checked.
      if (existing.booking.status !== "IN_SERVICE") {
        await app.prisma.booking.update({
          where: { id: existing.booking.id },
          data: { status: "IN_SERVICE" }
        });
      }
      const booking = await app.bookingDeps.service.completeService(getAuthUser(request), existing.booking.id);
      return { booking };
    }

    const entry = await app.prisma.queueEntry.update({ where: { id: existing.id }, data: { queueStatus: status } });
    return { entry };
  });

  // POST /api/queue/walk-in
  app.post("/queue/walk-in", { preHandler: app.authorizeRoles(["BARBER", "OWNER", "ADMIN"]) }, async (request, reply) => {
    const { shopId, serviceIds, customerName } = z.object({
      shopId: z.string(),
      serviceIds: z.array(z.string()).min(1),
      customerName: z.string().optional()
    }).parse(request.body);

    const [firstServiceId] = serviceIds;
    const service = await app.prisma.service.findFirst({ where: { id: firstServiceId!, shopId } });
    if (!service) throw app.httpErrors.badRequest("Service not found");

    const maxEntry = await app.prisma.queueEntry.findFirst({
      where: { shopId, lane: "WALKIN" },
      orderBy: { position: "desc" },
      select: { position: true }
    });
    const nextPosition = (maxEntry?.position ?? 0) + 1;
    const now = new Date();

    const booking = await app.prisma.$transaction(async (tx) => {
      const b = await tx.booking.create({
        data: {
          userId: request.user.sub,
          shopId,
          serviceId: service.id,
          status: "QUEUED",
          walkIn: true,
          arrivalWindowStart: now,
          arrivalWindowEnd: new Date(now.getTime() + 86400000),
          notes: customerName ?? null
        }
      });
      await tx.queueEntry.create({
        data: { shopId, bookingId: b.id, lane: "WALKIN", position: nextPosition, queueStatus: "WAITING" }
      });
      return b;
    });

    return reply.status(201).send({ booking });
  });
};
