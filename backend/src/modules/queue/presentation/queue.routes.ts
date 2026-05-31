import type { FastifyPluginAsync } from "fastify";
import { QueueController } from "./queue.controller.js";
import { WaitTimeController } from "./wait-time.controller.js";

export const queueRoutes: FastifyPluginAsync = async (app) => {
  const controller = new QueueController(app.queueDeps.coordinator);
  const waitTimeController = new WaitTimeController(app.queueDeps.waitTime);

  app.post("/shops/:shopId/queue/enqueue", { preHandler: app.authenticate }, controller.enqueue);
  app.post("/shops/:shopId/queue/rebalance", { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) }, controller.rebalance);
  app.get("/shops/:shopId/queue", { preHandler: app.authenticate }, controller.list);
  app.post("/bookings/:bookingId/check-in", { preHandler: app.authenticate }, controller.checkIn);
  app.post("/bookings/:bookingId/start", { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) }, controller.markInService);
  app.post("/bookings/:bookingId/complete", { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) }, controller.complete);
  app.post("/bookings/:bookingId/no-show", { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) }, controller.skip);

  app.get("/shops/:shopId/wait-estimates", { preHandler: app.authenticate }, waitTimeController.getEstimates);
  app.post(
    "/shops/:shopId/wait-estimates/recalculate",
    { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) },
    waitTimeController.recalculate
  );
  app.post(
    "/shops/:shopId/barbers/:barberId/delay",
    { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) },
    waitTimeController.reportBarberDelay
  );
  app.post(
    "/shops/:shopId/barbers/:barberId/overrun",
    { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) },
    waitTimeController.reportOverrun
  );
};
