import type { FastifyInstance } from "fastify";
import type { Server as SocketServer } from "socket.io";
import { env } from "../shared/config/env.js";
import { registerHealthRoutes } from "./health/health.routes.js";
import { registerRequestLogging } from "./logging/request-logging.plugin.js";
import { rootLogger } from "./logging/structured-logger.js";
import { registerMetricsRoutes, startGaugeCollector } from "./metrics/metrics.routes.js";
import { getRedisManager } from "./redis/redis-manager.js";
import { startRecoveryWorkers } from "./workers/recovery-bootstrap.js";
import { ScheduledBookingPromoterWorker } from "./workers/scheduled-booking-promoter.worker.js";

export type InfrastructureHandles = {
  stopGaugeCollector: () => void;
  stopRecoveryWorkers: () => void;
  stopScheduledPromoter: () => void;
  redisManager: ReturnType<typeof getRedisManager>;
};

export async function bootstrapInfrastructure(
  app: FastifyInstance,
  io: SocketServer | null
): Promise<InfrastructureHandles> {
  try {
    console.log("Registering request logging...");
    await registerRequestLogging(app);
    console.log("✓ Request logging registered");

    console.log("Registering metrics routes...");
    registerMetricsRoutes(app);
    console.log("✓ Metrics routes registered");

    console.log("Getting Redis manager...");
    const redisManager = getRedisManager();
    console.log("✓ Redis manager obtained");

    console.log("Connecting to Redis...");
    await redisManager.connect();
    console.log("✓ Redis connected");

    console.log("Starting Redis health checks...");
    redisManager.startHealthChecks();
    console.log("✓ Redis health checks started");

    console.log("Registering health routes...");
    registerHealthRoutes(app, {
      prisma: app.prisma,
      redisManager,
      io
    });
    console.log("✓ Health routes registered");

    console.log("Starting gauge collector...");
    const stopGaugeCollector = env.PROMETHEUS_ENABLED
      ? startGaugeCollector(app.prisma, io)
      : () => undefined;
    console.log("✓ Gauge collector started");

    console.log("Starting recovery workers...");
    const stopRecoveryWorkers = startRecoveryWorkers(app, redisManager.client);
    console.log("✓ Recovery workers started");

    console.log("Starting scheduled booking promoter...");
    const promoter = new ScheduledBookingPromoterWorker(app.notificationDeps.service);
    const stopScheduledPromoter = promoter.start();
    console.log("✓ Scheduled booking promoter started");

    rootLogger.info(
      {
        prometheus: env.PROMETHEUS_ENABLED,
        otel: env.OTEL_ENABLED,
        redis: redisManager.client !== null
      },
      "infrastructure initialized"
    );

    console.log("✓ Infrastructure bootstrap complete");
    return { stopGaugeCollector, stopRecoveryWorkers, stopScheduledPromoter, redisManager };
  } catch (error) {
    console.error("Bootstrap infrastructure error:", error);
    console.error("Stack:", error instanceof Error ? error.stack : "No stack");
    throw error;
  }
}
