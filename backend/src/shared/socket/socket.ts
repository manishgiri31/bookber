import type { FastifyInstance } from "fastify";
import { Server } from "socket.io";

import { configureRedisAdapter } from "./socket.adapter.js";
import {
  OPS_NAMESPACE,
  REALTIME_NAMESPACE,
  SOCKET_HEARTBEAT_MS,
  SOCKET_STALE_MS,
  SOCKET_STALE_SWEEP_MS
} from "./socket.config.js";
import { SocketConnectionRegistry, startStaleSocketCleanup } from "./socket.connection-registry.js";
import { SocketEventJournal } from "./socket.event-journal.js";
import { attachSocketHandlers } from "./socket.handlers.js";
import { SocketEventPublisher } from "./socket.publisher.js";
import type {
  ClientToServerEvents,
  InterServerEvents,
  ServerToClientEvents,
  SocketData
} from "./socket.types.js";

export function createSocketInfrastructure(app: FastifyInstance) {
  const httpServer = app.server;

  const io = new Server<ClientToServerEvents, ServerToClientEvents, InterServerEvents, SocketData>(
    httpServer,
    {
      cors: {
        origin: true,
        credentials: true
      },
      pingTimeout: 60_000,
      pingInterval: 25_000,
      connectionStateRecovery: {
        maxDisconnectionDuration: 2 * 60_000,
        skipMiddlewares: false
      }
    }
  );

  const pubClient = app.redis?.duplicate() ?? null;
  const subClient = app.redis?.duplicate() ?? null;
  const adapterEnabled = configureRedisAdapter(io, pubClient, subClient);

  const journal = new SocketEventJournal(app.redis);
  const registry = new SocketConnectionRegistry(app.redis);

  const realtimeNsp = io.of(REALTIME_NAMESPACE);
  attachSocketHandlers(app, realtimeNsp, journal, registry);

  const opsNsp = io.of(OPS_NAMESPACE);
  attachSocketHandlers(app, opsNsp, journal, registry);

  const stopStaleRealtime = startStaleSocketCleanup(
    realtimeNsp,
    SOCKET_STALE_MS,
    SOCKET_STALE_SWEEP_MS,
    (socketId) => {
      app.log.warn({ socketId }, "disconnecting stale realtime socket");
    }
  );

  const stopStaleOps = startStaleSocketCleanup(opsNsp, SOCKET_STALE_MS, SOCKET_STALE_SWEEP_MS);

  const heartbeatInterval = setInterval(() => {
    const payload = {
      timestamp: Date.now(),
      serverTime: new Date().toISOString()
    };
    const emitHeartbeat = (namespace: { emit(event: "heartbeat", data: typeof payload): boolean }) => {
      namespace.emit("heartbeat", payload);
    };
    emitHeartbeat(realtimeNsp);
    emitHeartbeat(opsNsp);
  }, SOCKET_HEARTBEAT_MS);

  const publisher = new SocketEventPublisher(io, journal);

  return {
    httpServer,
    io,
    realtimeNsp,
    publisher,
    journal,
    registry,
    pubClient,
    subClient,
    adapterEnabled,
    stop: () => {
      clearInterval(heartbeatInterval);
      stopStaleRealtime();
      stopStaleOps();
    }
  };
}
