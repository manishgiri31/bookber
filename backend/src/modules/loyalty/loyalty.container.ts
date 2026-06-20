import { PrismaLoyaltyRepository } from "./infrastructure/loyalty.repository.js";
import { LoyaltyService } from "./application/loyalty.service.js";

export interface LoyaltyDependencies {
  repo: PrismaLoyaltyRepository;
  service: LoyaltyService;
}

export function buildLoyaltyDependencies(): LoyaltyDependencies {
  const repo = new PrismaLoyaltyRepository();
  const service = new LoyaltyService(repo);
  return { repo, service };
}
