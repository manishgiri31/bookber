import { prisma } from "../../../shared/prisma/client.js";
import { SparsePositionAllocator } from "./sparse-position-allocator.service.js";
/**
 * Periodic job to normalize queue positions.
 *
 * This job runs on a schedule (e.g., every hour) to normalize queue lanes
 * that have grown too large or have gaps that are too small. Normalization
 * is an O(n) operation but should be rare with sparse positioning.
 *
 * The job:
 * 1. Scans all active shops
 * 2. Checks each lane for rebalancing/normalization needs
 * 3. Normalizes lanes that need it
 * 4. Updates Redis with new positions
 * 5. Emits queue updated events
 */
export class QueueNormalizationJob {
    positionAllocator;
    intervalMs;
    constructor(intervalMs = 60 * 60 * 1000) {
        this.positionAllocator = new SparsePositionAllocator();
        this.intervalMs = intervalMs;
    }
    /**
     * Run the normalization job once.
     * This can be called manually or scheduled.
     */
    async run() {
        const shops = await prisma.shop.findMany({
            where: { isActive: true },
            select: { id: true }
        });
        let normalizedShops = 0;
        let normalizedLanes = 0;
        for (const shop of shops) {
            const lanes = ["BOOKBER", "WALKIN"];
            let shopNormalized = false;
            for (const lane of lanes) {
                const needsRebalancing = await this.positionAllocator.needsRebalancing(prisma, shop.id, lane);
                const needsNormalization = await this.positionAllocator.needsNormalization(prisma, shop.id, lane);
                if (needsRebalancing || needsNormalization) {
                    await prisma.$transaction(async (tx) => {
                        await this.positionAllocator.normalizeLane(tx, shop.id, lane);
                        // Update Redis with new positions
                        const activeQueue = await tx.queueEntry.findMany({
                            where: {
                                shopId: shop.id,
                                lane,
                                queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
                            },
                            orderBy: { position: "asc" },
                            select: { bookingId: true, position: true, estimatedWaitMinutes: true }
                        });
                        // Note: Redis update would be done here if we had access to Redis
                        // This is a placeholder for the actual Redis update logic
                        // await this.redisStore.updatePositions(shop.id, lane, activeQueue);
                    });
                    normalizedLanes++;
                    shopNormalized = true;
                }
            }
            if (shopNormalized) {
                normalizedShops++;
            }
        }
        return { normalizedShops, normalizedLanes };
    }
    /**
     * Start the periodic job.
     * Returns a cleanup function to stop the job.
     */
    start() {
        const interval = setInterval(() => {
            this.run().catch((error) => {
                console.error("Queue normalization job failed:", error);
            });
        }, this.intervalMs);
        // Run immediately on start
        this.run().catch((error) => {
            console.error("Queue normalization job failed:", error);
        });
        return () => clearInterval(interval);
    }
    /**
     * Normalize a specific shop's lanes.
     * Useful for manual normalization or triggered normalization.
     */
    async normalizeShop(shopId) {
        const lanes = ["BOOKBER", "WALKIN"];
        let normalizedLanes = 0;
        for (const lane of lanes) {
            const needsRebalancing = await this.positionAllocator.needsRebalancing(prisma, shopId, lane);
            const needsNormalization = await this.positionAllocator.needsNormalization(prisma, shopId, lane);
            if (needsRebalancing || needsNormalization) {
                await prisma.$transaction(async (tx) => {
                    await this.positionAllocator.normalizeLane(tx, shopId, lane);
                    // Update Redis with new positions
                    const activeQueue = await tx.queueEntry.findMany({
                        where: {
                            shopId,
                            lane,
                            queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
                        },
                        orderBy: { position: "asc" },
                        select: { bookingId: true, position: true, estimatedWaitMinutes: true }
                    });
                    // Note: Redis update would be done here if we had access to Redis
                    // await this.redisStore.updatePositions(shopId, lane, activeQueue);
                });
                normalizedLanes++;
            }
        }
        return { normalizedLanes };
    }
    /**
     * Get statistics about queue position health.
     * Useful for monitoring and alerting.
     */
    async getHealthStats() {
        const shops = await prisma.shop.findMany({
            where: { isActive: true },
            select: { id: true }
        });
        let shopsNeedingNormalization = 0;
        let lanesNeedingNormalization = 0;
        let maxPosition = 0;
        let minGap = Infinity;
        for (const shop of shops) {
            const lanes = ["BOOKBER", "WALKIN"];
            let shopNeedsNormalization = false;
            for (const lane of lanes) {
                const needsRebalancing = await this.positionAllocator.needsRebalancing(prisma, shop.id, lane);
                const needsNormalization = await this.positionAllocator.needsNormalization(prisma, shop.id, lane);
                if (needsRebalancing || needsNormalization) {
                    lanesNeedingNormalization++;
                    shopNeedsNormalization = true;
                }
                // Track max position
                const maxPos = await prisma.queueEntry.aggregate({
                    where: {
                        shopId: shop.id,
                        lane,
                        queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
                    },
                    _max: { position: true }
                });
                maxPosition = Math.max(maxPosition, maxPos._max.position ?? 0);
                // Track min gap
                const activeQueue = await prisma.queueEntry.findMany({
                    where: {
                        shopId: shop.id,
                        lane,
                        queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
                    },
                    orderBy: { position: "asc" },
                    select: { position: true }
                });
                for (let i = 0; i < activeQueue.length - 1; i++) {
                    const current = activeQueue[i];
                    const next = activeQueue[i + 1];
                    if (current !== undefined && next !== undefined) {
                        const gap = next.position - current.position;
                        minGap = Math.min(minGap, gap);
                    }
                }
            }
            if (shopNeedsNormalization) {
                shopsNeedingNormalization++;
            }
        }
        return {
            totalShops: shops.length,
            shopsNeedingNormalization,
            lanesNeedingNormalization,
            maxPosition,
            minGap: minGap === Infinity ? 0 : minGap
        };
    }
    /**
     * Force normalize a specific shop (emergency recovery).
     * This will normalize regardless of thresholds.
     */
    async forceNormalizeShop(shopId) {
        const lanes = ["BOOKBER", "WALKIN"];
        let normalizedLanes = 0;
        for (const lane of lanes) {
            await prisma.$transaction(async (tx) => {
                await this.positionAllocator.normalizeLane(tx, shopId, lane);
                // Update Redis with new positions
                const activeQueue = await tx.queueEntry.findMany({
                    where: {
                        shopId,
                        lane,
                        queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
                    },
                    orderBy: { position: "asc" },
                    select: { bookingId: true, position: true, estimatedWaitMinutes: true }
                });
                // Note: Redis update would be done here if we had access to Redis
                // await this.redisStore.updatePositions(shopId, lane, activeQueue);
            });
            normalizedLanes++;
        }
        return { normalizedLanes };
    }
}
