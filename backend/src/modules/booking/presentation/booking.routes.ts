import type { FastifyPluginAsync } from "fastify";
import { BookingController } from "./booking.controller.js";

export const bookingRoutes: FastifyPluginAsync = async (app) => {
  const controller = new BookingController(app.bookingDeps.service);

  app.post("/", { preHandler: app.authenticate }, controller.create);
  app.post("/:bookingId/check-in", { preHandler: app.authenticate }, controller.checkIn);
  app.post("/:bookingId/start", { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) }, controller.startService);
  app.post("/:bookingId/complete", { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) }, controller.completeService);
  app.post("/:bookingId/no-show", { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) }, controller.markNoShow);
  app.post("/:bookingId/cancel", { preHandler: app.authenticate }, controller.cancel);
  app.get("/:bookingId", { preHandler: app.authenticate }, controller.getOne);
  app.get("/shops/:shopId", { preHandler: app.authenticate }, controller.listShop);
};
