import { PrismaReviewRepository } from "./infrastructure/review.repository.js";
import { ReviewService } from "./application/review.service.js";

export function buildReviewDependencies() {
  const repository = new PrismaReviewRepository();
  const service = new ReviewService(repository);

  return { repository, service };
}

declare module "fastify" {
  interface FastifyInstance {
    reviewDeps: ReturnType<typeof buildReviewDependencies>;
  }
}
