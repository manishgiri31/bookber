import type { FastifyInstance, FastifyReply, FastifyRequest } from "fastify";
import type { PrismaClient } from "@prisma/client";
import type { Server as SocketServer } from "socket.io";
import { env } from "../../shared/config/env.js";
import type { RedisManager } from "../redis/redis-manager.js";
import { getMetrics } from "../metrics/prometheus.js";

export type HealthStatus = "healthy" | "unhealthy" | "degraded";

export type DependencyCheck = {
  status: HealthStatus;
  message?: string;
  durationMs?: number;
};

export function registerHealthRoutes(
  app: FastifyInstance,
  deps: {
    prisma: PrismaClient;
    redisManager: RedisManager;
    io: SocketServer | null;
  }
): void {
  app.get("/health", async () => ({
    ok: true,
    service: env.APP_NAME,
    env: env.NODE_ENV,
    timestamp: new Date().toISOString()
  }));

  app.get("/health/live", async (_req: FastifyRequest, reply: FastifyReply) => {
    return reply.send({
      status: "healthy",
      timestamp: new Date().toISOString()
    });
  });

  app.get("/health/ready", async (_req: FastifyRequest, reply: FastifyReply) => {
    const checks: Record<string, DependencyCheck> = {};
    let overall: HealthStatus = "healthy";

    checks["postgres"] = await checkPostgres(deps.prisma);
    checks["redis"] = await checkRedis(deps.redisManager);

    for (const check of Object.values(checks)) {
      if (check.status === "unhealthy") overall = "unhealthy";
      else if (check.status === "degraded" && overall === "healthy") overall = "degraded";
    }

    const code = overall === "healthy" ? 200 : 503;
    return reply.code(code).send({
      status: overall,
      timestamp: new Date().toISOString(),
      checks
    });
  });
}

async function checkPostgres(prisma: PrismaClient): Promise<DependencyCheck> {
  const start = Date.now();
  try {
    await prisma.$queryRaw`SELECT 1`;
    const durationMs = Date.now() - start;
    getMetrics().databaseQueryDuration.observe({ model: "health", operation: "ping" }, durationMs / 1000);
    return durationMs > 500
      ? { status: "degraded", durationMs, message: "high latency" }
      : { status: "healthy", durationMs };
  } catch (error: unknown) {
    return {
      status: "unhealthy",
      durationMs: Date.now() - start,
      message: error instanceof Error ? error.message : String(error)
    };
  }
}

async function checkRedis(redisManager: RedisManager): Promise<DependencyCheck> {
  const health = await redisManager.healthCheck();
  if (!health.connected) {
    return { status: "unhealthy", message: health.error ?? "disconnected", durationMs: health.latencyMs };
  }
  return health.latencyMs > 250
    ? { status: "degraded", durationMs: health.latencyMs, message: "high latency" }
    : { status: "healthy", durationMs: health.latencyMs };
}
