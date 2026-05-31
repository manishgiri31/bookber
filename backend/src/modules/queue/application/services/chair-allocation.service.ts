import { Prisma, type QueueLane } from "@prisma/client";
import type { PrismaQueueRepository } from "../../infrastructure/queue.repository.js";
import { ChairAllocator } from "../chair-allocator.service.js";
import { QueueLock } from "../../queue.lock.js";
import { prisma } from "../../../../shared/prisma/client.js";

/**
 * ChairAllocationService handles chair assignment and release operations.
 * 
 * Responsibilities:
 * - Find available chairs
 * - Allocate chairs to bookings
 * - Release chairs from bookings
 * - Try assign next booking to available chair
 * 
 * Transaction ownership: Owns chair allocation transactions
 * Redis ownership: Delegates to other services
 * Event ownership: Delegates to QueueRealtimeService
 */
export class ChairAllocationService {
  constructor(
    private readonly repository: PrismaQueueRepository,
    private readonly chairAllocator: ChairAllocator,
    private readonly lock: QueueLock
  ) { }

  /**
   * Find an available chair for a lane
   */
  async findAvailableChair(shopId: string, lane: QueueLane): Promise<any> {
    return this.chairAllocator.findAvailableChair(prisma, shopId, lane);
  }

  /**
   * Allocate a chair to a booking
   */
  async allocateToBooking(
    shopId: string,
    chair: any,
    bookingId: string,
    lane: QueueLane,
    startNow: boolean
  ): Promise<void> {
    await this.chairAllocator.allocateToBooking(prisma, {
      shopId,
      chair,
      bookingId,
      lane,
      startNow
    });
  }

  /**
   * Release a chair from a booking
   */
  async releaseChair(chairId: string, bookingId: string, endAt: Date): Promise<void> {
    await this.repository.releaseChair(prisma, chairId, bookingId, endAt);
  }

  /**
   * Try to assign next booking to an available chair
   * This is called after a booking is completed, cancelled, or no-show
   */
  async tryAssignNext(shopId: string, lane: QueueLane): Promise<void> {
    await this.lock.withLock(`shop:${shopId}:assign`, 5000, async () =>
      prisma.$transaction(async (tx: Prisma.TransactionClient) => {
        await this.repository.lockShop(tx, shopId);

        const chair = await this.chairAllocator.findAvailableChair(tx, shopId, lane);
        if (!chair) return;

        // Lock chair before allocation to prevent race condition
        await this.repository.lockChair(tx, chair.id);

        const next = await tx.queueEntry.findFirst({
          where: {
            shopId,
            lane,
            queueStatus: { in: ["WAITING", "READY"] },
            booking: { status: { in: ["QUEUED", "READY"] } }
          },
          include: { booking: true },
          orderBy: { position: "asc" }
        });

        if (!next) return;

        const now = new Date();
        if (next.queueStatus === "WAITING" && now > next.booking.arrivalWindowEnd) {
          return;
        }

        await this.chairAllocator.allocateToBooking(tx, {
          shopId,
          chair,
          bookingId: next.bookingId,
          lane,
          startNow: true
        });

        await tx.booking.update({
          where: { id: next.bookingId },
          data: {
            chairId: chair.id,
            status: "CALLED"
          }
        });

        await tx.queueEntry.update({
          where: { id: next.id },
          data: { queueStatus: "CALLED", version: { increment: 1 } }
        });

        await this.repository.createQueueEvent(tx, {
          shopId,
          bookingId: next.bookingId,
          type: "CHAIR_ASSIGNED",
          payload: { chairId: chair.id }
        });
      }, { isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted, maxWait: 5000, timeout: 10000 })
    );
  }

  /**
   * Get chair status
   */
  async getChairStatus(chairId: string): Promise<any> {
    return prisma.chair.findUnique({
      where: { id: chairId },
      include: {
        chairAllocations: {
          where: { releasedAt: null },
          include: { booking: true }
        }
      }
    });
  }

  /**
   * Force release a chair (emergency recovery)
   */
  async forceReleaseChair(chairId: string): Promise<void> {
    await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      await this.repository.lockChair(tx, chairId);

      const activeAllocation = await tx.chairAllocation.findFirst({
        where: { chairId, releasedAt: null },
        include: { booking: true }
      });

      if (activeAllocation) {
        await this.repository.releaseChair(tx, chairId, activeAllocation.bookingId, new Date());
      }

      await tx.chair.update({
        where: { id: chairId },
        data: { status: "AVAILABLE", activeServiceStart: null, activeServiceEnd: null }
      });
    }, { isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted, maxWait: 5000, timeout: 10000 });
  }
}
