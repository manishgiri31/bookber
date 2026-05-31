import { prisma } from "../../../shared/prisma/client.js";
import { DEFAULT_RECOVERY_CONFIG } from "./recovery-types.js";
import { RecoveryTransactionManager } from "./recovery-transaction-manager.js";
/**
 * Queue reconciler worker.
 *
 * Detects and recovers dead queue entries that are inconsistent with booking state.
 * This can happen when:
 * - Booking is cancelled but queue entry remains
 * - Booking is completed but queue entry remains
 * - Chair is released but queue entry remains IN_SERVICE
 * - Queue entry has stale position (needs normalization)
 */
export class QueueReconcilerWorker {
    config;
    transactionManager;
    intervalMs;
    lock;
    constructor(lock, config = {}, intervalMs = 15 * 60 * 1000 // Default: 15 minutes
    ) {
        this.config = { ...DEFAULT_RECOVERY_CONFIG, ...config };
        this.transactionManager = new RecoveryTransactionManager(this.config);
        this.intervalMs = intervalMs;
        this.lock = lock;
    }
    /**
     * Detect dead queue entries across all active shops
     */
    async detectDeadQueueEntries() {
        const deadEntries = [];
        const shops = await prisma.shop.findMany({
            where: { isActive: true },
            select: { id: true }
        });
        for (const shop of shops) {
            const shopDeadEntries = await this.detectDeadQueueEntriesForShop(shop.id);
            deadEntries.push(...shopDeadEntries);
        }
        return deadEntries;
    }
    /**
     * Detect dead queue entries for a specific shop
     */
    async detectDeadQueueEntriesForShop(shopId) {
        const deadEntries = [];
        const now = new Date();
        const staleThreshold = new Date(now.getTime() - this.config.queueEntryStaleTimeoutHours * 60 * 60 * 1000);
        const activeQueue = await prisma.queueEntry.findMany({
            where: {
                shopId,
                queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
            },
            include: {
                booking: true
            }
        });
        for (const entry of activeQueue) {
            let reason = null;
            // Check if booking is cancelled or completed
            if (entry.booking.status === "CANCELLED") {
                reason = "BOOKING_CANCELLED";
            }
            else if (entry.booking.status === "COMPLETED") {
                reason = "BOOKING_COMPLETED";
            }
            else if (entry.booking.status === "NO_SHOW") {
                reason = "BOOKING_CANCELLED";
            }
            // Check if chair is released but entry is IN_SERVICE
            if (entry.queueStatus === "IN_SERVICE" && entry.booking.chairId) {
                const chair = await prisma.chair.findUnique({
                    where: { id: entry.booking.chairId }
                });
                if (chair && chair.status !== "OCCUPIED") {
                    reason = "CHAIR_RELEASED";
                }
            }
            // Check for stale positions
            if (entry.position > this.config.positionStaleThreshold) {
                reason = "STALE_POSITION";
            }
            // Check for very old entries (stale)
            if (entry.createdAt < staleThreshold && entry.queueStatus === "WAITING") {
                reason = "STALE_POSITION";
            }
            if (reason) {
                deadEntries.push({
                    activeQueueId: entry.id,
                    bookingId: entry.bookingId,
                    shopId: entry.shopId,
                    lane: entry.lane,
                    position: entry.position,
                    queueStatus: entry.queueStatus,
                    bookingStatus: entry.booking.status,
                    reason
                });
            }
        }
        return deadEntries;
    }
    /**
     * Auto-recover dead queue entries
     */
    async recoverDeadQueueEntries(deadEntries) {
        if (!this.config.enableAutoRecovery) {
            return 0;
        }
        let recovered = 0;
        for (const deadEntry of deadEntries) {
            await this.transactionManager.executeRecovery(() => this.transactionManager.recoverDeadQueueEntry(deadEntry.activeQueueId, deadEntry.bookingId, deadEntry.shopId, deadEntry.lane, deadEntry.reason), "QUEUE_ENTRY_RECOVERED", deadEntry.shopId, "Recover dead queue entry");
            if (this.transactionManager.getEvents().length > 0) {
                recovered++;
            }
        }
        return recovered;
    }
    /**
     * Normalize stale positions
     */
    async normalizeStalePositions() {
        if (!this.config.enablePositionNormalization) {
            return 0;
        }
        let normalized = 0;
        const shops = await prisma.shop.findMany({
            where: { isActive: true },
            select: { id: true }
        });
        for (const shop of shops) {
            const lanes = ["BOOKBER", "WALKIN"];
            for (const lane of lanes) {
                const needsNormalization = await this.transactionManager.executeRecovery(() => this.checkNeedsNormalization(shop.id, lane), "POSITION_NORMALIZED", shop.id, "Check position normalization");
                if (needsNormalization) {
                    await this.transactionManager.executeRecovery(() => this.transactionManager.normalizeStalePositions(shop.id, lane), "POSITION_NORMALIZED", shop.id, "Normalize positions");
                    if (this.transactionManager.getEvents().length > 0) {
                        normalized++;
                    }
                }
            }
        }
        return normalized;
    }
    /**
     * Normalize stale positions for a specific shop
     */
    async normalizeStalePositionsForShop(shopId) {
        if (!this.config.enablePositionNormalization) {
            return 0;
        }
        let normalized = 0;
        const lanes = ["BOOKBER", "WALKIN"];
        for (const lane of lanes) {
            const needsNormalization = await this.checkNeedsNormalization(shopId, lane);
            if (needsNormalization) {
                await this.transactionManager.executeRecovery(() => this.transactionManager.normalizeStalePositions(shopId, lane), "POSITION_NORMALIZED", shopId, "Normalize positions");
                if (this.transactionManager.getEvents().length > 0) {
                    normalized++;
                }
            }
        }
        return normalized;
    }
    async checkNeedsNormalization(shopId, lane) {
        const maxPosition = await prisma.queueEntry.aggregate({
            where: {
                shopId,
                lane,
                queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
            },
            _max: { position: true }
        });
        return (maxPosition._max.position ?? 0) > this.config.positionStaleThreshold;
    }
    /**
     * Run the queue reconciler worker
     */
    async run() {
        const stats = {
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
                    await this.lock.withLock(`shop:${shop.id}:reconcile`, 30000, async () => {
                        const deadEntries = await this.detectDeadQueueEntriesForShop(shop.id);
                        if (deadEntries.length > 0) {
                            const recovered = await this.recoverDeadQueueEntries(deadEntries);
                            stats.queueEntriesRecovered += recovered;
                        }
                        const normalized = await this.normalizeStalePositionsForShop(shop.id);
                        stats.positionsNormalized += normalized;
                        const events = this.transactionManager.getEvents();
                        stats.totalEvents += events.length;
                        stats.criticalEvents += events.filter(e => e.severity === "CRITICAL").length;
                        stats.errorEvents += events.filter(e => e.severity === "ERROR").length;
                        stats.warningEvents += events.filter(e => e.severity === "WARNING").length;
                        stats.infoEvents += events.filter(e => e.severity === "INFO").length;
                        this.transactionManager.clearEvents();
                    });
                }
                catch (error) {
                    if (error instanceof Error && error.message === "QUEUE_LOCK_BUSY") {
                        console.log(`Queue reconciliation lock busy for shop ${shop.id}, skipping`);
                    }
                    else {
                        console.error(`Queue reconciliation failed for shop ${shop.id}:`, error);
                    }
                }
            }
        }
        catch (error) {
            console.error("Queue reconciler worker failed:", error);
        }
        return stats;
    }
    /**
     * Start the periodic worker
     */
    start() {
        const interval = setInterval(() => {
            this.run().catch((error) => {
                console.error("Queue reconciler worker failed:", error);
            });
        }, this.intervalMs);
        // Run immediately on start
        this.run().catch((error) => {
            console.error("Queue reconciler worker failed:", error);
        });
        return () => clearInterval(interval);
    }
    /**
     * Get statistics for monitoring
     */
    async getStats() {
        const activeQueue = await prisma.queueEntry.findMany({
            where: {
                queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
            },
            include: {
                booking: true
            }
        });
        const deadEntries = await this.detectDeadQueueEntries();
        const byReason = {};
        const byShop = {};
        const byLane = {};
        for (const entry of deadEntries) {
            byReason[entry.reason] = (byReason[entry.reason] || 0) + 1;
            byShop[entry.shopId] = (byShop[entry.shopId] || 0) + 1;
            byLane[entry.lane] = (byLane[entry.lane] || 0) + 1;
        }
        return {
            totalActiveQueue: activeQueue.length,
            deadEntries: deadEntries.length,
            byReason,
            byShop,
            byLane
        };
    }
    /**
     * Manually reconcile a specific shop
     */
    async reconcileShop(shopId) {
        const deadEntries = await this.detectDeadQueueEntriesForShop(shopId);
        const recovered = await this.recoverDeadQueueEntries(deadEntries);
        const lanes = ["BOOKBER", "WALKIN"];
        let normalized = 0;
        for (const lane of lanes) {
            const needsNormalization = await this.checkNeedsNormalization(shopId, lane);
            if (needsNormalization) {
                await this.transactionManager.normalizeStalePositions(shopId, lane);
                normalized++;
            }
        }
        return {
            deadEntriesRecovered: recovered,
            positionsNormalized: normalized
        };
    }
}
