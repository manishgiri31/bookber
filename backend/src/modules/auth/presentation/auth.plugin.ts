import type { FastifyInstance, FastifyPluginCallback, FastifyRequest } from "fastify";
import fp from "fastify-plugin";

import { env } from "../../../shared/config/env.js";

import type { AccessTokenPayload } from "./auth-user.js";

const authPluginImpl: FastifyPluginCallback = (app: FastifyInstance, _opts, done) => {
  app.decorate("authenticate", (request: FastifyRequest) => {
    const bearer = request.headers.authorization?.startsWith("Bearer ")
      ? request.headers.authorization.slice(7)
      : undefined;
    const token = request.cookies?.[env.ACCESS_TOKEN_COOKIE_NAME] ?? bearer;

    if (!token) {
      throw app.httpErrors.unauthorized("Missing access token");
    }

    request.user = app.jwt.verify<AccessTokenPayload>(token);
    return Promise.resolve();
  });

  app.decorate("authorizeRoles", (roles: Array<"CLIENT" | "BARBER" | "ADMIN">) => {
    return async (request: FastifyRequest) => {
      await app.authenticate(request);
      const user = request.user;
      if (!user?.sub || !roles.includes(user.role)) {
        throw app.httpErrors.forbidden("Insufficient permissions");
      }
    };
  });
  done();
};

export const authPlugin = fp(authPluginImpl, {
  name: "auth-plugin"
});

declare module "@fastify/jwt" {
  interface FastifyJWT {
    user: AccessTokenPayload;
  }
}

declare module "fastify" {
  interface FastifyInstance {
    authenticate: (request: FastifyRequest) => Promise<void>;
    authorizeRoles: (
      roles: Array<"CLIENT" | "BARBER" | "ADMIN">
    ) => (request: FastifyRequest) => Promise<void>;
  }
}
