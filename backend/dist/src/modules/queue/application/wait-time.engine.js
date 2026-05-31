import { prisma } from "../../../shared/prisma/client.js";
import { Errors } from "../../../shared/http/app-error.js";
import { WAIT_RECALC_TRIGGERS } from "../domain/wait-time.types.js";
import { WaitTimeRedisStore } from "../infrastructure/wait-time-redis.store.js";
import { WaitTimePersistence } from "../infrastructure/wait-time.persistence.js";
import { calculateLaneWaitEstimates } from "./wait-time.calculator.js";
const DEFAULT_CONFIG = {
    activeReservedChairs: 1,
    activeWalkInChairs: 1,
    cleaningBufferMinutes: 5,
    overrunBufferMinutes: 3
};
export class WaitTimeEngine {
    redis;
    persistence;
    constructor(redisClient) {
        this.redis = new WaitTimeRedisStore(redisClient);
        this.persistence = new WaitTimePersistence(this.redis);
    }
    hasRedis() {
        return this.redis.isAvailable();
    }
    /**
     * Redis-only read path — suitable for 10k concurrent polling clients.
     */
    async getEstimates(shopId) {
        if (!this.hasRedis()) {
            return this.getEstimatesFromDatabase(shopId);
        }
        await this.ensureShopHydrated(shopId);
        const version = await this.redis.getWaitVersion(shopId);
        const [bookBer, walkIn] = await Promise.all([
            this.readLaneEstimatesFromRedis(shopId, "BOOKBER"),
            this.readLaneEstimatesFromRedis(shopId, "WALKIN")
        ]);
        return {
            shopId,
            version,
            bookBer,
            walkIn,
            computedAt: new Date().toISOString()
        };
    }
    /**
     * Full recalculation for one lane — Redis-first, returns estimates for optional DB txn.
     */
    async recalculateLane(shopId, lane, _trigger) {
        if (!this.hasRedis()) {
            return this.recalculateLaneFromDatabase(shopId, lane);
        }
        const shop = await this.ensureShopHydrated(shopId);
        const config = shop.config;
        const activeChairs = lane === "BOOKBER" ? config.activeReservedChairs : config.activeWalkInChairs;
        const bookingIds = await this.redis.listBookingIds(shopId, lane);
        const entries = await this.buildSnapshotsForRecalc(shopId, lane, bookingIds);
        const estimates = await this.computeAndApply(shopId, lane, shop, entries, activeChairs);
        const version = await this.redis.bumpWaitVersion(shopId);
        return {
            shopId,
            lane,
            version,
            activeChairs,
            estimates,
            computedAt: new Date()
        };
    }
    async recalculateShop(shopId, trigger) {
        const [bookBer, walkIn, version] = await Promise.all([
            this.recalculateLane(shopId, "BOOKBER", trigger),
            this.recalculateLane(shopId, "WALKIN", trigger),
            this.redis.getWaitVersion(shopId)
        ]);
        return {
            shopId,
            version,
            bookBer: bookBer.estimates,
            walkIn: walkIn.estimates,
            computedAt: new Date().toISOString()
        };
    }
    async onEnqueue(snapshot) {
        if (this.hasRedis()) {
            await this.redis.enqueue(snapshot.bookingId, snapshot.shopId, snapshot.lane, snapshot.position);
            await this.redis.setBookingSnapshot(snapshot);
        }
        return this.recalculateLane(snapshot.shopId, snapshot.lane, WAIT_RECALC_TRIGGERS.ENQUEUE);
    }
    async onDequeue(shopId, lane, bookingId) {
        if (this.hasRedis()) {
            await this.redis.dequeue(bookingId, shopId, lane);
        }
        return this.recalculateLane(shopId, lane, WAIT_RECALC_TRIGGERS.DEQUEUE);
    }
    async recordServiceComplete(args) {
        await this.persistence.recordServiceSample({
            shopId: args.shopId,
            barberId: args.barberId,
            category: args.category,
            actualMinutes: args.actualMinutes
        });
        if (args.barberId) {
            await this.persistence.clearBarberCompensation(args.barberId);
        }
        return this.onDequeue(args.shopId, args.lane, args.bookingId);
    }
    async recordBarberDelay(shopId, barberId, delayMinutes) {
        if (!this.hasRedis())
            return;
        const prev = (await this.redis.getBarberState(barberId)) ?? {
            delayMinutes: 0,
            overrunMinutes: 0,
            updatedAtMs: Date.now()
        };
        await this.redis.setBarberState(barberId, {
            delayMinutes: Math.max(prev.delayMinutes, delayMinutes),
            overrunMinutes: prev.overrunMinutes,
            updatedAtMs: Date.now()
        });
        await this.recalculateShop(shopId, WAIT_RECALC_TRIGGERS.BARBER_DELAY);
    }
    async recordServiceOverrun(shopId, barberId, overrunMinutes) {
        if (!this.hasRedis())
            return;
        const prev = (await this.redis.getBarberState(barberId)) ?? {
            delayMinutes: 0,
            overrunMinutes: 0,
            updatedAtMs: Date.now()
        };
        await this.redis.setBarberState(barberId, {
            delayMinutes: prev.delayMinutes,
            overrunMinutes: Math.max(prev.overrunMinutes, overrunMinutes),
            updatedAtMs: Date.now()
        });
        await this.recalculateShop(shopId, WAIT_RECALC_TRIGGERS.SERVICE_OVERRUN);
    }
    async syncBookingSnapshot(snapshot) {
        if (!this.hasRedis())
            return;
        await this.redis.setBookingSnapshot(snapshot);
        await this.redis.enqueue(snapshot.bookingId, snapshot.shopId, snapshot.lane, snapshot.position);
    }
    // ——— internals ———
    async computeAndApply(shopId, lane, shop, entries, activeChairs) {
        const { historical: shopHistorical, recent: shopRecent } = await this.redis.getShopAverages(shopId);
        const barberHistorical = new Map();
        const barberRecent = new Map();
        const barberState = new Map();
        const barberSpeedFactors = new Map();
        const barberIds = [...new Set(entries.map((e) => e.barberId).filter(Boolean))];
        await Promise.all(barberIds.map(async (barberId) => {
            const [avgs, state, barber] = await Promise.all([
                this.redis.getBarberAverages(barberId),
                this.redis.getBarberState(barberId),
                prisma.barber.findUnique({
                    where: { id: barberId },
                    select: { serviceSpeedFactor: true }
                })
            ]);
            barberHistorical.set(barberId, avgs.historical);
            barberRecent.set(barberId, avgs.recent);
            barberState.set(barberId, state ?? { delayMinutes: 0, overrunMinutes: 0, updatedAtMs: Date.now() });
            barberSpeedFactors.set(barberId, barber?.serviceSpeedFactor ?? 1);
        }));
        const input = {
            now: new Date(),
            config: shop.config,
            entries,
            shopHistorical,
            shopRecent,
            barberHistorical,
            barberRecent,
            barberState,
            barberSpeedFactors,
            activeChairs
        };
        const estimates = calculateLaneWaitEstimates(input);
        await this.redis.applyEstimatesPipeline(shopId, lane, estimates);
        return estimates;
    }
    async buildSnapshotsForRecalc(shopId, lane, bookingIds) {
        const cached = await this.redis.getBookingSnapshots(bookingIds);
        if (cached.length === bookingIds.length)
            return cached;
        const missing = bookingIds.filter((id) => !cached.find((c) => c.bookingId === id));
        if (missing.length === 0)
            return cached;
        const rows = await prisma.queueEntry.findMany({
            where: { shopId, lane, bookingId: { in: missing } },
            include: {
                booking: { include: { service: true, barber: true } }
            }
        });
        for (const row of rows) {
            const snap = bookingRowToSnapshot(row);
            await this.redis.setBookingSnapshot(snap);
            cached.push(snap);
        }
        return cached.sort((a, b) => a.position - b.position);
    }
    /**
     * Hot read path: cached estimates only (O(log n + k)), no writes.
     * Falls back to full recalc only when cache is empty but queue has members.
     */
    async readLaneEstimatesFromRedis(shopId, lane) {
        const cached = await this.redis.readCachedLaneEstimates(shopId, lane);
        if (cached.length > 0)
            return cached;
        const length = await this.redis.queueLength(shopId, lane);
        if (length === 0)
            return [];
        const result = await this.recalculateLane(shopId, lane, WAIT_RECALC_TRIGGERS.REBALANCE);
        return result.estimates;
    }
    async ensureShopHydrated(shopId) {
        const cached = await this.redis.getShopConfig(shopId);
        if (cached) {
            const reserved = cached.activeReservedChairs;
            const walkIn = cached.activeWalkInChairs;
            return { config: cached, reservedChairCount: reserved, walkInChairCount: walkIn };
        }
        const shop = await prisma.shop.findUnique({
            where: { id: shopId },
            include: {
                chairs: { where: { status: { not: "BLOCKED" } } },
                services: { where: { isActive: true } }
            }
        });
        if (!shop)
            throw Errors.notFound("Shop not found");
        const reservedChairs = shop.chairs.filter((c) => c.reservedForBookBer);
        const walkInChairs = shop.chairs.filter((c) => !c.reservedForBookBer);
        const config = {
            activeReservedChairs: Math.max(1, shop.bookBerReservedChairCount, reservedChairs.filter((c) => c.status === "AVAILABLE" || c.status === "OCCUPIED").length),
            activeWalkInChairs: Math.max(1, walkInChairs.filter((c) => c.status === "AVAILABLE" || c.status === "OCCUPIED").length),
            cleaningBufferMinutes: DEFAULT_CONFIG.cleaningBufferMinutes,
            overrunBufferMinutes: DEFAULT_CONFIG.overrunBufferMinutes
        };
        const historical = buildInitialShopAverages(shop.services);
        const recent = { ...historical };
        if (this.hasRedis()) {
            await this.redis.setShopConfig(shopId, config);
            await this.redis.setShopAverages(shopId, historical, recent);
        }
        return {
            config,
            reservedChairCount: config.activeReservedChairs,
            walkInChairCount: config.activeWalkInChairs
        };
    }
    async recalculateLaneFromDatabase(shopId, lane) {
        const shop = await this.ensureShopHydrated(shopId);
        const activeChairs = lane === "BOOKBER" ? shop.config.activeReservedChairs : shop.config.activeWalkInChairs;
        const rows = await prisma.queueEntry.findMany({
            where: {
                shopId,
                lane,
                queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
            },
            include: { booking: { include: { service: true, barber: true } } },
            orderBy: { position: "asc" }
        });
        const entries = rows.map(bookingRowToSnapshot);
        const estimates = calculateLaneWaitEstimates({
            now: new Date(),
            config: shop.config,
            entries,
            shopHistorical: buildInitialShopAverages(rows.map((r) => r.booking.service)),
            shopRecent: {},
            barberHistorical: new Map(),
            barberRecent: new Map(),
            barberState: new Map(),
            barberSpeedFactors: new Map(rows
                .filter((r) => r.barberId && r.booking.barber)
                .map((r) => [r.barberId, r.booking.barber.serviceSpeedFactor])),
            activeChairs
        });
        return {
            shopId,
            lane,
            version: 0,
            activeChairs,
            estimates,
            computedAt: new Date()
        };
    }
    async getEstimatesFromDatabase(shopId) {
        const [bookBer, walkIn] = await Promise.all([
            this.recalculateLaneFromDatabase(shopId, "BOOKBER"),
            this.recalculateLaneFromDatabase(shopId, "WALKIN")
        ]);
        return {
            shopId,
            version: 0,
            bookBer: bookBer.estimates,
            walkIn: walkIn.estimates,
            computedAt: new Date().toISOString()
        };
    }
}
function buildInitialShopAverages(services) {
    const buckets = {
        HAIRCUT: [],
        BEARD: [],
        COMBO: []
    };
    for (const s of services) {
        buckets[s.category].push(s.durationMinutes);
    }
    const avg = (arr, fallback) => arr.length > 0 ? Math.round(arr.reduce((a, b) => a + b, 0) / arr.length) : fallback;
    return {
        HAIRCUT: avg(buckets.HAIRCUT, 30),
        BEARD: avg(buckets.BEARD, 15),
        COMBO: avg(buckets.COMBO, 45)
    };
}
function bookingRowToSnapshot(row) {
    const remaining = row.estimatedServiceStart &&
        (row.queueStatus === "IN_SERVICE" || row.queueStatus === "CALLED")
        ? Math.max(0, row.booking.service.durationMinutes -
            Math.round((Date.now() - row.estimatedServiceStart.getTime()) / 60_000))
        : 0;
    return {
        bookingId: row.booking.id,
        shopId: row.shopId,
        lane: row.lane,
        position: row.position,
        serviceId: row.booking.serviceId,
        serviceCategory: row.booking.service.category,
        barberId: row.barberId,
        catalogDurationMinutes: row.booking.service.durationMinutes,
        queueStatus: row.queueStatus,
        estimatedWaitMinutes: row.estimatedWaitMinutes,
        estimatedServiceStartIso: row.estimatedServiceStart?.toISOString() ?? new Date().toISOString(),
        inServiceRemainingMinutes: remaining
    };
}
