import type { FastifyPluginAsync, FastifyRequest, FastifyReply } from "fastify";
import { getAuthUser } from "../../auth/presentation/auth-user.js";

export const loyaltyRoutes: FastifyPluginAsync = async (app) => {
  const svc = app.loyaltyDeps.service;
  const auth = { preHandler: [app.authenticate] };

  app.get("/loyalty/account", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const userId = getAuthUser(req).id;
    const account = await svc.getAccount(userId);
    return reply.send(account);
  });

  app.get("/loyalty/transactions", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const userId = getAuthUser(req).id;
    const transactions = await svc.getTransactions(userId);
    return reply.send({ transactions });
  });

  app.post("/loyalty/redeem", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const userId = getAuthUser(req).id;
    const { points, reason } = req.body as { points: number; reason: string };
    if (!points || !reason) {
      return reply.status(400).send({ error: "points and reason are required" });
    }
    try {
      await svc.redeem(userId, points, reason);
      const account = await svc.getAccount(userId);
      return reply.send({ points: account.points, tier: account.tier });
    } catch (err: any) {
      return reply.status(400).send({ error: err.message });
    }
  });
};
