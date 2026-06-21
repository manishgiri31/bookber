import type { PrismaCouponRepository } from "../infrastructure/coupon.repository.js";

export class CouponService {
  constructor(private readonly repo: PrismaCouponRepository) {}

  async validate(code: string, userId: string, orderAmount: number) {
    return this.repo.validate(code, userId, orderAmount);
  }

  async redeem(couponId: string, userId: string, bookingId: string, discount: number) {
    return this.repo.redeem(couponId, userId, bookingId, discount);
  }

  async create(data: {
    code: string;
    type: "PERCENT" | "FLAT";
    value: number;
    maxRedemptions?: number;
    expiresAt?: Date;
    minAmount?: number;
  }) {
    return this.repo.create(data);
  }
}
