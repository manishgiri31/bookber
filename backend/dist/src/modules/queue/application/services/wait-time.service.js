import { WAIT_RECALC_TRIGGERS } from "../../domain/wait-time.types.js";
import { prisma } from "../../../../shared/prisma/client.js";
/**
 * WaitTimeService handles wait time calculations and management.
 *
 * Responsibilities:
 * - Recalculate lane wait times
 * - Sync booking snapshots to Redis
 * - Record service overruns
 * - Record service samples
 * - Apply wait time estimates to database
 *
 * Transaction ownership: Owns wait time transactions
 * Redis ownership: Owns Redis wait time operations
 * Event ownership: Delegates to QueueRealtimeService
 */
export class WaitTimeService {
    repository;
    waitTime;
    constructor(repository, waitTime) {
        this.repository = repository;
        this.waitTime = waitTime;
    }
    /**
     * Recalculate wait times for a lane
     */
    async recalculateLane(shopId, lane, trigger) {
        const recalc = await this.waitTime.recalculateLane(shopId, lane, trigger);
        return {
            estimates: recalc.estimates
        };
    }
    /**
     * Sync booking snapshot to Redis
     */
    async syncBookingSnapshot(snapshot) {
        await this.waitTime.syncBookingSnapshot(snapshot);
    }
    /**
     * Record service overrun for a barber
     */
    async recordServiceOverrun(shopId, barberId, overrunMinutes) {
        await this.waitTime.recordServiceOverrun(shopId, barberId, overrunMinutes);
    }
    /**
     * Record service sample for a barber
     */
    async recordServiceSample(sample) {
        await this.waitTime.persistence.recordServiceSample(sample);
    }
    /**
     * Apply wait time estimates to database
     */
    async applyEstimatesToDatabase(tx, shopId, estimates, durationMap) {
        await this.waitTime.persistence.applyEstimatesToDatabase(tx, shopId, estimates, durationMap);
    }
    /**
     * Get wait time for a specific booking
     */
    async getBookingWaitTime(bookingId) {
        const activeQueue = await this.repository.findBooking(prisma, bookingId);
        if (!activeQueue)
            return 0;
        return activeQueue.queueEntry?.estimatedWaitMinutes ?? 0;
    }
    /**
     * Get lane wait times
     */
    async getLaneWaitTimes(shopId, lane) {
        const recalc = await this.waitTime.recalculateLane(shopId, lane, WAIT_RECALC_TRIGGERS.REBALANCE);
        return recalc.estimates.map(e => ({
            bookingId: e.bookingId,
            position: e.position,
            estimatedWaitMinutes: e.estimatedWaitMinutes,
            estimatedServiceStart: e.estimatedServiceStart
        }));
    }
    /**
     * Recalculate wait times for all lanes in a shop
     */
    async recalculateShop(shopId) {
        const [bookber, walkin] = await Promise.all([
            this.recalculateLane(shopId, "BOOKBER", WAIT_RECALC_TRIGGERS.REBALANCE),
            this.recalculateLane(shopId, "WALKIN", WAIT_RECALC_TRIGGERS.REBALANCE)
        ]);
        return {
            bookBerEstimates: bookber.estimates.map(e => ({
                bookingId: e.bookingId,
                position: e.position,
                estimatedWaitMinutes: e.estimatedWaitMinutes,
                estimatedServiceStart: e.estimatedServiceStart
            })),
            walkInEstimates: walkin.estimates.map(e => ({
                bookingId: e.bookingId,
                position: e.position,
                estimatedWaitMinutes: e.estimatedWaitMinutes,
                estimatedServiceStart: e.estimatedServiceStart
            }))
        };
    }
}
