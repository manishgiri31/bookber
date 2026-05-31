import type { Prisma, QueueLane } from "@prisma/client";
import { prisma } from "../../../shared/prisma/client.js";

const POSITION_INCREMENT = 100;
const MIN_GAP_THRESHOLD = 10; // Minimum gap before rebalancing
const MAX_GAP_THRESHOLD = 1000; // Maximum gap for normalization

export type SparsePositionResult = {
  position: number;
  needsRebalance: boolean;
  needsNormalization: boolean;
};

/**
 * Sparse position allocator to eliminate O(n) queue compaction.
 * 
 * Positions are sparse (increment by 100), allowing insertions between
 * existing positions without full reindexing. This enables O(log n) inserts
 * and O(1) removals.
 * 
 * Example:
 * - Initial: 100, 200, 300
 * - Insert between 200 and 300: 250
 * - Remove 200: 100, 250, 300 (no reindex)
 * - Rebalance when gaps < 10: 100, 200, 300
 * - Normalize when gaps > 1000: 100, 200, 300
 */
export class SparsePositionAllocator {
  /**
   * Allocate the next sparse position for a new queue entry.
   * 
   * Strategy:
   * - If queue is empty: return 100
   * - If inserting at end: return maxPosition + 100
   * - If inserting in middle: return (prevPosition + nextPosition) / 2
   * 
   * @param db - Prisma client or transaction
   * @param shopId - Shop ID
   * @param lane - Queue lane (BOOKBER or WALKIN)
   * @param insertAfterPosition - Optional position to insert after (null for end of queue)
   * @returns Position and rebalance flags
   */
  async allocatePosition(
    db: Prisma.TransactionClient | typeof prisma,
    shopId: string,
    lane: QueueLane,
    insertAfterPosition: number | null = null
  ): Promise<SparsePositionResult> {
    const activeQueue = await db.queueEntry.findMany({
      where: {
        shopId,
        lane,
        queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
      },
      orderBy: { position: "asc" },
      select: { position: true }
    });

    // Empty queue
    if (activeQueue.length === 0) {
      return {
        position: POSITION_INCREMENT,
        needsRebalance: false,
        needsNormalization: false
      };
    }

    // Insert at end of queue
    if (insertAfterPosition === null) {
      const maxPosition = activeQueue[activeQueue.length - 1]?.position ?? 0;
      const newPosition = maxPosition + POSITION_INCREMENT;

      return {
        position: newPosition,
        needsRebalance: false,
        needsNormalization: newPosition > MAX_GAP_THRESHOLD
      };
    }

    // Insert in middle of queue
    const insertIndex = activeQueue.findIndex((entry) => entry.position === insertAfterPosition);

    // Insert after last position or if position not found
    if (insertIndex === -1 || insertIndex === activeQueue.length - 1) {
      const maxPosition = activeQueue[activeQueue.length - 1]?.position ?? 0;
      const newPosition = maxPosition + POSITION_INCREMENT;

      return {
        position: newPosition,
        needsRebalance: false,
        needsNormalization: newPosition > MAX_GAP_THRESHOLD
      };
    }

    // Insert between two positions
    const prevPosition = activeQueue[insertIndex]?.position ?? 0;
    const nextPosition = activeQueue[insertIndex + 1]?.position ?? 0;
    const gap = nextPosition - prevPosition;
    const newPosition = prevPosition + Math.floor(gap / 2);

    // Check if gap is too small (needs rebalance)
    const needsRebalance = gap < MIN_GAP_THRESHOLD;
    const needsNormalization = newPosition > MAX_GAP_THRESHOLD;

    return {
      position: newPosition,
      needsRebalance,
      needsNormalization
    };
  }

  /**
   * Allocate position with conflict handling for uniqueness constraint
   * Retries with different position if conflict occurs
   */
  async allocatePositionWithRetry(
    db: Prisma.TransactionClient | typeof prisma,
    shopId: string,
    lane: QueueLane,
    insertAfterPosition: number | null = null,
    maxRetries: number = 3
  ): Promise<SparsePositionResult> {
    let lastError: Error | null = null;

    for (let attempt = 0; attempt < maxRetries; attempt++) {
      try {
        const result = await this.allocatePosition(db, shopId, lane, insertAfterPosition);

        // Validate position uniqueness
        const existing = await db.queueEntry.findFirst({
          where: { shopId, lane, position: result.position }
        });

        if (!existing) {
          return result;
        }

        // Position conflict, retry with different strategy
        lastError = new Error(`Position conflict: ${result.position}`);

        // Try next available position
        const maxPosition = await db.queueEntry.aggregate({
          where: { shopId, lane, queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] } },
          _max: { position: true }
        });

        const nextPosition = (maxPosition._max.position || 0) + POSITION_INCREMENT;
        return {
          position: nextPosition,
          needsRebalance: false,
          needsNormalization: nextPosition > MAX_GAP_THRESHOLD
        };
      } catch (error) {
        lastError = error as Error;
        // Continue to next retry
      }
    }

    throw lastError || new Error("Failed to allocate position after retries");
  }

  /**
   * Check if a queue lane needs rebalancing.
   * Rebalancing is needed when gaps between positions become too small.
   * 
   * @param db - Prisma client or transaction
   * @param shopId - Shop ID
   * @param lane - Queue lane
   * @returns true if rebalancing is needed
   */
  async needsRebalancing(
    db: Prisma.TransactionClient | typeof prisma,
    shopId: string,
    lane: QueueLane
  ): Promise<boolean> {
    const activeQueue = await db.queueEntry.findMany({
      where: {
        shopId,
        lane,
        queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
      },
      orderBy: { position: "asc" },
      select: { position: true }
    });

    if (activeQueue.length < 2) {
      return false;
    }

    // Check if any gap is below threshold
    for (let i = 0; i < activeQueue.length - 1; i++) {
      const current = activeQueue[i];
      const next = activeQueue[i + 1];
      if (!current || !next) continue;
      const gap = next.position - current.position;
      if (gap < MIN_GAP_THRESHOLD) {
        return true;
      }
    }

    return false;
  }

  /**
   * Check if a queue lane needs normalization.
   * Normalization is needed when positions grow too large.
   * 
   * @param db - Prisma client or transaction
   * @param shopId - Shop ID
   * @param lane - Queue lane
   * @returns true if normalization is needed
   */
  async needsNormalization(
    db: Prisma.TransactionClient | typeof prisma,
    shopId: string,
    lane: QueueLane
  ): Promise<boolean> {
    const maxPosition = await db.queueEntry.aggregate({
      where: {
        shopId,
        lane,
        queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
      },
      _max: { position: true }
    });

    return (maxPosition._max.position ?? 0) > MAX_GAP_THRESHOLD;
  }

  /**
   * Rebalance a queue lane by normalizing positions.
   * This is an O(n) operation but should be rare.
   * 
   * @param db - Prisma client or transaction
   * @param shopId - Shop ID
   * @param lane - Queue lane
   */
  async normalizeLane(
    db: Prisma.TransactionClient | typeof prisma,
    shopId: string,
    lane: QueueLane
  ): Promise<void> {
    const activeQueue = await db.queueEntry.findMany({
      where: {
        shopId,
        lane,
        queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
      },
      orderBy: { position: "asc" },
      select: { id: true, bookingId: true }
    });

    // Update positions to standard increments
    for (let i = 0; i < activeQueue.length; i++) {
      const entry = activeQueue[i];
      if (!entry) continue;
      const newPosition = (i + 1) * POSITION_INCREMENT;
      await db.queueEntry.update({
        where: { id: entry.id },
        data: { position: newPosition }
      });
    }
  }

  /**
   * Get the effective position (1-based index) for display purposes.
   * This converts sparse positions to sequential indices for user display.
   * 
   * @param db - Prisma client or transaction
   * @param shopId - Shop ID
   * @param lane - Queue lane
   * @param position - Sparse position
   * @returns 1-based index
   */
  async getEffectivePosition(
    db: Prisma.TransactionClient | typeof prisma,
    shopId: string,
    lane: QueueLane,
    position: number
  ): Promise<number> {
    const count = await db.queueEntry.count({
      where: {
        shopId,
        lane,
        queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] },
        position: { lt: position }
      }
    });

    return count + 1;
  }

  /**
   * Get all effective positions for a queue lane.
   * Useful for batch display updates.
   * 
   * @param db - Prisma client or transaction
   * @param shopId - Shop ID
   * @param lane - Queue lane
   * @returns Map of sparse position to effective position
   */
  async getEffectivePositions(
    db: Prisma.TransactionClient | typeof prisma,
    shopId: string,
    lane: QueueLane
  ): Promise<Map<number, number>> {
    const activeQueue = await db.queueEntry.findMany({
      where: {
        shopId,
        lane,
        queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
      },
      orderBy: { position: "asc" },
      select: { position: true }
    });

    const positionMap = new Map<number, number>();
    for (let i = 0; i < activeQueue.length; i++) {
      const entry = activeQueue[i];
      if (entry) {
        positionMap.set(entry.position, i + 1);
      }
    }

    return positionMap;
  }
}
