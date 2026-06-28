import type { FastifyPluginAsync, FastifyRequest, FastifyReply } from "fastify";
import { getAuthUser } from "../../auth/presentation/auth-user.js";

export const couponRoutes: FastifyPluginAsync = async (app) => {
  const svc = app.couponDeps.service;
  const auth = { preHandler: [app.authenticate] };

  app.post("/coupons/validate", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const { id } = getAuthUser(req);
    const { code, orderAmount } = req.body as { code: string; orderAmount: number };
    if (!code || !orderAmount) {
      return reply.status(400).send({ error: "code and orderAmount are required" });
    }
    try {
      const result = await svc.validate(code, id, orderAmount);
      return reply.send(result);
    } catch (err: any) {
      return reply.status(400).send({ error: err.message });
    }
  });

  app.post("/coupons/redeem", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const { id } = getAuthUser(req);
    const { couponId, bookingId, discount } = req.body as { couponId: string; bookingId: string; discount: number };
    if (!couponId || !bookingId || discount === undefined) {
      return reply.status(400).send({ error: "couponId, bookingId and discount are required" });
    }
    try {
      const redemption = await svc.redeem(couponId, id, bookingId, discount);
      return reply.send({ redemption });
    } catch (err: any) {
      return reply.status(400).send({ error: err.message });
    }
  });

  app.post("/coupons", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const { role } = getAuthUser(req);
    if (role !== "ADMIN") return reply.status(403).send({ error: "Admin only" });
    const body = req.body as {
      code: string;
      type: "PERCENT" | "FLAT";
      value: number;
      maxRedemptions?: number;
      expiresAt?: string;
      minAmount?: number;
    };
    const coupon = await svc.create({
      code: body.code,
      type: body.type,
      value: body.value,
      ...(body.maxRedemptions !== undefined && { maxRedemptions: body.maxRedemptions }),
      ...(body.expiresAt !== undefined && { expiresAt: new Date(body.expiresAt) }),
      ...(body.minAmount !== undefined && { minAmount: body.minAmount }),
    });
    return reply.status(201).send(coupon);
  });
};
