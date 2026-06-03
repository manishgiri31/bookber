import type { FastifyPluginAsync } from "fastify";
import { PaymentController } from "./payment.controller.js";

export const paymentRoutes: FastifyPluginAsync = async (app) => {
  const controller = new PaymentController(app.paymentDeps.service);

  app.post("/payments", { preHandler: app.authenticate }, controller.create);
  app.post("/payments/process", { preHandler: app.authenticate }, controller.process);
  app.post("/payments/refund", { preHandler: app.authenticate }, controller.refund);
  app.get("/payments/history", { preHandler: app.authenticate }, controller.getHistory);
  app.get("/payments/:paymentId", { preHandler: app.authenticate }, controller.getById);
};
