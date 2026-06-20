import { PrismaReferralRepository } from "./infrastructure/referral.repository.js";
import { ReferralService } from "./application/referral.service.js";

export interface ReferralDependencies {
  repo: PrismaReferralRepository;
  service: ReferralService;
}

export function buildReferralDependencies(): ReferralDependencies {
  const repo = new PrismaReferralRepository();
  const service = new ReferralService(repo);
  return { repo, service };
}
