import type { Prisma } from "@prisma/client";
import { prisma } from "../../../shared/prisma/client.js";

type DbClient = Prisma.TransactionClient | typeof prisma;

export class PrismaBookingRepository {
  async findShopForUpdate(db: DbClient, shopId: string): Promise<void> {
    await db.$queryRaw`SELECT id FROM "Shop" WHERE id = ${shopId} FOR UPDATE`;
  }

  async findServiceById(db: DbClient, serviceId: string) {
    return db.service.findUnique({
      where: { id: serviceId },
      include: { shop: true }
    });
  }

  async findShopById(db: DbClient, shopId: string) {
    return db.shop.findUnique({
      where: { id: shopId },
      include: { chairs: true, operatingHours: true }
    });
  }

  async findBookingById(db: DbClient, bookingId: string) {
    return db.booking.findUnique({
      where: { id: bookingId },
      include: {
        shop: true,
        user: true,
        barber: { include: { user: true } },
        chair: true,
        service: true,
        queueEntry: true
      }
    });
  }

  async findActiveBookingsForShop(db: DbClient, shopId: string) {
    return db.booking.findMany({
      where: {
        shopId,
        status: { in: ["QUEUED", "READY", "CALLED", "IN_SERVICE"] }
      },
      orderBy: { queueEntry: { position: "asc" } },
      include: {
        user: true,
        service: true,
        barber: { include: { user: true } },
        chair: true,
        queueEntry: true
      }
    });
  }

  async findActiveBookingForUser(db: DbClient, userId: string, shopId: string) {
    return db.booking.findFirst({
      where: {
        userId,
        shopId,
        status: { in: ["QUEUED", "READY", "CALLED", "IN_SERVICE"] }
      }
    });
  }

  async findBookingsByUserId(db: DbClient, userId: string, status?: string) {
    const activeStatuses = ["QUEUED", "READY", "CALLED", "IN_SERVICE"];
    const statusFilter = status === "active"
      ? { status: { in: activeStatuses as any } }
      : status
        ? { status: status.toUpperCase() as any }
        : {};

    return db.booking.findMany({
      where: { userId, ...statusFilter },
      orderBy: { createdAt: "desc" },
      include: {
        shop: true,
        service: true,
        barber: { include: { user: true } },
        chair: true,
        queueEntry: true
      }
    });
  }
}
