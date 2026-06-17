import type { FastifyInstance } from "fastify";
import type { AnalyticsController } from "./analytics.controller.js";

export function registerAnalyticsRoutes(
  app: FastifyInstance,
  controller: AnalyticsController
): void {
  app.get(
    "/shops/:shopId/analytics/daily",
    { schema: { tags: ["Analytics"] } },
    (req, reply) => controller.getDailyAnalytics(req as any, reply)
  );

  app.get(
    "/shops/:shopId/analytics/peak-hours",
    { schema: { tags: ["Analytics"] } },
    (req, reply) => controller.getPeakHours(req as any, reply)
  );

  app.get(
    "/shops/:shopId/analytics/utilization",
    { schema: { tags: ["Analytics"] } },
    (req, reply) => controller.getUtilization(req as any, reply)
  );

  app.get(
    "/shops/:shopId/analytics/insights",
    { schema: { tags: ["Analytics"] } },
    (req, reply) => controller.getWeeklyInsights(req as any, reply)
  );
}
