import type { FastifyInstance } from "fastify";
import type { AnalyticsController } from "./analytics.controller.js";

export function registerAnalyticsRoutes(
  app: FastifyInstance,
  controller: AnalyticsController
): void {
  const auth = { preHandler: [app.authenticate] };

  app.get(
    "/shops/:shopId/analytics/daily",
    { ...auth, schema: { tags: ["Analytics"] } },
    (req, reply) => controller.getDailyAnalytics(req as any, reply)
  );

  app.get(
    "/shops/:shopId/analytics/peak-hours",
    { ...auth, schema: { tags: ["Analytics"] } },
    (req, reply) => controller.getPeakHours(req as any, reply)
  );

  app.get(
    "/shops/:shopId/analytics/utilization",
    { ...auth, schema: { tags: ["Analytics"] } },
    (req, reply) => controller.getUtilization(req as any, reply)
  );

  app.get(
    "/shops/:shopId/analytics/insights",
    { ...auth, schema: { tags: ["Analytics"] } },
    (req, reply) => controller.getWeeklyInsights(req as any, reply)
  );
}
