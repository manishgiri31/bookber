import Fastify, { type FastifyInstance, type FastifyRequest } from "fastify";
import cookie from "@fastify/cookie";
import cors from "@fastify/cors";
import helmet from "@fastify/helmet";
import jwt from "@fastify/jwt";
import rateLimit from "@fastify/rate-limit";
import sensible from "@fastify/sensible";

import { authRoutes } from "./modules/auth/presentation/auth.routes.js";
import { authPlugin } from "./modules/auth/presentation/auth.plugin.js";
import { buildAuthDependencies } from "./modules/auth/auth.container.js";
import { buildShopDependencies } from "./modules/shop/shop.container.js";
// import { buildServiceManagementDependencies } from "./modules/shop/service-management/service-management.container.js";
// import { serviceManagementRoutes } from "./modules/shop/service-management/service-management.routes.js";
import { shopRoutes } from "./modules/shop/presentation/shop.routes.js";
import { env } from "./shared/config/index.js";
import { buildQueueDependencies } from "./modules/queue/queue.container.js";
import { buildBookingDependencies } from "./modules/booking/booking.container.js";
import { bookingRoutes } from "./modules/booking/presentation/booking.routes.js";
// import { queueRoutes } from "./modules/queue/presentation/queue.routes.js";
// import { buildNotificationDependencies } from "./modules/notification/notification.container.js";
// import { notificationRoutes } from "./modules/notification/presentation/notification.routes.js";
import type { SocketEventPublisher } from "./shared/socket/socket.publisher.js";
import { errorHandler } from "./shared/errors/error-handler.js";
import { prismaPlugin } from "./shared/prisma/prisma.plugin.js";
import { redisPlugin } from "./shared/redis/redis.plugin.js";
import { registerRoutes, type RouteDefinition } from "./shared/app/route-registry.js";

export async function buildApp(): Promise<FastifyInstance> {
  const app = Fastify({
    logger: { level: env.LOG_LEVEL },
    trustProxy: true,
    disableRequestLogging: true
  });

  const authDeps = buildAuthDependencies(app);
  const shopDeps = buildShopDependencies();
  // const serviceDeps = buildServiceManagementDependencies();
  const queueDeps = buildQueueDependencies(app);
  const bookingDeps = buildBookingDependencies(queueDeps.engine);
  // const notificationDeps = buildNotificationDependencies(app);

  app.decorate("authDeps", authDeps);
  app.decorate("shopDeps", shopDeps);
  // app.decorate("serviceDeps", serviceDeps);
  app.decorate("queueDeps", queueDeps);
  app.decorate("bookingDeps", bookingDeps);
  // app.decorate("notificationDeps", notificationDeps);

  await app.register(prismaPlugin);
  await app.register(redisPlugin);
  await app.register(sensible);
  await app.register(helmet);
  await app.register(cors, {
    origin: env.CORS_ORIGIN.split(",").map((value) => value.trim()),
    credentials: true
  });
  await app.register(cookie, {
    secret: env.JWT_ACCESS_SECRET,
    hook: "onRequest",
    parseOptions: {
      sameSite: env.COOKIE_SAME_SITE,
      secure: env.COOKIE_SECURE
    }
  });
  await app.register(rateLimit, {
    max: env.RATE_LIMIT_MAX_REQUESTS,
    timeWindow: `${env.RATE_LIMIT_WINDOW_MS}ms`
  });
  await app.register(jwt, {
    secret: env.JWT_ACCESS_SECRET,
    cookie: {
      cookieName: env.ACCESS_TOKEN_COOKIE_NAME,
      signed: env.COOKIE_SECURE
    },
    sign: {
      expiresIn: env.JWT_ACCESS_TTL
    }
  });
  await app.register(authPlugin);

  app.setErrorHandler(errorHandler);

  const routes: RouteDefinition[] = [
    { plugin: authRoutes, prefix: "/auth" },
    { plugin: shopRoutes, prefix: "/shops" },
    // { plugin: serviceManagementRoutes }, // Disabled - shopService model does not exist in Prisma schema
    { plugin: bookingRoutes, prefix: "/bookings" }
  ];

  await registerRoutes(app, routes);

  return app;
}

declare module "fastify" {
  interface FastifyInstance {
    authDeps: ReturnType<typeof buildAuthDependencies>;
    shopDeps: ReturnType<typeof buildShopDependencies>;
    // serviceDeps: ReturnType<typeof buildServiceManagementDependencies>;
    bookingDeps: ReturnType<typeof buildBookingDependencies>;
    queueDeps: ReturnType<typeof buildQueueDependencies>;
    // notificationDeps: ReturnType<typeof buildNotificationDependencies>;
    prisma: import("@prisma/client").PrismaClient;
    redis: import("ioredis").Redis | null;
    socketPublisher: SocketEventPublisher;
    authenticate: (request: FastifyRequest) => Promise<void>;
    authorizeRoles: (roles: Array<"CLIENT" | "BARBER" | "ADMIN">) => (request: FastifyRequest) => Promise<void>;
    io: import("socket.io").Server | null;
  }
}
