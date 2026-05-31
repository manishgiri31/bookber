import type { Redis as RedisClient } from "ioredis";
import type { QueueLane } from "@prisma/client";
import { prisma } from "../../../shared/prisma/client.js";
import type { RedisMismatch, RecoveryConfig, RecoveryStats } from "./recovery-types.js";
import { DEFAULT_RECOVERY_CONFIG } from "./recovery-types.js";
import { RecoveryTransactionManager } from "./recovery-transaction-manager.js";
import { waitTimeRedisKeys } from "../../../shared/redis/wait-time-redis.keys.js";
import { QueueLock } from "../queue.lock.js";

/**
 * Redis repair service.
 * 
 * Detects and repairs Redis state inconsistencies with PostgreSQL.
 * This can happen when:
 * - Redis cache is stale or corrupted
 * - Queue state changes are not propagated to Redis
 * - Redis eviction removes queue data
 * - Network issues cause Redis desync
 */
export class RedisRepairService {
  private readonly config: RecoveryConfig;
  private readonly transactionManager: RecoveryTransactionManager;
  private readonly intervalMs: number;
  private readonly lock: QueueLock;

  constructor(
    lock: QueueLock,
    config: Partial<RecoveryConfig> = {},
    intervalMs: number = 30 * 60 * 1000 // Default: 30 minutes
  ) {
    this.config = { ...DEFAULT_RECOVERY_CONFIG, ...config };
    this.transactionManager = new RecoveryTransactionManager(this.config);
    this.intervalMs = intervalMs;
    this.lock = lock;
  }

  /**
   * Detect Redis mismatches across all active shops
   */
  async detectRedisMismatches(redis: RedisClient): Promise<RedisMismatch[]> {
    const mismatches: RedisMismatch[] = [];

    const shops = await prisma.shop.findMany({
      where: { isActive: true },
      select: { id: true }
    });

    for (const shop of shops) {
      const shopMismatches = await this.detectRedisMismatchesForShop(shop.id, redis);
      if (shopMismatches.length > 0) {
        mismatches.push(...shopMismatches);
      }
    }

    return mismatches;
  }

  /**
   * Detect Redis mismatches for a specific shop
   */
  async detectRedisMismatchesForShop(shopId: string, redis: RedisClient): Promise<RedisMismatch[]> {
    const mismatches: RedisMismatch[] = [];
    const lanes: QueueLane[] = ["BOOKBER", "WALKIN"];

    for (const lane of lanes) {
      const laneMismatch = await this.detectRedisMismatchForLane(shopId, lane, redis);
      if (laneMismatch) {
        mismatches.push(laneMismatch);
      }
    }

    return mismatches;
  }

  /**
   * Detect Redis mismatch for a specific lane
   */
  async detectRedisMismatchForLane(shopId: string, lane: QueueLane, redis: RedisClient): Promise<RedisMismatch | null> {
    // Get DB queue length
    const dbQueueLength = await prisma.queueEntry.count({
      where: {
        shopId,
        lane,
        queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
      }
    });

    // Get Redis queue length
    const redisQueueLength = await redis.zcard(waitTimeRedisKeys.queue(shopId, lane));

    // If lengths match, check for individual booking mismatches
    if (dbQueueLength === redisQueueLength) {
      const mismatchedBookings = await this.detectBookingLevelMismatches(shopId, lane, redis);

      if (mismatchedBookings.length > 0) {
        return {
          shopId,
          lane,
          dbQueueLength,
          redisQueueLength,
          mismatchedBookings
        };
      }

      return null;
    }

    // Length mismatch - get detailed mismatch info
    const mismatchedBookings = await this.detectBookingLevelMismatches(shopId, lane, redis);

    return {
      shopId,
      lane,
      dbQueueLength,
      redisQueueLength,
      mismatchedBookings
    };
  }

  /**
   * Detect booking-level mismatches between DB and Redis
   */
  private async detectBookingLevelMismatches(shopId: string, lane: QueueLane, redis: RedisClient): Promise<Array<{
    bookingId: string;
    dbStatus: string;
    redisStatus: string;
    dbPosition: number;
    redisPosition: number;
  }>> {
    const mismatchedBookings: Array<{
      bookingId: string;
      dbStatus: string;
      redisStatus: string;
      dbPosition: number;
      redisPosition: number;
    }> = [];

    const dbQueue = await prisma.queueEntry.findMany({
      where: {
        shopId,
        lane,
        queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
      },
      select: {
        bookingId: true,
        queueStatus: true,
        position: true
      },
      orderBy: { position: "asc" }
    });

    const redisQueueIds = await redis.zrange(waitTimeRedisKeys.queue(shopId, lane), 0, -1);

    // Check for bookings in DB but not in Redis
    for (const dbEntry of dbQueue) {
      const redisIndex = redisQueueIds.indexOf(dbEntry.bookingId);

      if (redisIndex === -1) {
        mismatchedBookings.push({
          bookingId: dbEntry.bookingId,
          dbStatus: dbEntry.queueStatus,
          redisStatus: "MISSING",
          dbPosition: dbEntry.position,
          redisPosition: -1
        });
      } else {
        // Check if positions match
        const redisPosition = redisIndex + 1; // Redis is 0-indexed, DB is 1-indexed
        if (Math.abs(dbEntry.position - redisPosition * 100) > 10) {
          mismatchedBookings.push({
            bookingId: dbEntry.bookingId,
            dbStatus: dbEntry.queueStatus,
            redisStatus: "POSITION_MISMATCH",
            dbPosition: dbEntry.position,
            redisPosition: redisPosition * 100
          });
        }
      }
    }

    // Check for bookings in Redis but not in DB
    for (let i = 0; i < redisQueueIds.length; i++) {
      const bookingId = redisQueueIds[i];
      if (!bookingId) continue;

      const dbEntry = dbQueue.find(q => q.bookingId === bookingId);

      if (!dbEntry) {
        mismatchedBookings.push({
          bookingId,
          dbStatus: "MISSING",
          redisStatus: "ORPHANED",
          dbPosition: -1,
          redisPosition: (i + 1) * 100
        });
      }
    }

    return mismatchedBookings;
  }

  /**
   * Auto-rebuild Redis queues for mismatched shops
   */
  async rebuildRedisQueues(mismatches: RedisMismatch[], redis: RedisClient): Promise<number> {
    if (!this.config.enableRedisRebuild) {
      return 0;
    }

    const affectedShops = new Set<string>();

    for (const mismatch of mismatches) {
      // Only rebuild if mismatch exceeds threshold
      if (mismatch.mismatchedBookings.length >= this.config.redisRebuildThreshold) {
        affectedShops.add(mismatch.shopId);
      }
    }

    let rebuilt = 0;

    for (const shopId of affectedShops) {
      await this.transactionManager.executeRecovery(
        () => this.rebuildShopRedisQueue(shopId, redis),
        "REDIS_REBUILT",
        shopId,
        "Rebuild Redis queue"
      );

      if (this.transactionManager.getEvents().length > 0) {
        rebuilt++;
      }
    }

    return rebuilt;
  }

  /**
   * Rebuild Redis queue for a specific shop
   */
  private async rebuildShopRedisQueue(shopId: string, redis: RedisClient): Promise<void> {
    const lanes: QueueLane[] = ["BOOKBER", "WALKIN"];

    for (const lane of lanes) {
      await this.rebuildLaneRedisQueue(shopId, lane, redis);
    }
  }

  /**
   * Rebuild Redis queue for a specific lane
   */
  private async rebuildLaneRedisQueue(shopId: string, lane: QueueLane, redis: RedisClient): Promise<void> {
    // Clear existing Redis queue
    const queueKey = waitTimeRedisKeys.queue(shopId, lane);
    await redis.del(queueKey);

    // Rebuild from PostgreSQL
    const activeQueue = await prisma.queueEntry.findMany({
      where: {
        shopId,
        lane,
        queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
      },
      orderBy: { position: "asc" },
      include: {
        booking: {
          include: { service: true, barber: true, user: true }
        }
      }
    });

    // Rebuild queue
    for (const entry of activeQueue) {
      await redis.zadd(queueKey, entry.position, entry.bookingId);

      // Rebuild booking snapshot
      const bookingKey = waitTimeRedisKeys.booking(entry.bookingId);
      await redis.hset(bookingKey, {
        shopId: entry.shopId,
        lane: entry.lane,
        position: String(entry.position),
        serviceId: entry.booking.serviceId,
        serviceCategory: entry.booking.service.category ?? "HAIRCUT",
        barberId: entry.booking.barberId ?? "",
        catalogDurationMinutes: String(entry.booking.service.durationMinutes),
        queueStatus: entry.queueStatus,
        estimatedWaitMinutes: String(entry.estimatedWaitMinutes),
        estimatedServiceStartIso: entry.estimatedServiceStart?.toISOString() ?? "",
        inServiceRemainingMinutes: "0"
      });
    }
  }

  /**
   * Run the Redis repair service
   */
  async run(redis: RedisClient): Promise<RecoveryStats> {
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
          await this.lock.withLock(`shop:${shop.id}:redis-repair`, 30000, async () => {
            const mismatches = await this.detectRedisMismatchesForShop(shop.id, redis);

            if (mismatches.length > 0) {
              const rebuilt = await this.rebuildRedisQueues(mismatches, redis);
              stats.redisRebuilt += rebuilt;
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
            console.log(`Redis repair lock busy for shop ${shop.id}, skipping`);
          } else {
            console.error(`Redis repair failed for shop ${shop.id}:`, error);
          }
        }
      }
    } catch (error) {
      console.error("Redis repair service failed:", error);
    }

    return stats;
  }

  /**
   * Start the periodic service
   */
  start(redis: RedisClient): () => void {
    const interval = setInterval(() => {
      this.run(redis).catch((error) => {
        console.error("Redis repair service failed:", error);
      });
    }, this.intervalMs);

    // Run immediately on start
    this.run(redis).catch((error) => {
      console.error("Redis repair service failed:", error);
    });

    return () => clearInterval(interval);
  }

  /**
   * Get statistics for monitoring
   */
  async getStats(redis: RedisClient): Promise<{
    totalShops: number;
    mismatchedShops: number;
    mismatchedLanes: number;
    totalMismatches: number;
    byShop: Record<string, number>;
    byLane: Record<string, number>;
  }> {
    const shops = await prisma.shop.findMany({
      where: { isActive: true },
      select: { id: true }
    });

    let mismatchedShops = 0;
    let mismatchedLanes = 0;
    let totalMismatches = 0;
    const byShop: Record<string, number> = {};
    const byLane: Record<string, number> = {};

    for (const shop of shops) {
      const shopMismatches = await this.detectRedisMismatchesForShop(shop.id, redis);

      if (shopMismatches.length > 0) {
        mismatchedShops++;
        byShop[shop.id] = shopMismatches.length;
        mismatchedLanes += shopMismatches.length;
        totalMismatches += shopMismatches.reduce((sum, m) => sum + m.mismatchedBookings.length, 0);

        for (const mismatch of shopMismatches) {
          byLane[mismatch.lane] = (byLane[mismatch.lane] || 0) + mismatch.mismatchedBookings.length;
        }
      }
    }

    return {
      totalShops: shops.length,
      mismatchedShops,
      mismatchedLanes,
      totalMismatches,
      byShop,
      byLane
    };
  }

  /**
   * Manually rebuild Redis queue for a specific shop
   */
  async rebuildShopRedis(shopId: string, redis: RedisClient): Promise<void> {
    await this.rebuildShopRedisQueue(shopId, redis);
  }

  /**
   * Manually rebuild Redis queue for a specific lane
   */
  async rebuildLaneRedis(shopId: string, lane: QueueLane, redis: RedisClient): Promise<void> {
    await this.rebuildLaneRedisQueue(shopId, lane, redis);
  }

  /**
   * Clear all Redis data for a shop (emergency recovery)
   */
  async clearShopRedis(shopId: string, redis: RedisClient): Promise<void> {
    const lanes: QueueLane[] = ["BOOKBER", "WALKIN"];

    for (const lane of lanes) {
      const queueKey = waitTimeRedisKeys.queue(shopId, lane);
      await redis.del(queueKey);
    }

    // Clear booking snapshots for this shop
    const activeQueue = await prisma.queueEntry.findMany({
      where: {
        shopId,
        queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
      },
      select: { bookingId: true }
    });

    for (const entry of activeQueue) {
      const bookingKey = waitTimeRedisKeys.booking(entry.bookingId);
      await redis.del(bookingKey);
    }

    // Clear wait version
    const waitVersionKey = waitTimeRedisKeys.waitVersion(shopId);
    await redis.del(waitVersionKey);

    // Clear queue version
    const queueVersionKey = waitTimeRedisKeys.queueVersion(shopId);
    await redis.del(queueVersionKey);
  }
}
