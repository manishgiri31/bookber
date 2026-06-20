import type { PrismaReferralRepository } from "../infrastructure/referral.repository.js";

const REFERRAL_REWARD_POINTS = 50;

export class ReferralService {
  constructor(private readonly repo: PrismaReferralRepository) {}

  async getMyCode(userId: string) {
    const code = await this.repo.getOrCreateCode(userId);
    return { code };
  }

  async applyCode(code: string, refereeId: string) {
    return this.repo.applyReferral(code, refereeId);
  }

  async getMyReferrals(userId: string) {
    return this.repo.getReferralsByReferrer(userId);
  }

  async rewardReferrer(referralId: string) {
    await this.repo.markRewarded(referralId);
    return REFERRAL_REWARD_POINTS;
  }

  get rewardPoints() {
    return REFERRAL_REWARD_POINTS;
  }
}
