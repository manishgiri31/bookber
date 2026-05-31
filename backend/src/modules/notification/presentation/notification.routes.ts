import type { FastifyPluginAsync } from "fastify";
import { NotificationController } from "./notification.controller.js";

export const notificationRoutes: FastifyPluginAsync = async (app) => {
  const controller = new NotificationController(app.notificationDeps.service);

  app.post("/notifications/tokens", { preHandler: app.authenticate }, controller.registerToken);
  app.post("/notifications/send", { preHandler: app.authorizeRoles(["ADMIN"]) }, controller.send);
  app.delete("/notifications/tokens/:token", { preHandler: app.authenticate }, controller.deactivateToken);
};
