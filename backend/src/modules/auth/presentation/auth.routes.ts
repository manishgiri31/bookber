import type { FastifyPluginAsync } from "fastify";
import type { AccessTokenPayload } from "./auth-user.js";
import { AuthController } from "./auth.controller.js";

export const authRoutes: FastifyPluginAsync = async (app) => {
  const controller = new AuthController(app.authDeps.authService);

  app.post("/register", { config: { rateLimit: { max: 5, timeWindow: "1 hour" } } }, controller.register);
  app.post("/login", { config: { rateLimit: { max: 10, timeWindow: "1 minute" } } }, controller.login);
  app.post("/refresh", { config: { rateLimit: { max: 20, timeWindow: "1 minute" } } }, controller.refresh);
  app.post("/logout", controller.logout);
  app.patch("/change-password", { preHandler: app.authenticate }, controller.changePassword);
  app.get("/me", { preHandler: app.authenticate }, async (request) => {
    const payload = request.user as AccessTokenPayload;
    const user = await app.authDeps.authService.getMe(payload.sub);
    return { user };
  });
};
