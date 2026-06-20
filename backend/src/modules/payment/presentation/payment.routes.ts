import type { FastifyPluginAsync, FastifyRequest, FastifyReply } from "fastify";
import { PaymentController } from "./payment.controller.js";

export const paymentRoutes: FastifyPluginAsync = async (app) => {
  const controller = new PaymentController(app.paymentDeps.service);

  app.post("/payments", { preHandler: app.authenticate }, controller.create);
  app.post("/payments/process", { preHandler: app.authenticate }, controller.process);
  app.post("/payments/refund", { preHandler: app.authenticate }, controller.refund);
  app.get("/payments/history", { preHandler: app.authenticate }, controller.getHistory);
  app.get("/payments/:paymentId", { preHandler: app.authenticate }, controller.getById);

  // ─── Razorpay ──────────────────────────────────────────────────────────────

  app.post(
    "/payments/razorpay/order",
    { preHandler: app.authenticate },
    async (req: FastifyRequest, reply: FastifyReply) => {
      const { bookingId, amount } = req.body as { bookingId: string; amount: number };
      if (!bookingId || !amount) {
        return reply.status(400).send({ error: "bookingId and amount are required" });
      }
      const result = await app.paymentDeps.service.createRazorpayOrder(bookingId, amount);
      return reply.send(result);
    }
  );

  app.post(
    "/payments/razorpay/verify",
    { preHandler: app.authenticate },
    async (req: FastifyRequest, reply: FastifyReply) => {
      const { bookingId, razorpayOrderId, razorpayPaymentId, razorpaySignature } =
        req.body as {
          bookingId: string;
          razorpayOrderId: string;
          razorpayPaymentId: string;
          razorpaySignature: string;
        };
      const payment = await app.paymentDeps.service.verifyRazorpayPayment({
        bookingId,
        razorpayOrderId,
        razorpayPaymentId,
        razorpaySignature,
      });
      return reply.send({ payment, success: true });
    }
  );

  app.post(
    "/payments/webhook",
    async (req: FastifyRequest, reply: FastifyReply) => {
      const signature = req.headers["x-razorpay-signature"] as string | undefined;
      if (!signature) {
        return reply.status(400).send({ error: "Missing signature header" });
      }
      const rawBody = JSON.stringify(req.body);
      await app.paymentDeps.service.handleWebhook(rawBody, signature);
      return reply.send({ received: true });
    }
  );
};
