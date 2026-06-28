import type { FastifyPluginAsync, FastifyRequest, FastifyReply } from "fastify";
import { getAuthUser } from "../../auth/presentation/auth-user.js";

export const referralRoutes: FastifyPluginAsync = async (app) => {
  const svc = app.referralDeps.service;
  const auth = { preHandler: [app.authenticate] };

  app.get("/referral/my-code", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const { id } = getAuthUser(req);
    const result = await svc.getMyCode(id);
    return reply.send(result);
  });

  app.get("/referral/my-referrals", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const { id } = getAuthUser(req);
    const referrals = await svc.getMyReferrals(id);
    return reply.send({ referrals });
  });

  app.post("/referral/apply", auth, async (req: FastifyRequest, reply: FastifyReply) => {
    const { id } = getAuthUser(req);
    const { code } = req.body as { code: string };
    if (!code) return reply.status(400).send({ error: "code is required" });
    try {
      const referral = await svc.applyCode(code, id);
      return reply.send({ referral, message: "Referral applied successfully" });
    } catch (err: any) {
      return reply.status(400).send({ error: err.message });
    }
  });
};
