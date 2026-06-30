import type { EventLogType } from "@prisma/client";
import type { FastifyPluginAsync } from "fastify";
import { z } from "zod";

export const receptionRoutes: FastifyPluginAsync = async (app) => {
  // Resolve the shop for the current user based on role
  async function resolveShopId(userId: string, role: string): Promise<string> {
    if (role === "BARBER") {
      const barber = await app.prisma.barber.findUnique({
        where: { userId },
        select: { shopId: true }
      });
      if (!barber) throw app.httpErrors.forbidden("No barber profile found");
      return barber.shopId;
    }
    if (role === "RECEPTION") {
      const staff = await app.prisma.shopStaff.findFirst({
        where: { userId },
        select: { shopId: true }
      });
      if (!staff) throw app.httpErrors.forbidden("Not assigned to any shop");
      return staff.shopId;
    }
    if (role === "ADMIN") {
      // ADMIN must pass shopId explicitly via query param
      throw app.httpErrors.badRequest("Admin must supply shopId query param");
    }
    throw app.httpErrors.forbidden("Insufficient role");
  }

  async function resolveShopIdForAdmin(userId: string, role: string, shopIdParam?: string): Promise<string> {
    if (role === "ADMIN") {
      if (!shopIdParam) throw app.httpErrors.badRequest("shopId query param required for admin");
      return shopIdParam;
    }
    return resolveShopId(userId, role);
  }

  // GET /api/reception/queue — live queue for the shop
  app.get("/reception/queue", { preHandler: app.authorizeRoles(["BARBER", "RECEPTION", "ADMIN"]) }, async (request) => {
    const query = request.query as { shopId?: string };
    const shopId = await resolveShopIdForAdmin(request.user.sub, request.user.role, query.shopId);
    const entries = await app.prisma.queueEntry.findMany({
      where: {
        shopId,
        queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
      },
      orderBy: { position: "asc" },
      include: {
        booking: {
          include: {
            service: { select: { name: true, price: true, durationMinutes: true } },
            user: { select: { id: true, fullName: true, phoneNumber: true } }
          }
        }
      }
    });
    return { queue: entries };
  });

  // POST /api/reception/check-in — check in a customer by bookingId
  app.post("/reception/check-in", { preHandler: app.authorizeRoles(["BARBER", "RECEPTION", "ADMIN"]) }, async (request, reply) => {
    const { bookingId, shopId: shopIdBody } = z.object({
      bookingId: z.string().cuid(),
      shopId: z.string().optional()
    }).parse(request.body);
    const shopId = await resolveShopIdForAdmin(request.user.sub, request.user.role, shopIdBody);

    const booking = await app.prisma.booking.findUnique({
      where: { id: bookingId },
      select: { id: true, shopId: true, status: true, userId: true }
    });
    if (!booking) throw app.httpErrors.notFound("Booking not found");
    if (booking.shopId !== shopId) throw app.httpErrors.forbidden("Booking belongs to a different shop");
    if (!["QUEUED", "READY"].includes(booking.status)) {
      throw app.httpErrors.conflict(`Booking cannot be checked in (current status: ${booking.status})`);
    }

    const updated = await app.prisma.$transaction(async (tx) => {
      const b = await tx.booking.update({
        where: { id: bookingId },
        data: { status: "READY" }
      });
      await tx.queueEntry.update({
        where: { bookingId },
        data: { queueStatus: "READY", version: { increment: 1 } }
      });
      return b;
    });

    try {
      await app.prisma.eventLog.create({
        data: {
          type: "RECEPTION_CHECKIN" as EventLogType,
          shopId,
          bookingId,
          userId: booking.userId,
          payload: { checkedInBy: request.user.sub, role: request.user.role }
        }
      });
    } catch (_) { /* non-critical */ }

    return reply.send({ booking: updated });
  });

  // POST /api/reception/walk-in — create walk-in entry
  app.post("/reception/walk-in", { preHandler: app.authorizeRoles(["BARBER", "RECEPTION", "ADMIN"]) }, async (request, reply) => {
    const { serviceId, customerName, shopId: shopIdBody } = z.object({
      serviceId: z.string().cuid(),
      customerName: z.string().min(1).max(100),
      shopId: z.string().optional()
    }).parse(request.body);

    const shopId = await resolveShopIdForAdmin(request.user.sub, request.user.role, shopIdBody);

    const service = await app.prisma.service.findFirst({ where: { id: serviceId, shopId } });
    if (!service) throw app.httpErrors.badRequest("Service not found in this shop");

    const maxEntry = await app.prisma.queueEntry.findFirst({
      where: { shopId, lane: "WALKIN" },
      orderBy: { position: "desc" },
      select: { position: true }
    });
    const position = (maxEntry?.position ?? 0) + 1;
    const now = new Date();

    const booking = await app.prisma.$transaction(async (tx) => {
      const b = await tx.booking.create({
        data: {
          userId: request.user.sub,
          shopId,
          serviceId: service.id,
          status: "QUEUED",
          walkIn: true,
          notes: customerName,
          arrivalWindowStart: now,
          arrivalWindowEnd: new Date(now.getTime() + 86400000)
        }
      });
      await tx.queueEntry.create({
        data: { shopId, bookingId: b.id, lane: "WALKIN", position, queueStatus: "WAITING" }
      });
      return b;
    });

    return reply.status(201).send({ booking });
  });

  // GET /api/reception/scheduled — today's scheduled bookings
  app.get("/reception/scheduled", { preHandler: app.authorizeRoles(["BARBER", "RECEPTION", "ADMIN"]) }, async (request) => {
    const query = request.query as { shopId?: string };
    const shopId = await resolveShopIdForAdmin(request.user.sub, request.user.role, query.shopId);
    const now = new Date();
    const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);

    const bookings = await app.prisma.booking.findMany({
      where: {
        shopId,
        status: { in: ["SCHEDULED", "QUEUED"] },
        scheduledStart: { gte: now, lt: endOfDay }
      },
      orderBy: { scheduledStart: "asc" },
      include: {
        service: { select: { name: true, durationMinutes: true, price: true } },
        user: { select: { id: true, fullName: true, phoneNumber: true } },
        barber: { include: { user: { select: { fullName: true } } } }
      }
    });

    return { bookings };
  });
};
