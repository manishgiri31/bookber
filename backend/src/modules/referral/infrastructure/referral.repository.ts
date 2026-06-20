import { prisma } from "../../../shared/prisma/client.js";
import { randomBytes } from "crypto";

export class PrismaReferralRepository {

  private generateCode(): string {
    return randomBytes(4).toString("hex").toUpperCase();
  }

  async getOrCreateCode(referrerId: string): Promise<string> {
    const existing = await this.prisma.referral.findFirst({
      where: { referrerId, refereeId: null },
    });
    if (existing) return existing.code;
    const code = this.generateCode();
    await this.prisma.referral.create({
      data: { referrerId, code, status: "PENDING" },
    });
    return code;
  }

  async applyReferral(code: string, refereeId: string) {
    const referral = await this.prisma.referral.findFirst({
      where: { code, refereeId: null, status: "PENDING" },
    });
    if (!referral) throw new Error("Invalid or already-used referral code");
    if (referral.referrerId === refereeId) throw new Error("Cannot use your own referral code");
    return this.prisma.referral.update({
      where: { id: referral.id },
      data: { refereeId, status: "COMPLETED" },
    });
  }

  async getReferralsByReferrer(referrerId: string) {
    return this.prisma.referral.findMany({
      where: { referrerId },
      orderBy: { createdAt: "desc" },
    });
  }

  async markRewarded(referralId: string) {
    return this.prisma.referral.update({
      where: { id: referralId },
      data: { rewardGranted: true },
    });
  }
}
