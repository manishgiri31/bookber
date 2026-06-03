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
import { queueRoutes } from "./modules/queue/presentation/queue.routes.js";
// import { buildNotificationDependencies } from "./modules/notification/notification.container.js";
// import { notificationRoutes } from "./modules/notification/presentation/notification.routes.js";
import { buildPaymentDependencies } from "./modules/payment/payment.container.js";
import { paymentRoutes } from "./modules/payment/presentation/payment.routes.js";
import { buildReviewDependencies } from "./modules/review/review.container.js";
import { reviewRoutes } from "./modules/review/presentation/review.routes.js";
import type { SocketEventPublisher } from "./shared/socket/socket.publisher.js";
import { errorHandler } from "./shared/errors/error-handler.js";
import { prismaPlugin } from "./shared/prisma/prisma.plugin.js";
import { redisPlugin } from "./shared/redis/redis.plugin.js";
import { registerRoutes, type RouteDefinition } from "./shared/app/route-registry.js";

export async function buildApp(): Promise<FastifyInstance> {
  console.log("Creating Fastify instance...");
  const app = Fastify({
    logger: { level: env.LOG_LEVEL },
    trustProxy: true,
    disableRequestLogging: true
  });
  console.log("✓ Fastify instance created");

  console.log("Building dependency containers...");
  const authDeps = buildAuthDependencies(app);
  const shopDeps = buildShopDependencies();
  // const serviceDeps = buildServiceManagementDependencies();
  const queueDeps = buildQueueDependencies(app);
  const bookingDeps = buildBookingDependencies(queueDeps.engine);
  // const notificationDeps = buildNotificationDependencies(app);
  const paymentDeps = buildPaymentDependencies(app);
  const reviewDeps = buildReviewDependencies(app);
  console.log("✓ Dependency containers built");

  app.decorate("authDeps", authDeps);
  app.decorate("shopDeps", shopDeps);
  app.decorate("queueDeps", queueDeps);
  app.decorate("bookingDeps", bookingDeps);
  // app.decorate("notificationDeps", notificationDeps);
  app.decorate("paymentDeps", paymentDeps);
  app.decorate("reviewDeps", reviewDeps);

  console.log("Registering prisma plugin...");
  await app.register(prismaPlugin);
  console.log("✓ Prisma plugin registered");

  console.log("Registering redis plugin...");
  await app.register(redisPlugin);
  console.log("✓ Redis plugin registered");

  console.log("Registering sensible plugin...");
  await app.register(sensible);
  console.log("✓ Sensible plugin registered");

  console.log("Registering helmet plugin...");
  await app.register(helmet);
  console.log("✓ Helmet plugin registered");

  console.log("Registering cors plugin...");
  await app.register(cors, {
    origin: env.CORS_ORIGIN.split(",").map((value) => value.trim()),
    credentials: true
  });
  console.log("✓ CORS plugin registered");

  console.log("Registering cookie plugin...");
  await app.register(cookie, {
    secret: env.JWT_ACCESS_SECRET,
    hook: "onRequest",
    parseOptions: {
      sameSite: env.COOKIE_SAME_SITE,
      secure: env.COOKIE_SECURE
    }
  });
  console.log("✓ Cookie plugin registered");

  console.log("Registering rate-limit plugin...");
  await app.register(rateLimit, {
    max: env.RATE_LIMIT_MAX_REQUESTS,
    timeWindow: `${env.RATE_LIMIT_WINDOW_MS}ms`
  });
  console.log("✓ Rate-limit plugin registered");

  console.log("Registering jwt plugin...");
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
  console.log("✓ JWT plugin registered");

  console.log("Registering auth plugin...");
  await app.register(authPlugin);
  console.log("✓ Auth plugin registered");

  console.log("Setting error handler...");
  app.setErrorHandler(errorHandler);
  console.log("✓ Error handler set");

  console.log("Registering routes...");
  const routes: RouteDefinition[] = [
    { plugin: authRoutes, prefix: "/auth" },
    { plugin: shopRoutes, prefix: "/shops" },
    { plugin: bookingRoutes, prefix: "/bookings" },
    { plugin: queueRoutes, prefix: "" },
    { plugin: paymentRoutes, prefix: "" },
    { plugin: reviewRoutes, prefix: "" }
  ];

  await registerRoutes(app, routes);
  console.log("✓ Routes registered");
  console.log(app.printRoutes());

  console.log("✓ App build complete");
  return app;
}

declare module "fastify" {
  interface FastifyInstance {
    authDeps: ReturnType<typeof buildAuthDependencies>;
    shopDeps: ReturnType<typeof buildShopDependencies>;
    // serviceDeps: ReturnType<typeof buildServiceManagementDependencies>;
    bookingDeps: ReturnType<typeof buildBookingDependencies>;
    // queueDeps: ReturnType<typeof buildQueueDependencies>;
    // notificationDeps: ReturnType<typeof buildNotificationDependencies>;
    paymentDeps: ReturnType<typeof buildPaymentDependencies>;
    reviewDeps: ReturnType<typeof buildReviewDependencies>;
    prisma: import("@prisma/client").PrismaClient;
    redis: import("ioredis").Redis | null;
    socketPublisher: SocketEventPublisher;
    authenticate: (request: FastifyRequest) => Promise<void>;
    authorizeRoles: (roles: Array<"CLIENT" | "BARBER" | "ADMIN">) => (request: FastifyRequest) => Promise<void>;
    io: import("socket.io").Server | null;
  }
}
