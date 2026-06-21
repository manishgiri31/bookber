import type { FastifyPluginAsync, FastifyRequest, FastifyReply } from "fastify";
import { getAuthUser } from "../../auth/presentation/auth-user.js";

export const walletRoutes: FastifyPluginAsync = async (app) => {
  const svc = app.walletDeps.service;
  const auth = { preHandler: [app.authenticate] };

  app.get("/wallet/balance", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const userId = getAuthUser(req).id;
    const wallet = await svc.getWallet(userId);
    return reply.send({ balance: wallet.balance });
  });

  app.get("/wallet/transactions", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const userId = getAuthUser(req).id;
    const transactions = await svc.getTransactions(userId);
    return reply.send({ transactions });
  });

  app.post("/wallet/topup", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const userId = getAuthUser(req).id;
    const { amount, refId } = req.body as { amount: number; refId: string };
    if (!amount || !refId) {
      return reply.status(400).send({ error: "amount and refId are required" });
    }
    const [wallet] = await svc.topUp(userId, amount, refId);
    return reply.send({ balance: (wallet as any).balance });
  });
};
