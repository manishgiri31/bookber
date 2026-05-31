import { Prisma, type QueueLane } from "@prisma/client";
import type { PrismaQueueRepository } from "../../infrastructure/queue.repository.js";
import type { QueueSnapshot, QueueSnapshotEntry } from "../../domain/queue.types.js";
import { QueueLock } from "../../queue.lock.js";
import { Errors } from "../../../../shared/http/app-error.js";
import { prisma } from "../../../../shared/prisma/client.js";

/**
 * QueuePositionService handles queue position management.
 * 
 * Responsibilities:
 * - Position allocation (sparse positioning)
 * - Queue compaction (sparse positioning)
 * - Lane normalization
 * - Lane rebalancing
 * - Snapshot building
 * 
 * Transaction ownership: Owns position-related transactions
 * Redis ownership: Delegates to other services
 * Event ownership: Delegates to QueueRealtimeService
 */
export class QueuePositionService {
  constructor(
    private readonly repository: PrismaQueueRepository,
    private readonly lock: QueueLock
  ) { }

  /**
   * Get next queue position with sparse positioning
   */
  async getNextPosition(
    shopId: string,
    lane: QueueLane,
    insertAfterPosition: number | null = null
  ): Promise<{ position: number; needsRebalance: boolean; needsNormalization: boolean }> {
    return this.repository.nextQueuePosition(prisma, shopId, lane, insertAfterPosition);
  }

  /**
   * Compact queue using sparse positioning
   * With sparse positioning, we don't need O(n) reindexing on every deletion.
   * Only normalize when positions get too large or gaps get too small.
   */
  async compactQueue(tx: Prisma.TransactionClient, shopId: string, lane: QueueLane): Promise<void> {
    const needsRebalancing = await this.repository.needsRebalancing(tx, shopId, lane);
    const needsNormalization = await this.repository.needsNormalization(tx, shopId, lane);

    if (needsRebalancing || needsNormalization) {
      await this.repository.normalizeLane(tx, shopId, lane);
    }
  }

  /**
   * Normalize a specific lane
   */
  async normalizeLane(shopId: string, lane: QueueLane): Promise<void> {
    return this.lock.withLock(`shop:${shopId}:normalize`, 8000, async () =>
      prisma.$transaction(async (tx) => {
        await this.repository.lockShop(tx, shopId);
        await this.repository.normalizeLane(tx, shopId, lane);
      }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable, maxWait: 8000, timeout: 15000 })
    );
  }

  /**
   * Normalize all lanes for a shop
   */
  async normalizeShop(shopId: string): Promise<void> {
    return this.lock.withLock(`shop:${shopId}:normalize`, 8000, async () =>
      prisma.$transaction(async (tx) => {
        await this.repository.lockShop(tx, shopId);
        await this.repository.normalizeLane(tx, shopId, "BOOKBER");
        await this.repository.normalizeLane(tx, shopId, "WALKIN");
      }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable, maxWait: 8000, timeout: 15000 })
    );
  }

  /**
   * Get effective position (1-indexed) from sparse position
   */
  async getEffectivePosition(shopId: string, lane: QueueLane, position: number): Promise<number> {
    return this.repository.getEffectivePosition(prisma, shopId, lane, position);
  }

  /**
   * Get all effective positions for a lane
   */
  async getEffectivePositions(shopId: string, lane: QueueLane): Promise<Map<number, number>> {
    return this.repository.getEffectivePositions(prisma, shopId, lane);
  }

  /**
   * Check if lane needs rebalancing
   */
  async needsRebalancing(shopId: string, lane: QueueLane): Promise<boolean> {
    return this.repository.needsRebalancing(prisma, shopId, lane);
  }

  /**
   * Check if lane needs normalization
   */
  async needsNormalization(shopId: string, lane: QueueLane): Promise<boolean> {
    return this.repository.needsNormalization(prisma, shopId, lane);
  }

  /**
   * Build queue snapshot
   */
  async buildSnapshot(shopId: string, version: number): Promise<QueueSnapshot> {
    const mapEntry = async (lane: QueueLane): Promise<QueueSnapshotEntry[]> => {
      const rows = await this.repository.listActiveQueueEntries(prisma, shopId, lane);
      return rows.map((row) => ({
        activeQueueId: row.id,
        bookingId: row.bookingId,
        shopId: row.shopId,
        barberId: row.barberId,
        userId: row.booking.userId,
        serviceId: row.booking.serviceId,
        lane: row.lane,
        position: row.position,
        queueStatus: row.queueStatus,
        bookingStatus: row.booking.status,
        estimatedWaitMinutes: row.estimatedWaitMinutes,
        estimatedServiceStart: row.estimatedServiceStart,
        arrivalWindowStart: row.booking.arrivalWindowStart,
        arrivalWindowEnd: row.booking.arrivalWindowEnd,
        chairId: row.booking.chairId,
        walkIn: row.booking.walkIn
      }));
    };

    return {
      shopId,
      version,
      bookBer: await mapEntry("BOOKBER"),
      walkIn: await mapEntry("WALKIN")
    };
  }

  /**
   * Rebalance shop (force normalization of all lanes)
   */
  async rebalanceShop(shopId: string): Promise<QueueSnapshot> {
    return this.lock.withLock(`shop:${shopId}:rebalance`, 8000, async () =>
      prisma.$transaction(async (tx) => {
        await this.repository.lockShop(tx, shopId);
        const shop = await this.repository.findShopById(tx, shopId);
        if (!shop) throw Errors.notFound("Shop not found");

        await this.repository.normalizeLane(tx, shopId, "BOOKBER");
        await this.repository.normalizeLane(tx, shopId, "WALKIN");

        return await this.buildSnapshot(shopId, Date.now());
      }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable, maxWait: 8000, timeout: 15000 })
    );
  }

  /**
   * Get shop snapshot
   */
  async getShopSnapshot(shopId: string): Promise<QueueSnapshot> {
    return this.buildSnapshot(shopId, Date.now());
  }
}
