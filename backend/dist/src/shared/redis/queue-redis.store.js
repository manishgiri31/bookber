import { waitTimeRedisKeys } from "./wait-time-redis.keys.js";
function chairKey(chairId) {
    return `chair:${chairId}`;
}
/**
 * Legacy facade — queue keys are shared with {@link waitTimeRedisKeys}.
 */
export class QueueRedisStore {
    redis;
    constructor(redis) {
        this.redis = redis;
    }
    async enqueueMember(shopId, member) {
        if (!this.redis)
            return;
        const key = waitTimeRedisKeys.queue(shopId, member.lane);
        await this.redis.zadd(key, member.position, member.bookingId);
        await this.redis.hset(waitTimeRedisKeys.booking(member.bookingId), {
            shopId,
            lane: member.lane,
            position: String(member.position),
            estimatedWaitMinutes: String(member.estimatedWaitMinutes),
            queueStatus: member.queueStatus,
            userId: member.userId,
            serviceId: member.serviceId,
            barberId: member.barberId ?? ""
        });
    }
    async removeMember(shopId, lane, bookingId) {
        if (!this.redis)
            return;
        await this.redis.zrem(waitTimeRedisKeys.queue(shopId, lane), bookingId);
        await this.redis.del(waitTimeRedisKeys.booking(bookingId));
    }
    async updatePosition(shopId, lane, bookingId, position, estimatedWaitMinutes) {
        if (!this.redis)
            return;
        const key = waitTimeRedisKeys.queue(shopId, lane);
        await this.redis.zadd(key, position, bookingId);
        await this.redis.hset(waitTimeRedisKeys.booking(bookingId), {
            position: String(position),
            estimatedWaitMinutes: String(estimatedWaitMinutes)
        });
    }
    async listQueue(shopId, lane) {
        if (!this.redis)
            return [];
        return this.redis.zrange(waitTimeRedisKeys.queue(shopId, lane), 0, -1);
    }
    async setChairCache(args) {
        if (!this.redis)
            return;
        await this.redis.hset(chairKey(args.chairId), {
            shopId: args.shopId,
            status: args.status,
            reservedForBookBer: args.reservedForBookBer ? "1" : "0",
            bookingId: args.bookingId ?? "",
            activeServiceStart: args.activeServiceStart ?? "",
            activeServiceEnd: args.activeServiceEnd ?? ""
        });
    }
    async getChairCache(chairId) {
        if (!this.redis)
            return null;
        const data = await this.redis.hgetall(chairKey(chairId));
        return Object.keys(data).length > 0 ? data : null;
    }
    async bumpShopQueueVersion(shopId) {
        if (!this.redis)
            return 0;
        return this.redis.incr(waitTimeRedisKeys.queueVersion(shopId));
    }
    async getShopQueueVersion(shopId) {
        if (!this.redis)
            return 0;
        const v = await this.redis.get(waitTimeRedisKeys.queueVersion(shopId));
        return v ? Number(v) : 0;
    }
}
