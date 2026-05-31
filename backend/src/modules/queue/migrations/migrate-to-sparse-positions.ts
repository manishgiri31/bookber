import type { Prisma, QueueLane } from "@prisma/client";
import { prisma } from "../../../shared/prisma/client.js";

/**
 * Migration strategy for converting sequential queue positions to sparse positions.
 * 
 * This migration:
 * 1. Converts existing sequential positions (1, 2, 3...) to sparse positions (100, 200, 300...)
 * 2. Preserves ordering
 * 3. Updates both ActiveQueue and Booking tables
 * 4. Updates Redis sorted sets
 * 5. Can be run safely on production data
 */
export class SparsePositionMigration {
  /**
   * Migrate a specific shop's queue positions to sparse format
   */
  async migrateShop(shopId: string, redis: any): Promise<{
    bookberEntriesMigrated: number;
    walkinEntriesMigrated: number;
    totalMigrated: number;
  }> {
    const lanes: QueueLane[] = ["BOOKBER", "WALKIN"];
    let totalMigrated = 0;

    for (const lane of lanes) {
      const migrated = await this.migrateLane(shopId, lane, redis);
      totalMigrated += migrated;
    }

    return {
      bookberEntriesMigrated: await this.getLaneCount(shopId, "BOOKBER"),
      walkinEntriesMigrated: await this.getLaneCount(shopId, "WALKIN"),
      totalMigrated
    };
  }

  /**
   * Migrate a specific lane to sparse positions
   */
  async migrateLane(shopId: string, lane: QueueLane, redis: any): Promise<number> {
    return await prisma.$transaction(async (tx) => {
      // Get all active queue entries ordered by current position
      const activeQueue = await tx.queueEntry.findMany({
        where: {
          shopId,
          lane,
          queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
        },
        orderBy: { position: "asc" },
        select: { id: true, bookingId: true, position: true }
      });

      const POSITION_INCREMENT = 100;
      let migrated = 0;

      for (let i = 0; i < activeQueue.length; i++) {
        const entry = activeQueue[i];
        if (!entry) continue;

        const newPosition = (i + 1) * POSITION_INCREMENT;

        // Skip if already in sparse format
        if (entry.position === newPosition) {
          continue;
        }

        // Update ActiveQueue position
        await tx.queueEntry.update({
          where: { id: entry.id },
          data: { position: newPosition, version: { increment: 1 } }
        });

        // Update Booking queuePosition
        await tx.booking.updateMany({
          where: { id: entry.bookingId },
          data: { queuePosition: newPosition }
        });

        // Update Redis if available
        if (redis) {
          await this.updateRedisPosition(redis, shopId, lane, entry.bookingId, newPosition);
        }

        migrated++;
      }

      return migrated;
    });
  }

  /**
   * Update Redis position for a booking
   */
  private async updateRedisPosition(
    redis: any,
    shopId: string,
    lane: QueueLane,
    bookingId: string,
    newPosition: number
  ): Promise<void> {
    try {
      const { waitTimeRedisKeys } = await import("../../../shared/redis/wait-time-redis.keys.js");
      const queueKey = waitTimeRedisKeys.queue(shopId, lane);

      // Remove old position and add new position
      await redis.zrem(queueKey, bookingId);
      await redis.zadd(queueKey, newPosition, bookingId);

      // Update booking snapshot
      const bookingKey = waitTimeRedisKeys.booking(bookingId);
      await redis.hset(bookingKey, { position: String(newPosition) });
    } catch (error) {
      console.error("Failed to update Redis position:", error);
    }
  }

  /**
   * Get count of entries in a lane
   */
  private async getLaneCount(shopId: string, lane: QueueLane): Promise<number> {
    return prisma.queueEntry.count({
      where: {
        shopId,
        lane,
        queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
      }
    });
  }

  /**
   * Validate sparse position migration for a shop
   */
  async validateMigration(shopId: string): Promise<{
    isValid: boolean;
    issues: string[];
    bookberSequentialCount: number;
    walkinSequentialCount: number;
  }> {
    const lanes: QueueLane[] = ["BOOKBER", "WALKIN"];
    const issues: string[] = [];
    let bookberSequentialCount = 0;
    let walkinSequentialCount = 0;

    for (const lane of lanes) {
      const activeQueue = await prisma.queueEntry.findMany({
        where: {
          shopId,
          lane,
          queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
        },
        orderBy: { position: "asc" },
        select: { position: true }
      });

      let sequentialCount = 0;
      for (let i = 0; i < activeQueue.length; i++) {
        const entry = activeQueue[i];
        if (!entry) continue;

        const expectedPosition = (i + 1) * 100;
        if (entry.position !== expectedPosition) {
          sequentialCount++;
        }
      }

      if (lane === "BOOKBER") {
        bookberSequentialCount = sequentialCount;
      } else {
        walkinSequentialCount = sequentialCount;
      }

      if (sequentialCount > 0) {
        issues.push(`${lane} has ${sequentialCount} entries with sequential positions`);
      }
    }

    return {
      isValid: issues.length === 0,
      issues,
      bookberSequentialCount,
      walkinSequentialCount
    };
  }

  /**
   * Migrate all shops to sparse positions
   */
  async migrateAllShops(redis: any): Promise<{
    totalShops: number;
    shopsMigrated: number;
    totalEntriesMigrated: number;
    failedShops: Array<{ shopId: string; error: string }>;
  }> {
    const shops = await prisma.shop.findMany({
      where: { isActive: true },
      select: { id: true }
    });

    let shopsMigrated = 0;
    let totalEntriesMigrated = 0;
    const failedShops: Array<{ shopId: string; error: string }> = [];

    for (const shop of shops) {
      try {
        const result = await this.migrateShop(shop.id, redis);
        shopsMigrated++;
        totalEntriesMigrated += result.totalMigrated;
      } catch (error) {
        failedShops.push({
          shopId: shop.id,
          error: error instanceof Error ? error.message : String(error)
        });
      }
    }

    return {
      totalShops: shops.length,
      shopsMigrated,
      totalEntriesMigrated,
      failedShops
    };
  }
}
