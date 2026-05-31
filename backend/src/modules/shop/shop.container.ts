import { PrismaShopRepository } from "./infrastructure/shop.repository.js";
import { ShopService } from "./application/shop.service.js";

export function buildShopDependencies() {
  const repository = new PrismaShopRepository();
  const service = new ShopService(repository);

  return { repository, service };
}

declare module "fastify" {
  interface FastifyInstance {
    shopDeps: ReturnType<typeof buildShopDependencies>;
  }
}
