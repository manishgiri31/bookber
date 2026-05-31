import type { FastifyInstance, FastifyReply, FastifyRequest } from "fastify";
import type { PrismaClient } from "@prisma/client";
import type { Server as SocketServer } from "socket.io";
import { getMetrics, observeHttpRequest } from "./prometheus.js";

export function registerMetricsRoutes(app: FastifyInstance): void {
  const metrics = getMetrics();

  app.addHook("onRequest", async (request: FastifyRequest) => {
    (request as FastifyRequest & { metricsStart?: bigint }).metricsStart = process.hrtime.bigint();
  });

  app.addHook("onResponse", async (request: FastifyRequest, reply: FastifyReply) => {
    const start = (request as FastifyRequest & { metricsStart?: bigint }).metricsStart;
    if (start === undefined) return;
    const durationSeconds = Number(process.hrtime.bigint() - start) / 1e9;
    const route = request.routeOptions?.url ?? request.url.split("?")[0] ?? "unknown";
    observeHttpRequest(request.method, route, reply.statusCode, durationSeconds);
  });

  app.get("/metrics", async (_request: FastifyRequest, reply: FastifyReply) => {
    reply.header("Content-Type", metrics.registry.contentType);
    return reply.send(await metrics.metricsText());
  });
}

export async function refreshOperationalGauges(
  prisma: PrismaClient,
  io: SocketServer | null
): Promise<void> {
  const metrics = getMetrics();
  const activeStatuses = ["QUEUED", "READY", "CALLED", "IN_SERVICE"] as const;
  const queueStatuses = ["WAITING", "READY", "CALLED", "IN_SERVICE"] as const;

  const [queueCounts, bookingCounts, chairCounts] = await Promise.all([
    prisma.queueEntry.groupBy({
      by: ["shopId", "lane"],
      where: { queueStatus: { in: [...queueStatuses] } },
      _count: { _all: true }
    }),
    prisma.booking.groupBy({
      by: ["shopId"],
      where: { status: { in: [...activeStatuses] } },
      _count: { _all: true }
    }),
    prisma.chair.groupBy({
      by: ["shopId", "status"],
      _count: { _all: true }
    })
  ]);

  metrics.activeQueueSize.reset();
  for (const row of queueCounts) {
    metrics.activeQueueSize.set(
      { shop_id: row.shopId, lane: row.lane },
      row._count._all
    );
  }

  metrics.activeBookings.reset();
  for (const row of bookingCounts) {
    metrics.activeBookings.set({ shop_id: row.shopId }, row._count._all);
  }

  metrics.activeChairs.reset();
  for (const row of chairCounts) {
    metrics.activeChairs.set({ shop_id: row.shopId, status: row.status }, row._count._all);
  }

  metrics.socketConnections.reset();
  if (io) {
    metrics.socketConnections.set({ namespace: "all" }, io.engine.clientsCount);
  }
}

export function startGaugeCollector(
  prisma: PrismaClient,
  io: SocketServer | null,
  intervalMs = 30_000
): () => void {
  const tick = () => {
    void refreshOperationalGauges(prisma, io).catch(() => undefined);
  };
  tick();
  const timer = setInterval(tick, intervalMs);
  return () => clearInterval(timer);
}
