import { prisma } from "../../../shared/prisma/client.js";
import { DEFAULT_RECOVERY_CONFIG } from "./recovery-types.js";
/**
 * Recovery transaction manager for safe recovery operations.
 *
 * This manager ensures that recovery operations are performed safely
 * with proper transaction boundaries, logging, and rollback capabilities.
 */
export class RecoveryTransactionManager {
    config;
    events = [];
    constructor(config = {}) {
        this.config = { ...DEFAULT_RECOVERY_CONFIG, ...config };
    }
    /**
     * Log a recovery event
     */
    logEvent(type, shopId, severity, message, metadata = {}) {
        const event = {
            id: crypto.randomUUID(),
            type,
            shopId,
            severity,
            message,
            metadata,
            recoveredAt: new Date()
        };
        this.events.push(event);
    }
    /**
     * Get all logged events
     */
    getEvents() {
        return [...this.events];
    }
    /**
     * Clear logged events
     */
    clearEvents() {
        this.events.length = 0;
    }
    /**
     * Recover an orphaned chair
     */
    async recoverOrphanedChair(chairId, shopId, reason) {
        await prisma.$transaction(async (tx) => {
            const chair = await tx.chair.findUnique({
                where: { id: chairId },
                include: { shop: true }
            });
            if (!chair) {
                this.logEvent("CHAIR_RECOVERED", shopId, "ERROR", "Chair not found", { chairId });
                throw new Error("Chair not found");
            }
            if (chair.status !== "OCCUPIED") {
                this.logEvent("CHAIR_RECOVERED", shopId, "WARNING", "Chair not occupied", { chairId, status: chair.status });
                return;
            }
            // Release any active allocation
            await tx.chairAllocation.updateMany({
                where: { chairId, releasedAt: null },
                data: { releasedAt: new Date(), activeServiceEnd: new Date() }
            });
            // Reset chair to available
            await tx.chair.update({
                where: { id: chairId },
                data: {
                    status: "AVAILABLE",
                    activeServiceStart: null,
                    activeServiceEnd: new Date()
                }
            });
            this.logEvent("CHAIR_RECOVERED", shopId, "INFO", "Orphaned chair recovered", {
                chairId,
                number: chair.number,
                reason
            });
        });
    }
    /**
     * Flag a stale service
     */
    async flagStaleService(bookingId, shopId, reason, timeoutMinutes) {
        await prisma.$transaction(async (tx) => {
            const booking = await tx.booking.findUnique({
                where: { id: bookingId },
                include: { queueEntry: true, chair: true }
            });
            if (!booking) {
                this.logEvent("SERVICE_FLAGGED", shopId, "ERROR", "Booking not found", { bookingId });
                throw new Error("Booking not found");
            }
            if (booking.status !== "IN_SERVICE") {
                this.logEvent("SERVICE_FLAGGED", shopId, "WARNING", "Booking not in service", { bookingId, status: booking.status });
                return;
            }
            // Add flag to booking metadata or create a recovery record
            await tx.queueEvent.create({
                data: {
                    shopId,
                    bookingId,
                    type: "ENQUEUED", // Use valid QueueEventType, store reason in payload
                    payload: { reason, timeoutMinutes, flaggedAt: new Date().toISOString(), isRecoveryFlag: true }
                }
            });
            this.logEvent("SERVICE_FLAGGED", shopId, "WARNING", "Stale service flagged", {
                bookingId,
                userId: booking.userId,
                chairId: booking.chairId,
                reason,
                timeoutMinutes
            });
        });
    }
    /**
     * Recover a dead queue entry
     */
    async recoverDeadQueueEntry(activeQueueId, bookingId, shopId, lane, reason) {
        await prisma.$transaction(async (tx) => {
            const activeQueue = await tx.queueEntry.findUnique({
                where: { id: activeQueueId },
                include: { booking: true }
            });
            if (!activeQueue) {
                this.logEvent("QUEUE_ENTRY_RECOVERED", shopId, "ERROR", "Queue entry not found", { activeQueueId });
                throw new Error("Queue entry not found");
            }
            // Remove dead queue entry
            await tx.queueEntry.delete({
                where: { id: activeQueueId }
            });
            // Update booking status if needed
            if (activeQueue.booking && activeQueue.booking.status === "IN_SERVICE") {
                await tx.booking.update({
                    where: { id: bookingId },
                    data: {
                        status: "CANCELLED",
                        queueStatus: "CANCELLED",
                        cancellationReason: reason
                    }
                });
            }
            this.logEvent("QUEUE_ENTRY_RECOVERED", shopId, "INFO", "Dead queue entry recovered", {
                activeQueueId,
                bookingId,
                lane,
                reason
            });
        });
    }
    /**
     * Normalize stale positions
     */
    async normalizeStalePositions(shopId, lane) {
        await prisma.$transaction(async (tx) => {
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
            for (let i = 0; i < activeQueue.length; i++) {
                const newPosition = (i + 1) * POSITION_INCREMENT;
                const entry = activeQueue[i];
                if (!entry)
                    continue;
                await tx.queueEntry.update({
                    where: { id: entry.id },
                    data: { position: newPosition, version: { increment: 1 } }
                });
            }
            this.logEvent("POSITION_NORMALIZED", shopId, "INFO", "Positions normalized", {
                lane,
                entriesUpdated: activeQueue.length
            });
        });
    }
    /**
     * Rebuild Redis queue from PostgreSQL
     */
    async rebuildRedisQueue(shopId, lane, redisStore) {
        await prisma.$transaction(async (tx) => {
            const activeQueue = await tx.queueEntry.findMany({
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
            // Clear existing Redis queue
            await redisStore.clearQueue(shopId, lane);
            // Rebuild from PostgreSQL
            for (const entry of activeQueue) {
                await redisStore.enqueueMember(shopId, {
                    bookingId: entry.bookingId,
                    lane,
                    position: entry.position,
                    estimatedWaitMinutes: entry.estimatedWaitMinutes,
                    queueStatus: entry.queueStatus,
                    userId: entry.booking.userId,
                    serviceId: entry.booking.serviceId,
                    barberId: entry.booking.barberId ?? null
                });
            }
            this.logEvent("REDIS_REBUILT", shopId, "INFO", "Redis queue rebuilt from PostgreSQL", {
                lane,
                entriesRebuilt: activeQueue.length
            });
        });
    }
    /**
     * Recalculate wait times for a lane
     */
    async recalculateWaitTimes(shopId, lane, waitTimeEngine) {
        await prisma.$transaction(async (tx) => {
            const recalc = await waitTimeEngine.recalculateLane(shopId, lane, "RECOVERY");
            const durationMap = new Map(recalc.estimates.map((e) => [e.bookingId, e.effectiveDurationMinutes]));
            await waitTimeEngine.persistence.applyEstimatesToDatabase(tx, shopId, recalc.estimates, durationMap);
            this.logEvent("WAIT_TIME_RECALCULATED", shopId, "INFO", "Wait times recalculated", {
                lane,
                estimatesUpdated: recalc.estimates.length
            });
        });
    }
    /**
     * Execute a recovery operation with error handling
     */
    async executeRecovery(operation, eventType, shopId, operationName) {
        try {
            return await operation();
        }
        catch (error) {
            this.logEvent(eventType, shopId, "ERROR", `Recovery operation failed: ${operationName}`, { error: error instanceof Error ? error.message : String(error) });
            return null;
        }
    }
}
