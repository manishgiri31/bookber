import { PrismaCouponRepository } from "./infrastructure/coupon.repository.js";
import { CouponService } from "./application/coupon.service.js";

export interface CouponDependencies {
  repo: PrismaCouponRepository;
  service: CouponService;
}

export function buildCouponDependencies(): CouponDependencies {
  const repo = new PrismaCouponRepository();
  const service = new CouponService(repo);
  return { repo, service };
}
