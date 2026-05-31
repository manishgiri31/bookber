import type { Prisma, QueueLane } from "@prisma/client";
import { prisma } from "../../../shared/prisma/client.js";
import type { WaitTimeMismatch, RecoveryConfig, RecoveryStats } from "./recovery-types.js";
import { DEFAULT_RECOVERY_CONFIG } from "./recovery-types.js";
import { RecoveryTransactionManager } from "./recovery-transaction-manager.js";
import { QueueLock } from "../queue.lock.js";

/**
 * Wait-time reconciler worker.
 * 
 * Detects and reconciles wait time discrepancies between Redis and PostgreSQL.
 * This can happen when:
 * - Redis cache is stale or corrupted
 * - Wait time calculation is inconsistent
 * - Queue state changes are not propagated to Redis
 * - Redis eviction removes wait time data
 */
export class WaitTimeReconcilerWorker {
  private readonly config: RecoveryConfig;
  private readonly transactionManager: RecoveryTransactionManager;
  private readonly intervalMs: number;
  private readonly lock: QueueLock;

  constructor(
    lock: QueueLock,
    config: Partial<RecoveryConfig> = {},
    intervalMs: number = 20 * 60 * 1000 // Default: 20 minutes
  ) {
    this.config = { ...DEFAULT_RECOVERY_CONFIG, ...config };
    this.transactionManager = new RecoveryTransactionManager(this.config);
    this.intervalMs = intervalMs;
    this.lock = lock;
  }

  /**
   * Detect wait time mismatches across all active shops
   */
  async detectWaitTimeMismatches(redisStore: any): Promise<WaitTimeMismatch[]> {
    const mismatches: WaitTimeMismatch[] = [];

    const shops = await prisma.shop.findMany({
      where: { isActive: true },
      select: { id: true }
    });

    for (const shop of shops) {
      const shopMismatches = await this.detectWaitTimeMismatchesForShop(shop.id, redisStore);
      mismatches.push(...shopMismatches);
    }

    return mismatches;
  }

  /**
   * Detect wait time mismatches for a specific shop
   */
  async detectWaitTimeMismatchesForShop(shopId: string, redisStore: any): Promise<WaitTimeMismatch[]> {
    const mismatches: WaitTimeMismatch[] = [];
    const lanes: QueueLane[] = ["BOOKBER", "WALKIN"];

    for (const lane of lanes) {
      const laneMismatches = await this.detectWaitTimeMismatchesForLane(shopId, lane, redisStore);
      mismatches.push(...laneMismatches);
    }

    return mismatches;
  }

  /**
   * Detect wait time mismatches for a specific lane
   */
  async detectWaitTimeMismatchesForLane(shopId: string, lane: QueueLane, redisStore: any): Promise<WaitTimeMismatch[]> {
    const mismatches: WaitTimeMismatch[] = [];

    const activeQueue = await prisma.queueEntry.findMany({
      where: {
        shopId,
        lane,
        queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
      },
      select: {
        bookingId: true,
        estimatedWaitMinutes: true
      }
    });

    for (const entry of activeQueue) {
      const dbWaitMinutes = entry.estimatedWaitMinutes;
      const redisWaitMinutes = await this.getRedisWaitMinutes(redisStore, entry.bookingId);

      if (redisWaitMinutes !== null) {
        const discrepancy = Math.abs(dbWaitMinutes - redisWaitMinutes);

        if (discrepancy > this.config.waitTimeDiscrepancyThreshold) {
          mismatches.push({
            shopId,
            lane,
            bookingId: entry.bookingId,
            dbWaitMinutes,
            redisWaitMinutes,
            discrepancy
          });
        }
      }
    }

    return mismatches;
  }

  /**
   * Get wait minutes from Redis
   */
  private async getRedisWaitMinutes(redisStore: any, bookingId: string): Promise<number | null> {
    if (!redisStore || !redisStore.isAvailable()) {
      return null;
    }

    try {
      const snapshot = await redisStore.getBookingSnapshot(bookingId);
      return snapshot ? snapshot.estimatedWaitMinutes : null;
    } catch (error) {
      console.error("Failed to get Redis wait minutes:", error);
      return null;
    }
  }

  /**
   * Auto-recalculate wait times for mismatched entries
   */
  async recalculateWaitTimes(mismatches: WaitTimeMismatch[], waitTimeEngine: any): Promise<number> {
    if (!this.config.enableWaitTimeRecalculation) {
      return 0;
    }

    const affectedShops = new Set<string>();
    const affectedLanes = new Set<string>();

    for (const mismatch of mismatches) {
      affectedShops.add(mismatch.shopId);
      affectedLanes.add(`${mismatch.shopId}:${mismatch.lane}`);
    }

    let recalculated = 0;

    for (const shopId of affectedShops) {
      const lanes: QueueLane[] = ["BOOKBER", "WALKIN"];

      for (const lane of lanes) {
        if (affectedLanes.has(`${shopId}:${lane}`)) {
          await this.transactionManager.executeRecovery(
            () => this.transactionManager.recalculateWaitTimes(shopId, lane, waitTimeEngine),
            "WAIT_TIME_RECALCULATED",
            shopId,
            "Recalculate wait times"
          );

          if (this.transactionManager.getEvents().length > 0) {
            recalculated++;
          }
        }
      }
    }

    return recalculated;
  }

  /**
   * Run the wait-time reconciler worker
   */
  async run(redisStore: any, waitTimeEngine: any): Promise<RecoveryStats> {
    const stats: RecoveryStats = {
      chairsRecovered: 0,
      servicesFlagged: 0,
      queueEntriesRecovered: 0,
      redisRebuilt: 0,
      positionsNormalized: 0,
      waitTimesRecalculated: 0,
      socketsDisconnected: 0,
      totalEvents: 0,
      criticalEvents: 0,
      errorEvents: 0,
      warningEvents: 0,
      infoEvents: 0
    };

    try {
      // Use distributed locking for each shop to prevent concurrent execution
      const shops = await prisma.shop.findMany({
        where: { isActive: true },
        select: { id: true }
      });

      for (const shop of shops) {
        try {
          await this.lock.withLock(`shop:${shop.id}:wait-time-rebuild`, 30000, async () => {
            const mismatches = await this.detectWaitTimeMismatchesForShop(shop.id, redisStore);

            if (mismatches.length > 0) {
              const recalculated = await this.recalculateWaitTimes(mismatches, waitTimeEngine);
              stats.waitTimesRecalculated += recalculated;
            }

            const events = this.transactionManager.getEvents();
            stats.totalEvents += events.length;
            stats.criticalEvents += events.filter(e => e.severity === "CRITICAL").length;
            stats.errorEvents += events.filter(e => e.severity === "ERROR").length;
            stats.warningEvents += events.filter(e => e.severity === "WARNING").length;
            stats.infoEvents += events.filter(e => e.severity === "INFO").length;

            this.transactionManager.clearEvents();
          });
        } catch (error) {
          if (error instanceof Error && error.message === "QUEUE_LOCK_BUSY") {
            console.log(`Wait time reconciliation lock busy for shop ${shop.id}, skipping`);
          } else {
            console.error(`Wait time reconciliation failed for shop ${shop.id}:`, error);
          }
        }
      }
    } catch (error) {
      console.error("Wait-time reconciler worker failed:", error);
    }

    return stats;
  }

  /**
   * Start the periodic worker
   */
  start(redisStore: any, waitTimeEngine: any): () => void {
    const interval = setInterval(() => {
      this.run(redisStore, waitTimeEngine).catch((error) => {
        console.error("Wait-time reconciler worker failed:", error);
      });
    }, this.intervalMs);

    // Run immediately on start
    this.run(redisStore, waitTimeEngine).catch((error) => {
      console.error("Wait-time reconciler worker failed:", error);
    });

    return () => clearInterval(interval);
  }

  /**
   * Get statistics for monitoring
   */
  async getStats(redisStore: any): Promise<{
    totalActiveQueue: number;
    mismatches: number;
    byShop: Record<string, number>;
    byLane: Record<string, number>;
    averageDiscrepancy: number;
    maxDiscrepancy: number;
  }> {
    const activeQueue = await prisma.queueEntry.findMany({
      where: {
        queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
      },
      select: {
        shopId: true,
        lane: true,
        bookingId: true,
        estimatedWaitMinutes: true
      }
    });

    const mismatches = await this.detectWaitTimeMismatches(redisStore);

    const byShop: Record<string, number> = {};
    const byLane: Record<string, number> = {};
    const discrepancies: number[] = [];

    for (const mismatch of mismatches) {
      byShop[mismatch.shopId] = (byShop[mismatch.shopId] || 0) + 1;
      byLane[mismatch.lane] = (byLane[mismatch.lane] || 0) + 1;
      discrepancies.push(mismatch.discrepancy);
    }

    const averageDiscrepancy = discrepancies.length > 0
      ? discrepancies.reduce((sum, d) => sum + d, 0) / discrepancies.length
      : 0;
    const maxDiscrepancy = discrepancies.length > 0
      ? Math.max(...discrepancies)
      : 0;

    return {
      totalActiveQueue: activeQueue.length,
      mismatches: mismatches.length,
      byShop,
      byLane,
      averageDiscrepancy,
      maxDiscrepancy
    };
  }

  /**
   * Manually recalculate wait times for a specific shop
   */
  async recalculateShopWaitTimes(shopId: string, waitTimeEngine: any): Promise<{
    lanesRecalculated: number;
  }> {
    const lanes: QueueLane[] = ["BOOKBER", "WALKIN"];
    let recalculated = 0;

    for (const lane of lanes) {
      await this.transactionManager.recalculateWaitTimes(shopId, lane, waitTimeEngine);
      recalculated++;
    }

    return {
      lanesRecalculated: recalculated
    };
  }
}
