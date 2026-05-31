import type { FastifyPluginAsync } from "fastify";
import { AdminController } from "./admin.controller.js";

export const adminRoutes: FastifyPluginAsync = async (app) => {
  const controller = new AdminController(app.adminDeps.service);

  // All admin routes require ADMIN role
  app.addHook("onRequest", async (request, reply) => {
    const user = request.user as any;
    if (!user || user.role !== "ADMIN") {
      return reply.status(403).send({ error: "Forbidden - Admin access required" });
    }
  });

  // Dashboard and Analytics
  app.get("/admin/dashboard", controller.getDashboard);
  app.get("/admin/analytics/overview", controller.getAnalyticsOverview);
  app.get("/admin/analytics/bookings", controller.getBookingAnalytics);
  app.get("/admin/analytics/earnings", controller.getEarningsOverview);

  // Barber Moderation
  app.get("/admin/barbers", controller.getBarberModerationList);
  app.post("/admin/moderation/action", controller.executeModerationAction);

  // Active Queue Monitoring
  app.get("/admin/queues/active", controller.getActiveQueueMonitoring);
};
