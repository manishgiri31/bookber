import type { FastifyPluginAsync, FastifyRequest, FastifyReply } from "fastify";

export const loyaltyRoutes: FastifyPluginAsync = async (app) => {
  const svc = app.loyaltyDeps.service;
  const auth = { preHandler: [app.authenticate] };

  app.get("/loyalty/account", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const user = (req as any).user as { id: string };
    const account = await svc.getAccount(user.id);
    return reply.send(account);
  });

  app.get("/loyalty/transactions", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const user = (req as any).user as { id: string };
    const transactions = await svc.getTransactions(user.id);
    return reply.send({ transactions });
  });

  app.post("/loyalty/redeem", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const user = (req as any).user as { id: string };
    const { points, reason } = req.body as { points: number; reason: string };
    if (!points || !reason) {
      return reply.status(400).send({ error: "points and reason are required" });
    }
    try {
      await svc.redeem(user.id, points, reason);
      const account = await svc.getAccount(user.id);
      return reply.send({ points: account.points, tier: account.tier });
    } catch (err: any) {
      return reply.status(400).send({ error: err.message });
    }
  });
};
