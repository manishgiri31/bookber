import { SOCKET_EVENT_LOG_MAX } from "./socket.config.js";
function shopLogKey(shopId) {
    return `shop:${shopId}:eventlog`;
}
function shopSeqKey(shopId) {
    return `shop:${shopId}:event:seq`;
}
function userLogKey(userId) {
    return `user:${userId}:eventlog`;
}
function userSeqKey(userId) {
    return `user:${userId}:event:seq`;
}
export class SocketEventJournal {
    redis;
    constructor(redis) {
        this.redis = redis;
    }
    isEnabled() {
        return this.redis != null;
    }
    async nextShopSeq(shopId) {
        if (!this.redis)
            return Date.now();
        return this.redis.incr(shopSeqKey(shopId));
    }
    async nextUserSeq(userId) {
        if (!this.redis)
            return Date.now();
        return this.redis.incr(userSeqKey(userId));
    }
    async appendShopEvent(shopId, envelope) {
        if (!this.redis)
            return;
        const key = shopLogKey(shopId);
        const payload = JSON.stringify(envelope);
        await this.redis.zadd(key, envelope.seq, payload);
        const count = await this.redis.zcard(key);
        if (count > SOCKET_EVENT_LOG_MAX) {
            await this.redis.zpopmin(key, count - SOCKET_EVENT_LOG_MAX);
        }
    }
    async appendUserEvent(userId, envelope) {
        if (!this.redis)
            return;
        const key = userLogKey(userId);
        const payload = JSON.stringify(envelope);
        await this.redis.zadd(key, envelope.seq, payload);
        const count = await this.redis.zcard(key);
        if (count > SOCKET_EVENT_LOG_MAX) {
            await this.redis.zpopmin(key, count - SOCKET_EVENT_LOG_MAX);
        }
    }
    async getShopEventsSince(shopId, afterSeq, limit = 100) {
        if (!this.redis)
            return [];
        const raw = await this.redis.zrangebyscore(shopLogKey(shopId), afterSeq > 0 ? `(${afterSeq}` : "-inf", "+inf", "LIMIT", 0, limit);
        return raw.map(parseEnvelope).filter((e) => e != null);
    }
    async getUserEventsSince(userId, afterSeq, limit = 100) {
        if (!this.redis)
            return [];
        const raw = await this.redis.zrangebyscore(userLogKey(userId), afterSeq > 0 ? `(${afterSeq}` : "-inf", "+inf", "LIMIT", 0, limit);
        return raw.map(parseEnvelope).filter((e) => e != null);
    }
    async currentShopSeq(shopId) {
        if (!this.redis)
            return 0;
        const v = await this.redis.get(shopSeqKey(shopId));
        return v ? Number(v) : 0;
    }
    async currentUserSeq(userId) {
        if (!this.redis)
            return 0;
        const v = await this.redis.get(userSeqKey(userId));
        return v ? Number(v) : 0;
    }
}
function parseEnvelope(raw) {
    try {
        const parsed = JSON.parse(raw);
        if (typeof parsed.seq !== "number" || typeof parsed.event !== "string")
            return null;
        return parsed;
    }
    catch {
        return null;
    }
}
