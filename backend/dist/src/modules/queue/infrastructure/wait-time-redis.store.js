import { waitTimeRedisKeys } from "../../../shared/redis/wait-time-redis.keys.js";
const CATEGORY_FIELDS = ["HAIRCUT", "BEARD", "COMBO"];
function parseIntField(value, fallback = 0) {
    if (value == null || value === "")
        return fallback;
    const n = Number.parseInt(value, 10);
    return Number.isFinite(n) ? n : fallback;
}
export class WaitTimeRedisStore {
    redis;
    constructor(redis) {
        this.redis = redis;
    }
    isAvailable() {
        return this.redis != null;
    }
    requireRedis() {
        if (!this.redis) {
            throw new Error("REDIS_UNAVAILABLE");
        }
        return this.redis;
    }
    /** ZADD — O(log n) */
    async enqueue(bookingId, shopId, lane, position) {
        const r = this.requireRedis();
        await r.zadd(waitTimeRedisKeys.queue(shopId, lane), position, bookingId);
    }
    /** ZREM — O(log n) */
    async dequeue(bookingId, shopId, lane) {
        const r = this.requireRedis();
        await r.zrem(waitTimeRedisKeys.queue(shopId, lane), bookingId);
    }
    /** ZRANGE 0 -1 — O(log n + k) */
    async listBookingIds(shopId, lane) {
        const r = this.requireRedis();
        return r.zrange(waitTimeRedisKeys.queue(shopId, lane), 0, -1);
    }
    /** ZCARD — O(1) */
    async queueLength(shopId, lane) {
        const r = this.requireRedis();
        return r.zcard(waitTimeRedisKeys.queue(shopId, lane));
    }
    async setBookingSnapshot(snapshot) {
        const r = this.requireRedis();
        await r.hset(waitTimeRedisKeys.booking(snapshot.bookingId), {
            shopId: snapshot.shopId,
            lane: snapshot.lane,
            position: String(snapshot.position),
            serviceId: snapshot.serviceId,
            serviceCategory: snapshot.serviceCategory,
            barberId: snapshot.barberId ?? "",
            catalogDurationMinutes: String(snapshot.catalogDurationMinutes),
            queueStatus: snapshot.queueStatus,
            estimatedWaitMinutes: String(snapshot.estimatedWaitMinutes),
            estimatedServiceStartIso: snapshot.estimatedServiceStartIso,
            inServiceRemainingMinutes: String(snapshot.inServiceRemainingMinutes)
        });
    }
    async getBookingSnapshot(bookingId) {
        const r = this.requireRedis();
        const raw = await r.hgetall(waitTimeRedisKeys.booking(bookingId));
        if (Object.keys(raw).length === 0)
            return null;
        return {
            bookingId,
            shopId: raw['shopId'] ?? "",
            lane: raw['lane'] ?? "BOOKBER",
            position: parseIntField(raw['position'], 1),
            serviceId: raw['serviceId'] ?? "",
            serviceCategory: raw['serviceCategory'] ?? "HAIRCUT",
            barberId: raw['barberId'] ? raw['barberId'] : null,
            catalogDurationMinutes: parseIntField(raw['catalogDurationMinutes'], 30),
            queueStatus: raw['queueStatus'] ?? "WAITING",
            estimatedWaitMinutes: parseIntField(raw['estimatedWaitMinutes']),
            estimatedServiceStartIso: raw['estimatedServiceStartIso'] ?? new Date().toISOString(),
            inServiceRemainingMinutes: parseIntField(raw['inServiceRemainingMinutes'])
        };
    }
    /** Pipeline HGETALL — one round trip for k bookings */
    async getBookingSnapshots(bookingIds) {
        if (bookingIds.length === 0)
            return [];
        const r = this.requireRedis();
        const pipeline = r.pipeline();
        for (const id of bookingIds) {
            pipeline.hgetall(waitTimeRedisKeys.booking(id));
        }
        const results = await pipeline.exec();
        const snapshots = [];
        for (let i = 0; i < bookingIds.length; i += 1) {
            const id = bookingIds[i];
            const row = results?.[i]?.[1];
            if (!id || !row || Object.keys(row).length === 0)
                continue;
            snapshots.push({
                bookingId: id,
                shopId: row['shopId'] ?? "",
                lane: row['lane'] ?? "BOOKBER",
                position: parseIntField(row['position'], i + 1),
                serviceId: row['serviceId'] ?? "",
                serviceCategory: row['serviceCategory'] ?? "HAIRCUT",
                barberId: row['barberId'] ? row['barberId'] : null,
                catalogDurationMinutes: parseIntField(row['catalogDurationMinutes'], 30),
                queueStatus: row['queueStatus'] ?? "WAITING",
                estimatedWaitMinutes: parseIntField(row['estimatedWaitMinutes']),
                estimatedServiceStartIso: row['estimatedServiceStartIso'] ?? new Date().toISOString(),
                inServiceRemainingMinutes: parseIntField(row['inServiceRemainingMinutes'])
            });
        }
        return snapshots.sort((a, b) => a.position - b.position);
    }
    async applyEstimatesPipeline(shopId, lane, estimates) {
        const r = this.requireRedis();
        const pipeline = r.pipeline();
        const queueKey = waitTimeRedisKeys.queue(shopId, lane);
        for (const est of estimates) {
            pipeline.zadd(queueKey, est.position, est.bookingId);
            pipeline.hset(waitTimeRedisKeys.booking(est.bookingId), {
                position: String(est.position),
                estimatedWaitMinutes: String(est.estimatedWaitMinutes),
                estimatedServiceStartIso: est.estimatedServiceStart.toISOString(),
                effectiveDurationMinutes: String(est.effectiveDurationMinutes),
                cleaningBufferMinutes: String(est.cleaningBufferMinutes),
                delayCompensationMinutes: String(est.delayCompensationMinutes),
                overrunCompensationMinutes: String(est.overrunCompensationMinutes)
            });
        }
        await pipeline.exec();
    }
    /**
     * Read-only path for high concurrency — one ZRANGE + one pipelined HGETALL round trip.
     * Does not recalculate or write.
     */
    async readCachedLaneEstimates(shopId, lane) {
        const r = this.requireRedis();
        const bookingIds = await r.zrange(waitTimeRedisKeys.queue(shopId, lane), 0, -1);
        if (bookingIds.length === 0)
            return [];
        const pipeline = r.pipeline();
        for (const id of bookingIds) {
            pipeline.hgetall(waitTimeRedisKeys.booking(id));
        }
        const rows = await pipeline.exec();
        const estimates = [];
        for (let i = 0; i < bookingIds.length; i += 1) {
            const bookingId = bookingIds[i];
            const raw = rows?.[i]?.[1];
            if (!bookingId || !raw || Object.keys(raw).length === 0)
                continue;
            const startIso = raw['estimatedServiceStartIso'];
            estimates.push({
                bookingId,
                position: parseIntField(raw['position'], i + 1),
                estimatedWaitMinutes: parseIntField(raw['estimatedWaitMinutes']),
                estimatedServiceStart: startIso ? new Date(startIso) : new Date(),
                effectiveDurationMinutes: parseIntField(raw['effectiveDurationMinutes'], 30),
                cleaningBufferMinutes: parseIntField(raw['cleaningBufferMinutes']),
                delayCompensationMinutes: parseIntField(raw['delayCompensationMinutes']),
                overrunCompensationMinutes: parseIntField(raw['overrunCompensationMinutes'])
            });
        }
        return estimates.sort((a, b) => a.position - b.position);
    }
    async getShopConfig(shopId) {
        const r = this.requireRedis();
        const raw = await r.hgetall(waitTimeRedisKeys.shopWaitConfig(shopId));
        if (Object.keys(raw).length === 0)
            return null;
        return {
            activeReservedChairs: Math.max(1, parseIntField(raw['activeReservedChairs'], 1)),
            activeWalkInChairs: Math.max(1, parseIntField(raw['activeWalkInChairs'], 1)),
            cleaningBufferMinutes: parseIntField(raw['cleaningBufferMinutes'], 5),
            overrunBufferMinutes: parseIntField(raw['overrunBufferMinutes'], 3)
        };
    }
    async setShopConfig(shopId, config) {
        const r = this.requireRedis();
        await r.hset(waitTimeRedisKeys.shopWaitConfig(shopId), {
            activeReservedChairs: String(config.activeReservedChairs),
            activeWalkInChairs: String(config.activeWalkInChairs),
            cleaningBufferMinutes: String(config.cleaningBufferMinutes),
            overrunBufferMinutes: String(config.overrunBufferMinutes)
        });
    }
    async getShopAverages(shopId) {
        const r = this.requireRedis();
        const [hist, rec] = await Promise.all([
            r.hgetall(waitTimeRedisKeys.shopAvgHistorical(shopId)),
            r.hgetall(waitTimeRedisKeys.shopAvgRecent(shopId))
        ]);
        return {
            historical: parseCategoryHash(hist),
            recent: parseCategoryHash(rec)
        };
    }
    async setShopAverages(shopId, historical, recent) {
        const r = this.requireRedis();
        await Promise.all([
            r.hset(waitTimeRedisKeys.shopAvgHistorical(shopId), categoryHashToStrings(historical)),
            r.hset(waitTimeRedisKeys.shopAvgRecent(shopId), categoryHashToStrings(recent))
        ]);
    }
    async updateShopRecentCategory(shopId, category, minutes) {
        const r = this.requireRedis();
        await r.hset(waitTimeRedisKeys.shopAvgRecent(shopId), category, String(minutes));
    }
    async getBarberAverages(barberId) {
        const r = this.requireRedis();
        const [hist, rec] = await Promise.all([
            r.hgetall(waitTimeRedisKeys.barberAvgHistorical(barberId)),
            r.hgetall(waitTimeRedisKeys.barberAvgRecent(barberId))
        ]);
        return {
            historical: parseCategoryHash(hist),
            recent: parseCategoryHash(rec)
        };
    }
    async setBarberAverages(barberId, historical, recent) {
        const r = this.requireRedis();
        await Promise.all([
            r.hset(waitTimeRedisKeys.barberAvgHistorical(barberId), categoryHashToStrings(historical)),
            r.hset(waitTimeRedisKeys.barberAvgRecent(barberId), categoryHashToStrings(recent))
        ]);
    }
    async getBarberState(barberId) {
        const r = this.requireRedis();
        const raw = await r.hgetall(waitTimeRedisKeys.barberState(barberId));
        if (Object.keys(raw).length === 0)
            return null;
        return {
            delayMinutes: parseIntField(raw['delayMinutes']),
            overrunMinutes: parseIntField(raw['overrunMinutes']),
            updatedAtMs: parseIntField(raw['updatedAtMs'], Date.now())
        };
    }
    async setBarberState(barberId, state) {
        const r = this.requireRedis();
        await r.hset(waitTimeRedisKeys.barberState(barberId), {
            delayMinutes: String(state.delayMinutes),
            overrunMinutes: String(state.overrunMinutes),
            updatedAtMs: String(state.updatedAtMs)
        });
    }
    async bumpWaitVersion(shopId) {
        const r = this.requireRedis();
        return r.incr(waitTimeRedisKeys.waitVersion(shopId));
    }
    async getWaitVersion(shopId) {
        const r = this.requireRedis();
        const v = await r.get(waitTimeRedisKeys.waitVersion(shopId));
        return v ? Number(v) : 0;
    }
}
function parseCategoryHash(raw) {
    const out = {};
    for (const field of CATEGORY_FIELDS) {
        const v = raw[field];
        if (v != null && v !== "") {
            out[field] = parseIntField(v, 0);
        }
    }
    return out;
}
function categoryHashToStrings(avg) {
    const out = {};
    for (const field of CATEGORY_FIELDS) {
        const v = avg[field];
        if (v != null)
            out[field] = String(v);
    }
    return out;
}
