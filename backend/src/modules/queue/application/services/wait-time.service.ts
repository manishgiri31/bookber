import { Prisma, type QueueLane, type ServiceCategory } from "@prisma/client";
import type { PrismaQueueRepository } from "../../infrastructure/queue.repository.js";
import { WaitTimeEngine } from "../wait-time.engine.js";
import { WAIT_RECALC_TRIGGERS } from "../../domain/wait-time.types.js";
import type { BookingWaitSnapshot, WaitEstimateResult } from "../../domain/wait-time.types.js";
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
  constructor(
    private readonly repository: PrismaQueueRepository,
    private readonly waitTime: WaitTimeEngine
  ) { }

  /**
   * Recalculate wait times for a lane
   */
  async recalculateLane(
    shopId: string,
    lane: QueueLane,
    trigger: (typeof WAIT_RECALC_TRIGGERS)[keyof typeof WAIT_RECALC_TRIGGERS]
  ): Promise<{
    estimates: Array<{
      bookingId: string;
      position: number;
      estimatedWaitMinutes: number;
      estimatedServiceStart: Date;
      effectiveDurationMinutes: number;
      cleaningBufferMinutes: number;
      delayCompensationMinutes: number;
      overrunCompensationMinutes: number;
    }>;
  }> {
    const recalc = await this.waitTime.recalculateLane(shopId, lane, trigger);
    return {
      estimates: recalc.estimates
    };
  }

  /**
   * Sync booking snapshot to Redis
   */
  async syncBookingSnapshot(snapshot: BookingWaitSnapshot): Promise<void> {
    await this.waitTime.syncBookingSnapshot(snapshot);
  }

  /**
   * Record service overrun for a barber
   */
  async recordServiceOverrun(shopId: string, barberId: string, overrunMinutes: number): Promise<void> {
    await this.waitTime.recordServiceOverrun(shopId, barberId, overrunMinutes);
  }

  /**
   * Record service sample for a barber
   */
  async recordServiceSample(sample: {
    shopId: string;
    barberId: string;
    category: ServiceCategory;
    actualMinutes: number;
  }): Promise<void> {
    await this.waitTime.persistence.recordServiceSample(sample);
  }

  /**
   * Apply wait time estimates to database
   */
  async applyEstimatesToDatabase(
    tx: Prisma.TransactionClient,
    shopId: string,
    estimates: WaitEstimateResult[],
    durationMap: Map<string, number>
  ): Promise<void> {
    await this.waitTime.persistence.applyEstimatesToDatabase(
      tx,
      shopId,
      estimates,
      durationMap
    );
  }

  /**
   * Get wait time for a specific booking
   */
  async getBookingWaitTime(bookingId: string): Promise<number> {
    const activeQueue = await this.repository.findBooking(prisma, bookingId);
    if (!activeQueue) return 0;
    return activeQueue.queueEntry?.estimatedWaitMinutes ?? 0;
  }

  /**
   * Get lane wait times
   */
  async getLaneWaitTimes(shopId: string, lane: QueueLane): Promise<Array<{
    bookingId: string;
    position: number;
    estimatedWaitMinutes: number;
    estimatedServiceStart: Date;
  }>> {
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
  async recalculateShop(shopId: string): Promise<{
    bookBerEstimates: Array<{
      bookingId: string;
      position: number;
      estimatedWaitMinutes: number;
      estimatedServiceStart: Date;
    }>;
    walkInEstimates: Array<{
      bookingId: string;
      position: number;
      estimatedWaitMinutes: number;
      estimatedServiceStart: Date;
    }>;
  }> {
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
