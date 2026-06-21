import type { FastifyInstance } from "fastify";
import type { AnalyticsController } from "./analytics.controller.js";

export function registerAnalyticsRoutes(
  app: FastifyInstance,
  controller: AnalyticsController
): void {
  const auth = { preHandler: [app.authenticate] };

  app.get(
    "/shops/:shopId/analytics/daily",
    auth,
    (req, reply) => controller.getDailyAnalytics(req as any, reply)
  );

  app.get(
    "/shops/:shopId/analytics/peak-hours",
    auth,
    (req, reply) => controller.getPeakHours(req as any, reply)
  );

  app.get(
    "/shops/:shopId/analytics/utilization",
    auth,
    (req, reply) => controller.getUtilization(req as any, reply)
  );

  app.get(
    "/shops/:shopId/analytics/insights",
    auth,
    (req, reply) => controller.getWeeklyInsights(req as any, reply)
  );
}
