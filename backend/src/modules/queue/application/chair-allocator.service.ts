import type { Chair, QueueLane } from "@prisma/client";
import { Errors } from "../../../shared/http/app-error.js";
import type { PrismaQueueRepository, DbClient } from "../infrastructure/queue.repository.js";

export class ChairAllocator {
  constructor(private readonly repository: PrismaQueueRepository) {}

  /**
   * Walk-ins only use non-reserved chairs; BookBer queue only uses reserved chairs.
   */
  async findAvailableChair(db: DbClient, shopId: string, lane: QueueLane): Promise<Chair | null> {
    return this.repository.findAvailableChairForLane(db, shopId, lane);
  }

  async allocateToBooking(
    db: DbClient,
    args: { shopId: string; chair: Chair; bookingId: string; lane: QueueLane; startNow?: boolean }
  ) {
    const chair = args.chair;
    if (args.lane === "WALKIN" && chair.reservedForBookBer) {
      throw Errors.conflict("Walk-in cannot use BookBer reserved chair");
    }
    if (args.lane === "BOOKBER" && !chair.reservedForBookBer) {
      throw Errors.conflict("BookBer customer requires a reserved chair");
    }

    return this.repository.assignChair(db, {
      shopId: args.shopId,
      chairId: chair.id,
      bookingId: args.bookingId,
      ...(args.startNow ? { activeServiceStart: new Date() } : {})
    });
  }
}
