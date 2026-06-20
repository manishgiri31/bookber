import type { PrismaLoyaltyRepository } from "../infrastructure/loyalty.repository.js";

const POINTS_PER_BOOKING = 10;

export class LoyaltyService {
  constructor(private readonly repo: PrismaLoyaltyRepository) {}

  async getAccount(userId: string) {
    return this.repo.getOrCreate(userId);
  }

  async awardForBooking(userId: string, bookingId: string) {
    return this.repo.award(userId, POINTS_PER_BOOKING, "Booking completed", bookingId);
  }

  async award(userId: string, points: number, reason: string, refId?: string) {
    return this.repo.award(userId, points, reason, refId);
  }

  async redeem(userId: string, points: number, reason: string, refId?: string) {
    return this.repo.redeem(userId, points, reason, refId);
  }

  async getTransactions(userId: string) {
    return this.repo.getTransactions(userId);
  }
}
