import { prisma } from "../../../shared/prisma/client.js";

const TIER_THRESHOLDS = { BRONZE: 0, SILVER: 500, GOLD: 1500, PLATINUM: 3000 };
type Tier = "BRONZE" | "SILVER" | "GOLD" | "PLATINUM";

function computeTier(points: number): Tier {
  if (points >= TIER_THRESHOLDS.PLATINUM) return "PLATINUM";
  if (points >= TIER_THRESHOLDS.GOLD) return "GOLD";
  if (points >= TIER_THRESHOLDS.SILVER) return "SILVER";
  return "BRONZE";
}

export class PrismaLoyaltyRepository {

  async getOrCreate(userId: string) {
    return this.prisma.loyaltyAccount.upsert({
      where: { userId },
      create: { userId, points: 0, tier: "BRONZE" },
      update: {},
      include: { transactions: { orderBy: { createdAt: "desc" }, take: 20 } },
    });
  }

  async award(userId: string, points: number, reason: string, refId?: string) {
    const account = await this.getOrCreate(userId);
    const newPoints = account.points + points;
    const newTier = computeTier(newPoints);
    return this.prisma.$transaction([
      this.prisma.loyaltyAccount.update({
        where: { id: account.id },
        data: { points: { increment: points }, tier: newTier },
      }),
      this.prisma.loyaltyTransaction.create({
        data: { accountId: account.id, points, type: "EARN", reason, refId },
      }),
    ]);
  }

  async redeem(userId: string, points: number, reason: string, refId?: string) {
    const account = await this.getOrCreate(userId);
    if (account.points < points) throw new Error("Insufficient loyalty points");
    const newPoints = account.points - points;
    const newTier = computeTier(newPoints);
    return this.prisma.$transaction([
      this.prisma.loyaltyAccount.update({
        where: { id: account.id },
        data: { points: { decrement: points }, tier: newTier },
      }),
      this.prisma.loyaltyTransaction.create({
        data: { accountId: account.id, points, type: "REDEEM", reason, refId },
      }),
    ]);
  }

  async getTransactions(userId: string) {
    const account = await this.prisma.loyaltyAccount.findUnique({ where: { userId } });
    if (!account) return [];
    return this.prisma.loyaltyTransaction.findMany({
      where: { accountId: account.id },
      orderBy: { createdAt: "desc" },
      take: 50,
    });
  }
}
