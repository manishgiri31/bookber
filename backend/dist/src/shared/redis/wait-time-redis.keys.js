/**
 * Redis key layout (all O(log n) queue ops via sorted sets).
 *
 * QUEUE (sorted set, score = position, member = bookingId)
 *   shop:{shopId}:queue              — BookBer lane
 *   shop:{shopId}:queue:walkin       — walk-in lane
 *
 * BOOKING snapshot (hash, hot read path)
 *   booking:{bookingId}
 *
 * SHOP wait config (hash)
 *   shop:{shopId}:wait:config
 *
 * SHOP service-duration rolling averages (hash, field = ServiceCategory)
 *   shop:{shopId}:avg:historical
 *   shop:{shopId}:avg:recent
 *
 * BARBER duration averages + runtime compensation (hash)
 *   barber:{barberId}:avg:historical
 *   barber:{barberId}:avg:recent
 *   barber:{barberId}:state          — delayMinutes, overrunMinutes
 *
 * INVALIDATION
 *   shop:{shopId}:wait:version       — integer, bumped on every recalc
 *   shop:{shopId}:queue:version      — existing queue snapshot version
 */
export const waitTimeRedisKeys = {
    queue: (shopId, lane) => lane === "BOOKBER" ? `shop:${shopId}:queue` : `shop:${shopId}:queue:walkin`,
    booking: (bookingId) => `booking:${bookingId}`,
    shopWaitConfig: (shopId) => `shop:${shopId}:wait:config`,
    shopAvgHistorical: (shopId) => `shop:${shopId}:avg:historical`,
    shopAvgRecent: (shopId) => `shop:${shopId}:avg:recent`,
    barberAvgHistorical: (barberId) => `barber:${barberId}:avg:historical`,
    barberAvgRecent: (barberId) => `barber:${barberId}:avg:recent`,
    barberState: (barberId) => `barber:${barberId}:state`,
    waitVersion: (shopId) => `shop:${shopId}:wait:version`,
    queueVersion: (shopId) => `shop:${shopId}:queue:version`,
    serviceCategoryField: (category) => category
};
