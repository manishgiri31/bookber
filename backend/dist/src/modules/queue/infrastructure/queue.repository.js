import { SparsePositionAllocator } from "../application/sparse-position-allocator.service.js";
const ACTIVE_QUEUE_STATUSES = ["WAITING", "READY", "CALLED", "IN_SERVICE"];
export class PrismaQueueRepository {
    positionAllocator;
    constructor() {
        this.positionAllocator = new SparsePositionAllocator();
    }
    async lockShop(db, shopId) {
        await db.$queryRaw `SELECT id FROM "Shop" WHERE id = ${shopId} FOR UPDATE`;
    }
    async lockBooking(db, bookingId) {
        await db.$queryRaw `SELECT id FROM "Booking" WHERE id = ${bookingId} FOR UPDATE`;
    }
    async lockChair(db, chairId) {
        await db.$queryRaw `SELECT id FROM "Chair" WHERE id = ${chairId} FOR UPDATE`;
    }
    async lockQueueEntry(db, queueEntryId) {
        await db.$queryRaw `SELECT id FROM "QueueEntry" WHERE id = ${queueEntryId} FOR UPDATE`;
    }
    async findShopById(db, shopId) {
        return db.shop.findUnique({
            where: { id: shopId },
            include: {
                chairs: { orderBy: { number: "asc" } },
                services: { where: { isActive: true } },
                barbers: { where: { isAvailable: true } }
            }
        });
    }
    async findService(db, serviceId) {
        return db.service.findUnique({ where: { id: serviceId } });
    }
    async findBooking(db, bookingId) {
        return db.booking.findUnique({
            where: { id: bookingId },
            include: {
                service: true,
                barber: true,
                queueEntry: true,
                chair: true,
                user: true
            }
        });
    }
    // Legacy method for backward compatibility - will be removed after migration
    async listActiveQueueEntries(db, shopId, lane) {
        return this.listQueueEntries(db, shopId, lane);
    }
    async countReservedChairs(db, shopId) {
        return db.chair.count({
            where: { shopId, reservedForBookBer: true, status: { not: "BLOCKED" } }
        });
    }
    async countActiveReservedChairsInService(db, shopId) {
        const reserved = await db.chair.count({
            where: { shopId, reservedForBookBer: true, status: "OCCUPIED" }
        });
        const totalReserved = await this.countReservedChairs(db, shopId);
        const availableReserved = await db.chair.count({
            where: { shopId, reservedForBookBer: true, status: "AVAILABLE" }
        });
        return Math.max(1, totalReserved - availableReserved + (availableReserved > 0 ? availableReserved : 0));
    }
    async listQueueEntries(db, shopId, lane) {
        return db.queueEntry.findMany({
            where: {
                shopId,
                lane,
                queueStatus: { in: ACTIVE_QUEUE_STATUSES }
            },
            include: {
                booking: {
                    include: {
                        service: true,
                        barber: true,
                        user: true
                    }
                }
            },
            orderBy: { position: "asc" }
        });
    }
    async nextQueuePosition(db, shopId, lane, insertAfterPosition = null) {
        return this.positionAllocator.allocatePositionWithRetry(db, shopId, lane, insertAfterPosition, 3);
    }
    async needsRebalancing(db, shopId, lane) {
        return this.positionAllocator.needsRebalancing(db, shopId, lane);
    }
    async needsNormalization(db, shopId, lane) {
        return this.positionAllocator.needsNormalization(db, shopId, lane);
    }
    async normalizeLane(db, shopId, lane) {
        return this.positionAllocator.normalizeLane(db, shopId, lane);
    }
    async getEffectivePosition(db, shopId, lane, position) {
        return this.positionAllocator.getEffectivePosition(db, shopId, lane, position);
    }
    async getEffectivePositions(db, shopId, lane) {
        return this.positionAllocator.getEffectivePositions(db, shopId, lane);
    }
    async createQueueEvent(db, data) {
        return db.queueEvent.create({
            data: {
                shopId: data.shopId,
                ...(data.bookingId ? { bookingId: data.bookingId } : {}),
                type: data.type,
                payload: data.payload ?? {}
            }
        });
    }
    async findAvailableChairForLane(db, shopId, lane) {
        return db.chair.findFirst({
            where: {
                shopId,
                status: "AVAILABLE",
                reservedForBookBer: lane === "BOOKBER"
            },
            orderBy: { number: "asc" }
        });
    }
    async assignChair(db, args) {
        const now = args.activeServiceStart ?? new Date();
        const allocation = await db.chairAllocation.create({
            data: {
                shopId: args.shopId,
                chairId: args.chairId,
                bookingId: args.bookingId,
                activeServiceStart: now
            }
        });
        await db.chair.update({
            where: { id: args.chairId },
            data: {
                status: "OCCUPIED",
                activeServiceStart: now,
                activeServiceEnd: null
            }
        });
        return allocation;
    }
    async releaseChair(db, chairId, bookingId, endAt = new Date()) {
        await db.chairAllocation.updateMany({
            where: { chairId, bookingId, releasedAt: null },
            data: { releasedAt: endAt, activeServiceEnd: endAt }
        });
        return db.chair.update({
            where: { id: chairId },
            data: {
                status: "AVAILABLE",
                activeServiceStart: null,
                activeServiceEnd: endAt
            }
        });
    }
    async markChairCleaning(db, chairId) {
        return db.chair.update({
            where: { id: chairId },
            data: { status: "CLEANING" }
        });
    }
    async finishChairCleaning(db, chairId) {
        return db.chair.update({
            where: { id: chairId },
            data: { status: "AVAILABLE", activeServiceEnd: null }
        });
    }
    async updateBarberRollingAverage(db, barberId, actualMinutes) {
        const barber = await db.barber.findUnique({ where: { id: barberId } });
        if (!barber)
            return;
        const prev = barber.averageServiceMinutes;
        const next = prev == null ? actualMinutes : Math.round(prev * 0.7 + actualMinutes * 0.3);
        await db.barber.update({
            where: { id: barberId },
            data: { averageServiceMinutes: next }
        });
    }
}
