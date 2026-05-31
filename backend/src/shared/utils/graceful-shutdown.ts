import type { FastifyInstance } from "fastify";
import type { Server } from "node:http";
import type { Server as SocketServer } from "socket.io";
import type { Redis } from "ioredis";
import { rootLogger } from "../../infrastructure/logging/structured-logger.js";
import type { RedisManager } from "../../infrastructure/redis/redis-manager.js";

export async function shutdownServer(params: {
  app: FastifyInstance;
  httpServer: Server;
  io: SocketServer;
  pubClient: Redis | null;
  subClient: Redis | null;
  redisManager?: RedisManager;
  signal: string;
  timeoutMs: number;
}): Promise<void> {
  const { app, httpServer, io, pubClient, subClient, redisManager, signal, timeoutMs } = params;

  rootLogger.info({ signal, timeoutMs }, "shutdown initiated");

  const closeHttpServer = new Promise<void>((resolve, reject) => {
    httpServer.close((error) => {
      if (error) {
        reject(error);
        return;
      }
      resolve();
    });
  });

  const closeRedis = redisManager
    ? redisManager.shutdown()
    : Promise.all(
        [pubClient, subClient]
          .filter((client): client is Redis => client !== null)
          .map((client) => client.quit())
      );

  const closeAll = Promise.all([closeHttpServer, closeRedis, io.close(), app.close()]);
  const timeout = new Promise<never>((_, reject) => {
    setTimeout(() => reject(new Error("shutdown timeout")), timeoutMs);
  });

  try {
    await Promise.race([closeAll, timeout]);
    rootLogger.info({ signal }, "shutdown completed");
  } catch (error) {
    rootLogger.error({ err: error, signal }, "shutdown failed");
    throw error;
  }
}
