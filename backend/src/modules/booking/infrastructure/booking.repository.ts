import type { Prisma } from "@prisma/client";
import { prisma } from "../../../shared/prisma/client.js";
import { SparsePositionAllocator } from "../../queue/application/sparse-position-allocator.service.js";

type DbClient = Prisma.TransactionClient | typeof prisma;

const ACTIVE_QUEUE_STATUSES = ["WAITING", "READY", "CALLED", "IN_SERVICE"];

export class PrismaBookingRepository {
  private readonly positionAllocator = new SparsePositionAllocator();

  /**
   * QueueEntry.position is a sparse internal index (increments of 100, used for
   * cheap middle-inserts) — it must never be shown to users as-is. Replace it with
   * the 1-based effective rank before a booking leaves the repository layer.
   */
  private async withEffectivePosition<T extends { shopId: string; queueEntry: { lane: import("@prisma/client").QueueLane; position: number; queueStatus: string } | null }>(
    db: DbClient,
    booking: T
  ): Promise<T> {
    if (!booking.queueEntry || !ACTIVE_QUEUE_STATUSES.includes(booking.queueEntry.queueStatus)) {
      return booking;
    }
    const effectivePosition = await this.positionAllocator.getEffectivePosition(
      db,
      booking.shopId,
      booking.queueEntry.lane,
      booking.queueEntry.position
    );
    return { ...booking, queueEntry: { ...booking.queueEntry, position: effectivePosition } };
  }
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
    const booking = await db.booking.findUnique({
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
    if (!booking) return booking;
    return this.withEffectivePosition(db, booking);
  }

  async findActiveBookingsForShop(db: DbClient, shopId: string) {
    const bookings = await db.booking.findMany({
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
    return Promise.all(bookings.map((booking) => this.withEffectivePosition(db, booking)));
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

    const bookings = await db.booking.findMany({
      where: { userId, ...statusFilter },
      orderBy: { createdAt: "desc" },
      include: {
        shop: true,
        service: true,
        barber: { include: { user: true } },
        chair: true,
        queueEntry: true,
        review: { select: { id: true } }
      }
    });
    return Promise.all(bookings.map((booking) => this.withEffectivePosition(db, booking)));
  }
}
