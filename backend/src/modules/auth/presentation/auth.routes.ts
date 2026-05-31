import type { FastifyPluginAsync } from "fastify";
import { AuthController } from "./auth.controller.js";

export const authRoutes: FastifyPluginAsync = async (app) => {
  const controller = new AuthController(app.authDeps.authService);

  app.post("/register", controller.register);
  app.post("/login", controller.login);
  app.post("/refresh", controller.refresh);
  app.post("/logout", controller.logout);
  app.get("/me", { preHandler: app.authenticate }, async (request) => ({ user: request.user }));
};
