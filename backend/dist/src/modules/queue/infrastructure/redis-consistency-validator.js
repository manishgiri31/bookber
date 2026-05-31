import { prisma } from "../../../shared/prisma/client.js";
import { waitTimeRedisKeys } from "../../../shared/redis/wait-time-redis.keys.js";
/**
 * Redis consistency validation layer.
 *
 * Validates Redis state against PostgreSQL source of truth.
 * Provides methods to detect and report inconsistencies.
 * Used by recovery systems and as a pre-flight check for critical operations.
 */
export class RedisConsistencyValidator {
    redis;
    constructor(redis) {
        this.redis = redis;
    }
    /**
     * Validate queue consistency between Redis and PostgreSQL
     */
    async validateQueueConsistency(shopId, lane) {
        if (!this.redis) {
            return { isConsistent: true, dbQueueLength: 0, redisQueueLength: 0, mismatchedBookings: [] };
        }
        const dbQueueLength = await prisma.queueEntry.count({
            where: {
                shopId,
                lane,
                queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
            }
        });
        const redisQueueLength = await this.redis.zcard(waitTimeRedisKeys.queue(shopId, lane));
        if (dbQueueLength !== redisQueueLength) {
            const mismatchedBookings = await this.getMismatchedBookings(shopId, lane);
            return {
                isConsistent: false,
                dbQueueLength,
                redisQueueLength,
                mismatchedBookings
            };
        }
        return {
            isConsistent: true,
            dbQueueLength,
            redisQueueLength,
            mismatchedBookings: []
        };
    }
    /**
     * Get mismatched booking IDs between Redis and PostgreSQL
     */
    async getMismatchedBookings(shopId, lane) {
        if (!this.redis) {
            return [];
        }
        const dbQueue = await prisma.queueEntry.findMany({
            where: {
                shopId,
                lane,
                queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
            },
            select: { bookingId: true }
        });
        const redisQueueIds = await this.redis.zrange(waitTimeRedisKeys.queue(shopId, lane), 0, -1);
        const dbBookingIds = new Set(dbQueue.map(q => q.bookingId));
        const redisBookingIds = new Set(redisQueueIds);
        const mismatchedBookings = [];
        // Bookings in DB but not in Redis
        for (const bookingId of dbBookingIds) {
            if (!redisBookingIds.has(bookingId)) {
                mismatchedBookings.push(bookingId);
            }
        }
        // Bookings in Redis but not in DB
        for (const bookingId of redisBookingIds) {
            if (!dbBookingIds.has(bookingId)) {
                mismatchedBookings.push(bookingId);
            }
        }
        return mismatchedBookings;
    }
    /**
     * Validate wait time consistency for a specific booking
     */
    async validateWaitTimeConsistency(bookingId) {
        if (!this.redis) {
            return { isConsistent: true, dbWaitMinutes: 0, redisWaitMinutes: null };
        }
        const activeQueue = await prisma.queueEntry.findUnique({
            where: { bookingId },
            select: { estimatedWaitMinutes: true }
        });
        if (!activeQueue) {
            return { isConsistent: true, dbWaitMinutes: 0, redisWaitMinutes: null };
        }
        const redisSnapshot = await this.redis.hgetall(waitTimeRedisKeys.booking(bookingId));
        const redisWaitMinutes = redisSnapshot["estimatedWaitMinutes"]
            ? parseInt(redisSnapshot["estimatedWaitMinutes"], 10)
            : null;
        const isConsistent = redisWaitMinutes === null || redisWaitMinutes === activeQueue.estimatedWaitMinutes;
        return {
            isConsistent,
            dbWaitMinutes: activeQueue.estimatedWaitMinutes,
            redisWaitMinutes
        };
    }
    /**
     * Validate chair cache consistency
     */
    async validateChairCacheConsistency(chairId) {
        if (!this.redis) {
            return { isConsistent: true, dbStatus: "", redisStatus: null };
        }
        const chair = await prisma.chair.findUnique({
            where: { id: chairId },
            select: { status: true }
        });
        if (!chair) {
            return { isConsistent: true, dbStatus: "", redisStatus: null };
        }
        const redisCache = await this.redis.hgetall(`chair:${chairId}`);
        const redisStatus = redisCache["status"] || null;
        const isConsistent = redisStatus === null || redisStatus === chair.status;
        return {
            isConsistent,
            dbStatus: chair.status,
            redisStatus
        };
    }
    /**
     * Validate all queues for a shop
     */
    async validateShopQueues(shopId) {
        const [bookber, walkin] = await Promise.all([
            this.validateQueueConsistency(shopId, "BOOKBER"),
            this.validateQueueConsistency(shopId, "WALKIN")
        ]);
        return { BOOKBER: bookber, WALKIN: walkin };
    }
    /**
     * Get overall health status for a shop
     */
    async getShopHealthStatus(shopId) {
        const queueConsistency = await this.validateShopQueues(shopId);
        const totalInconsistencies = (queueConsistency.BOOKBER.isConsistent ? 0 : 1) +
            (queueConsistency.WALKIN.isConsistent ? 0 : 1);
        return {
            isHealthy: totalInconsistencies === 0,
            queueConsistency,
            totalInconsistencies
        };
    }
}
