import type { FastifyPluginAsync, FastifyRequest, FastifyReply } from "fastify";

export const walletRoutes: FastifyPluginAsync = async (app) => {
  const svc = app.walletDeps.service;
  const auth = { preHandler: [app.authenticate] };

  app.get("/wallet/balance", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const user = (req as any).user as { id: string };
    const wallet = await svc.getWallet(user.id);
    return reply.send({ balance: wallet.balance });
  });

  app.get("/wallet/transactions", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const user = (req as any).user as { id: string };
    const transactions = await svc.getTransactions(user.id);
    return reply.send({ transactions });
  });

  app.post("/wallet/topup", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const user = (req as any).user as { id: string };
    const { amount, refId } = req.body as { amount: number; refId: string };
    if (!amount || !refId) {
      return reply.status(400).send({ error: "amount and refId are required" });
    }
    const [wallet] = await svc.topUp(user.id, amount, refId);
    return reply.send({ balance: (wallet as any).balance });
  });
};
