import type { FastifyPluginAsync, FastifyRequest, FastifyReply } from "fastify";

export const couponRoutes: FastifyPluginAsync = async (app) => {
  const svc = app.couponDeps.service;
  const auth = { preHandler: [app.authenticate] };

  app.post("/coupons/validate", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const user = (req as any).user as { id: string };
    const { code, orderAmount } = req.body as { code: string; orderAmount: number };
    if (!code || !orderAmount) {
      return reply.status(400).send({ error: "code and orderAmount are required" });
    }
    try {
      const result = await svc.validate(code, user.id, orderAmount);
      return reply.send(result);
    } catch (err: any) {
      return reply.status(400).send({ error: err.message });
    }
  });

  app.post("/coupons/redeem", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const user = (req as any).user as { id: string };
    const { couponId, bookingId } = req.body as { couponId: string; bookingId: string };
    if (!couponId || !bookingId) {
      return reply.status(400).send({ error: "couponId and bookingId are required" });
    }
    try {
      const redemption = await svc.redeem(couponId, user.id, bookingId);
      return reply.send({ redemption });
    } catch (err: any) {
      return reply.status(400).send({ error: err.message });
    }
  });

  app.post("/coupons", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const user = (req as any).user as { id: string; role: string };
    if (user.role !== "ADMIN") return reply.status(403).send({ error: "Admin only" });
    const body = req.body as {
      code: string;
      type: "PERCENT" | "FLAT";
      value: number;
      maxRedemptions?: number;
      expiresAt?: string;
      minAmount?: number;
    };
    const coupon = await svc.create({
      ...body,
      expiresAt: body.expiresAt ? new Date(body.expiresAt) : undefined,
    });
    return reply.status(201).send(coupon);
  });
};
