import { prisma } from "../../../shared/prisma/client.js";
import { DEFAULT_RECOVERY_CONFIG } from "./recovery-types.js";
import { RecoveryTransactionManager } from "./recovery-transaction-manager.js";
/**
 * Chair recovery worker.
 *
 * Detects and recovers orphaned chairs that are stuck in OCCUPIED state
 * without an active booking. This can happen when:
 * - Booking is cancelled but chair not released
 * - Booking is completed but chair not released
 * - System crash during service
 * - Chair allocation record is orphaned
 */
export class ChairRecoveryWorker {
    config;
    transactionManager;
    intervalMs;
    lock;
    constructor(lock, config = {}, intervalMs = 10 * 60 * 1000 // Default: 10 minutes
    ) {
        this.config = { ...DEFAULT_RECOVERY_CONFIG, ...config };
        this.transactionManager = new RecoveryTransactionManager(this.config);
        this.intervalMs = intervalMs;
        this.lock = lock;
    }
    /**
     * Detect orphaned chairs across all active shops
     */
    async detectOrphanedChairs() {
        const orphanedChairs = [];
        const shops = await prisma.shop.findMany({
            where: { isActive: true },
            select: { id: true }
        });
        for (const shop of shops) {
            const shopOrphanedChairs = await this.detectOrphanedChairsForShop(shop.id);
            orphanedChairs.push(...shopOrphanedChairs);
        }
        return orphanedChairs;
    }
    /**
     * Detect orphaned chairs for a specific shop
     */
    async detectOrphanedChairsForShop(shopId) {
        const orphanedChairs = [];
        const now = new Date();
        const timeoutThreshold = new Date(now.getTime() - this.config.chairOrphanTimeoutHours * 60 * 60 * 1000);
        const occupiedChairs = await prisma.chair.findMany({
            where: {
                shopId,
                status: "OCCUPIED",
                activeServiceStart: { lt: timeoutThreshold }
            },
            include: {
                chairAllocations: {
                    where: { releasedAt: null },
                    include: { booking: true }
                }
            }
        });
        for (const chair of occupiedChairs) {
            const activeAllocation = chair.chairAllocations[0];
            let reason = "TIMEOUT";
            if (!activeAllocation) {
                reason = "NO_ACTIVE_BOOKING";
            }
            else if (activeAllocation.booking) {
                const booking = activeAllocation.booking;
                if (booking.status === "COMPLETED") {
                    reason = "BOOKING_COMPLETED";
                }
                else if (booking.status === "CANCELLED") {
                    reason = "BOOKING_CANCELLED";
                }
            }
            const hoursSinceService = Math.floor((now.getTime() - chair.activeServiceStart.getTime()) / (60 * 60 * 1000));
            orphanedChairs.push({
                chairId: chair.id,
                shopId: chair.shopId,
                number: chair.number,
                status: chair.status,
                lastBookingId: activeAllocation?.bookingId ?? null,
                lastServiceStart: chair.activeServiceStart,
                hoursSinceService,
                reason
            });
        }
        return orphanedChairs;
    }
    /**
     * Auto-recover orphaned chairs
     */
    async recoverOrphanedChairs(orphanedChairs) {
        if (!this.config.enableAutoRecovery) {
            return 0;
        }
        let recovered = 0;
        for (const orphanedChair of orphanedChairs) {
            await this.transactionManager.executeRecovery(() => this.transactionManager.recoverOrphanedChair(orphanedChair.chairId, orphanedChair.shopId, orphanedChair.reason), "CHAIR_RECOVERED", orphanedChair.shopId, "Recover orphaned chair");
            if (this.transactionManager.getEvents().length > 0) {
                recovered++;
            }
        }
        return recovered;
    }
    /**
     * Run the chair recovery worker
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
                    await this.lock.withLock(`shop:${shop.id}:chair-recovery`, 30000, async () => {
                        const orphanedChairs = await this.detectOrphanedChairsForShop(shop.id);
                        if (orphanedChairs.length > 0) {
                            const recovered = await this.recoverOrphanedChairs(orphanedChairs);
                            stats.chairsRecovered += recovered;
                        }
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
                        console.log(`Chair recovery lock busy for shop ${shop.id}, skipping`);
                    }
                    else {
                        console.error(`Chair recovery failed for shop ${shop.id}:`, error);
                    }
                }
            }
        }
        catch (error) {
            console.error("Chair recovery worker failed:", error);
        }
        return stats;
    }
    /**
     * Start the periodic worker
     */
    start() {
        const interval = setInterval(() => {
            this.run().catch((error) => {
                console.error("Chair recovery worker failed:", error);
            });
        }, this.intervalMs);
        // Run immediately on start
        this.run().catch((error) => {
            console.error("Chair recovery worker failed:", error);
        });
        return () => clearInterval(interval);
    }
    /**
     * Get statistics for monitoring
     */
    async getStats() {
        const now = new Date();
        const timeoutThreshold = new Date(now.getTime() - this.config.chairOrphanTimeoutHours * 60 * 60 * 1000);
        const occupiedChairs = await prisma.chair.findMany({
            where: {
                status: "OCCUPIED"
            },
            include: {
                chairAllocations: {
                    where: { releasedAt: null },
                    include: { booking: true }
                }
            }
        });
        const orphanedChairs = occupiedChairs.filter(c => c.activeServiceStart && c.activeServiceStart < timeoutThreshold);
        const byReason = {};
        const byShop = {};
        for (const chair of orphanedChairs) {
            const activeAllocation = chair.chairAllocations[0];
            let reason = "TIMEOUT";
            if (!activeAllocation) {
                reason = "NO_ACTIVE_BOOKING";
            }
            else if (activeAllocation.booking) {
                const booking = activeAllocation.booking;
                if (booking.status === "COMPLETED") {
                    reason = "BOOKING_COMPLETED";
                }
                else if (booking.status === "CANCELLED") {
                    reason = "BOOKING_CANCELLED";
                }
            }
            byReason[reason] = (byReason[reason] || 0) + 1;
            byShop[chair.shopId] = (byShop[chair.shopId] || 0) + 1;
        }
        return {
            totalOccupiedChairs: occupiedChairs.length,
            orphanedChairs: orphanedChairs.length,
            byReason,
            byShop
        };
    }
    /**
     * Manually recover a specific chair
     */
    async recoverChair(chairId) {
        const chair = await prisma.chair.findUnique({
            where: { id: chairId },
            include: {
                shop: true,
                chairAllocations: {
                    where: { releasedAt: null },
                    include: { booking: true }
                }
            }
        });
        if (!chair) {
            throw new Error("Chair not found");
        }
        const activeAllocation = chair.chairAllocations[0];
        let reason = "MANUAL_RECOVERY";
        if (!activeAllocation) {
            reason = "NO_ACTIVE_BOOKING";
        }
        else if (activeAllocation.booking) {
            const booking = activeAllocation.booking;
            if (booking.status === "COMPLETED") {
                reason = "BOOKING_COMPLETED";
            }
            else if (booking.status === "CANCELLED") {
                reason = "BOOKING_CANCELLED";
            }
        }
        await this.transactionManager.recoverOrphanedChair(chairId, chair.shopId, reason);
    }
}
