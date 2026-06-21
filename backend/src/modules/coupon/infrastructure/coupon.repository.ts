import { prisma } from "../../../shared/prisma/client.js";

export class PrismaCouponRepository {
  async findByCode(code: string) {
    return prisma.coupon.findUnique({ where: { code } });
  }

  async validate(code: string, userId: string, orderAmount: number) {
    const coupon = await this.findByCode(code);
    if (!coupon) throw new Error("Invalid coupon code");
    if (!coupon.isActive) throw new Error("Coupon is not active");
    if (coupon.expiresAt && coupon.expiresAt < new Date()) throw new Error("Coupon has expired");
    if (coupon.minAmount && orderAmount < coupon.minAmount) {
      throw new Error(`Minimum order amount is ₹${coupon.minAmount}`);
    }

    const redemptionCount = await prisma.couponRedemption.count({
      where: { couponId: coupon.id },
    });
    if (coupon.maxRedemptions && redemptionCount >= coupon.maxRedemptions) {
      throw new Error("Coupon redemption limit reached");
    }

    const userRedeemed = await prisma.couponRedemption.findFirst({
      where: { couponId: coupon.id, userId },
    });
    if (userRedeemed) throw new Error("You have already used this coupon");

    const discount =
      coupon.type === "PERCENT"
        ? Math.floor((orderAmount * coupon.value) / 100)
        : coupon.value;

    return { coupon, discount, finalAmount: Math.max(0, orderAmount - discount) };
  }

  async redeem(couponId: string, userId: string, bookingId: string, discount: number) {
    return prisma.couponRedemption.create({
      data: { couponId, userId, bookingId, discount },
    });
  }

  async create(data: {
    code: string;
    type: "PERCENT" | "FLAT";
    value: number;
    maxRedemptions?: number;
    expiresAt?: Date;
    minAmount?: number;
  }) {
    return prisma.coupon.create({
      data: {
        code: data.code,
        type: data.type,
        value: data.value,
        ...(data.maxRedemptions !== undefined && { maxRedemptions: data.maxRedemptions }),
        ...(data.expiresAt !== undefined && { expiresAt: data.expiresAt }),
        ...(data.minAmount !== undefined && { minAmount: data.minAmount }),
      },
    });
  }
}
