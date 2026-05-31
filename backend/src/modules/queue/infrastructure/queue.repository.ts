import type { Prisma, QueueEventType, QueueLane, QueueStatus } from "@prisma/client";
import { prisma } from "../../../shared/prisma/client.js";
import { SparsePositionAllocator } from "../application/sparse-position-allocator.service.js";

export type DbClient = Prisma.TransactionClient | typeof prisma;

const ACTIVE_QUEUE_STATUSES: QueueStatus[] = ["WAITING", "READY", "CALLED", "IN_SERVICE"];

export class PrismaQueueRepository {
  private readonly positionAllocator: SparsePositionAllocator;

  constructor() {
    this.positionAllocator = new SparsePositionAllocator();
  }

  async lockShop(db: DbClient, shopId: string): Promise<void> {
    await db.$queryRaw`SELECT id FROM "Shop" WHERE id = ${shopId} FOR UPDATE`;
  }

  async lockBooking(db: DbClient, bookingId: string): Promise<void> {
    await db.$queryRaw`SELECT id FROM "Booking" WHERE id = ${bookingId} FOR UPDATE`;
  }

  async lockChair(db: DbClient, chairId: string): Promise<void> {
    await db.$queryRaw`SELECT id FROM "Chair" WHERE id = ${chairId} FOR UPDATE`;
  }

  async lockQueueEntry(db: DbClient, queueEntryId: string): Promise<void> {
    await db.$queryRaw`SELECT id FROM "QueueEntry" WHERE id = ${queueEntryId} FOR UPDATE`;
  }

  async findShopById(db: DbClient, shopId: string) {
    return db.shop.findUnique({
      where: { id: shopId },
      include: {
        chairs: { orderBy: { number: "asc" } },
        services: { where: { isActive: true } },
        barbers: { where: { isAvailable: true } }
      }
    });
  }

  async findService(db: DbClient, serviceId: string) {
    return db.service.findUnique({ where: { id: serviceId } });
  }

  async findBooking(db: DbClient, bookingId: string) {
    return db.booking.findUnique({
      where: { id: bookingId },
      include: {
        service: true,
        barber: true,
        queueEntry: true,
        chair: true,
        user: true
      }
    });
  }

  // Legacy method for backward compatibility - will be removed after migration
  async listActiveQueueEntries(db: DbClient, shopId: string, lane: QueueLane) {
    return this.listQueueEntries(db, shopId, lane);
  }

  async countReservedChairs(db: DbClient, shopId: string): Promise<number> {
    return db.chair.count({
      where: { shopId, reservedForBookBer: true, status: { not: "BLOCKED" } }
    });
  }

  async countActiveReservedChairsInService(db: DbClient, shopId: string): Promise<number> {
    const reserved = await db.chair.count({
      where: { shopId, reservedForBookBer: true, status: "OCCUPIED" }
    });
    const totalReserved = await this.countReservedChairs(db, shopId);
    const availableReserved = await db.chair.count({
      where: { shopId, reservedForBookBer: true, status: "AVAILABLE" }
    });
    return Math.max(1, totalReserved - availableReserved + (availableReserved > 0 ? availableReserved : 0));
  }

  async listQueueEntries(db: DbClient, shopId: string, lane: QueueLane) {
    return db.queueEntry.findMany({
      where: {
        shopId,
        lane,
        queueStatus: { in: ACTIVE_QUEUE_STATUSES }
      },
      include: {
        booking: {
          include: {
            service: true,
            barber: true,
            user: true
          }
        }
      },
      orderBy: { position: "asc" }
    });
  }

  async nextQueuePosition(
    db: DbClient,
    shopId: string,
    lane: QueueLane,
    insertAfterPosition: number | null = null
  ): Promise<{ position: number; needsRebalance: boolean; needsNormalization: boolean }> {
    return this.positionAllocator.allocatePositionWithRetry(db, shopId, lane, insertAfterPosition, 3);
  }

  async needsRebalancing(db: DbClient, shopId: string, lane: QueueLane): Promise<boolean> {
    return this.positionAllocator.needsRebalancing(db, shopId, lane);
  }

  async needsNormalization(db: DbClient, shopId: string, lane: QueueLane): Promise<boolean> {
    return this.positionAllocator.needsNormalization(db, shopId, lane);
  }

  async normalizeLane(db: DbClient, shopId: string, lane: QueueLane): Promise<void> {
    return this.positionAllocator.normalizeLane(db, shopId, lane);
  }

  async getEffectivePosition(db: DbClient, shopId: string, lane: QueueLane, position: number): Promise<number> {
    return this.positionAllocator.getEffectivePosition(db, shopId, lane, position);
  }

  async getEffectivePositions(db: DbClient, shopId: string, lane: QueueLane): Promise<Map<number, number>> {
    return this.positionAllocator.getEffectivePositions(db, shopId, lane);
  }

  async createQueueEvent(
    db: DbClient,
    data: {
      shopId: string;
      bookingId?: string;
      type: QueueEventType;
      payload?: Prisma.InputJsonValue;
    }
  ) {
    return db.queueEvent.create({
      data: {
        shopId: data.shopId,
        ...(data.bookingId ? { bookingId: data.bookingId } : {}),
        type: data.type,
        payload: data.payload ?? {}
      }
    });
  }

  async findAvailableChairForLane(db: DbClient, shopId: string, lane: QueueLane) {
    return db.chair.findFirst({
      where: {
        shopId,
        status: "AVAILABLE",
        reservedForBookBer: lane === "BOOKBER"
      },
      orderBy: { number: "asc" }
    });
  }

  async assignChair(
    db: DbClient,
    args: {
      shopId: string;
      chairId: string;
      bookingId: string;
      activeServiceStart?: Date;
    }
  ) {
    const now = args.activeServiceStart ?? new Date();
    const allocation = await db.chairAllocation.create({
      data: {
        shopId: args.shopId,
        chairId: args.chairId,
        bookingId: args.bookingId,
        activeServiceStart: now
      }
    });

    await db.chair.update({
      where: { id: args.chairId },
      data: {
        status: "OCCUPIED",
        activeServiceStart: now,
        activeServiceEnd: null
      }
    });

    return allocation;
  }

  async releaseChair(db: DbClient, chairId: string, bookingId: string, endAt = new Date()) {
    await db.chairAllocation.updateMany({
      where: { chairId, bookingId, releasedAt: null },
      data: { releasedAt: endAt, activeServiceEnd: endAt }
    });

    return db.chair.update({
      where: { id: chairId },
      data: {
        status: "AVAILABLE",
        activeServiceStart: null,
        activeServiceEnd: endAt
      }
    });
  }

  async markChairCleaning(db: DbClient, chairId: string) {
    return db.chair.update({
      where: { id: chairId },
      data: { status: "CLEANING" }
    });
  }

  async finishChairCleaning(db: DbClient, chairId: string) {
    return db.chair.update({
      where: { id: chairId },
      data: { status: "AVAILABLE", activeServiceEnd: null }
    });
  }

  async updateBarberRollingAverage(db: DbClient, barberId: string, actualMinutes: number) {
    const barber = await db.barber.findUnique({ where: { id: barberId } });
    if (!barber) return;
    const prev = barber.averageServiceMinutes;
    const next = prev == null ? actualMinutes : Math.round(prev * 0.7 + actualMinutes * 0.3);
    await db.barber.update({
      where: { id: barberId },
      data: { averageServiceMinutes: next }
    });
  }
}
