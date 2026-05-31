import type { QueueLane, ServiceCategory } from "@prisma/client";

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
  queue: (shopId: string, lane: QueueLane): string =>
    lane === "BOOKBER" ? `shop:${shopId}:queue` : `shop:${shopId}:queue:walkin`,

  booking: (bookingId: string): string => `booking:${bookingId}`,

  shopWaitConfig: (shopId: string): string => `shop:${shopId}:wait:config`,

  shopAvgHistorical: (shopId: string): string => `shop:${shopId}:avg:historical`,

  shopAvgRecent: (shopId: string): string => `shop:${shopId}:avg:recent`,

  barberAvgHistorical: (barberId: string): string => `barber:${barberId}:avg:historical`,

  barberAvgRecent: (barberId: string): string => `barber:${barberId}:avg:recent`,

  barberState: (barberId: string): string => `barber:${barberId}:state`,

  waitVersion: (shopId: string): string => `shop:${shopId}:wait:version`,

  queueVersion: (shopId: string): string => `shop:${shopId}:queue:version`,

  serviceCategoryField: (category: ServiceCategory): string => category
} as const;
