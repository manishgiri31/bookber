import type { FastifyPluginAsync } from "fastify";
import { ReviewController } from "./review.controller.js";

export const reviewRoutes: FastifyPluginAsync = async (app) => {
  const controller = new ReviewController(app.reviewDeps.service);

  app.post("/reviews", { preHandler: app.authenticate }, controller.create);
  app.get("/shops/:shopId/reviews", { preHandler: app.authenticate }, controller.getShopReviews);
  app.get("/reviews/my", { preHandler: app.authenticate }, controller.getUserReviews);
};
