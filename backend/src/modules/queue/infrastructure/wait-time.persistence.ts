import type { Prisma, ServiceCategory } from "@prisma/client";
import { prisma } from "../../../shared/prisma/client.js";
import type { WaitEstimateResult } from "../domain/wait-time.types.js";
import { arrivalWindowFromWait, updateHistoricalAverage } from "../application/wait-time.calculator.js";
import type { WaitTimeRedisStore } from "./wait-time-redis.store.js";

type DbClient = Prisma.TransactionClient | typeof prisma;

/**
 * Eventual consistency layer — Postgres writes happen after Redis recalc commits.
 */
export class WaitTimePersistence {
  constructor(private readonly redis: WaitTimeRedisStore) {}

  async applyEstimatesToDatabase(
    db: DbClient,
    shopId: string,
    estimates: WaitEstimateResult[],
    _durationByBooking: Map<string, number>
  ): Promise<void> {
    for (const est of estimates) {
      const window = arrivalWindowFromWait(est.estimatedServiceStart);

      await db.queueEntry.updateMany({
        where: { bookingId: est.bookingId, shopId },
        data: {
          position: est.position,
          estimatedWaitMinutes: est.estimatedWaitMinutes,
          estimatedServiceStart: est.estimatedServiceStart,
          version: { increment: 1 }
        }
      });

      await db.booking.update({
        where: { id: est.bookingId },
        data: {
          arrivalWindowStart: window.start,
          arrivalWindowEnd: window.end
        }
      });
    }
  }

  /**
   * Records a completed service sample — updates Redis immediately, DB barber average async.
   */
  async recordServiceSample(args: {
    shopId: string;
    barberId: string | null;
    category: ServiceCategory;
    actualMinutes: number;
  }): Promise<void> {
    const { shopId, barberId, category, actualMinutes } = args;

    try {
      const shopAvgs = await this.redis.getShopAverages(shopId);
      const nextShopRecent = {
        ...shopAvgs.recent,
        [category]: Math.round(
          (shopAvgs.recent[category] ?? actualMinutes) * 0.7 + actualMinutes * 0.3
        )
      };
      const nextShopHist = {
        ...shopAvgs.historical,
        [category]: updateHistoricalAverage(shopAvgs.historical[category], actualMinutes)
      };
      await this.redis.setShopAverages(shopId, nextShopHist, nextShopRecent);

      if (barberId) {
        const barberAvgs = await this.redis.getBarberAverages(barberId);
        const nextBarberRecent = {
          ...barberAvgs.recent,
          [category]: Math.round(
            (barberAvgs.recent[category] ?? actualMinutes) * 0.7 + actualMinutes * 0.3
          )
        };
        const nextBarberHist = {
          ...barberAvgs.historical,
          [category]: updateHistoricalAverage(barberAvgs.historical[category], actualMinutes)
        };
        await this.redis.setBarberAverages(barberId, nextBarberHist, nextBarberRecent);

        void prisma.barber
          .update({
            where: { id: barberId },
            data: { averageServiceMinutes: nextBarberHist[category] ?? actualMinutes }
          })
          .catch(() => undefined);
      }
    } catch {
      /* Redis optional in dev — DB path still valid via queue engine */
    }
  }

  async clearBarberCompensation(barberId: string): Promise<void> {
    try {
      await this.redis.setBarberState(barberId, {
        delayMinutes: 0,
        overrunMinutes: 0,
        updatedAtMs: Date.now()
      });
    } catch {
      /* ignore */
    }
  }
}
