import type { FastifyPluginAsync, FastifyRequest, FastifyReply } from "fastify";

export const referralRoutes: FastifyPluginAsync = async (app) => {
  const svc = app.referralDeps.service;
  const auth = { preHandler: [app.authenticate] };

  app.get("/referral/my-code", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const user = (req as any).user as { id: string };
    const result = await svc.getMyCode(user.id);
    return reply.send(result);
  });

  app.get("/referral/my-referrals", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const user = (req as any).user as { id: string };
    const referrals = await svc.getMyReferrals(user.id);
    return reply.send({ referrals });
  });

  app.post("/referral/apply", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const user = (req as any).user as { id: string };
    const { code } = req.body as { code: string };
    if (!code) return reply.status(400).send({ error: "code is required" });
    try {
      const referral = await svc.applyCode(code, user.id);
      return reply.send({ referral, message: "Referral applied successfully" });
    } catch (err: any) {
      return reply.status(400).send({ error: err.message });
    }
  });
};
