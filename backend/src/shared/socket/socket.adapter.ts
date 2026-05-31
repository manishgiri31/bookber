import { createAdapter } from "@socket.io/redis-adapter";
import type { Redis } from "ioredis";
import type { Server } from "socket.io";

import { logger } from "../logging/logger.js";

/**
 * Redis pub/sub adapter for horizontal scaling across Node processes.
 *
 * Use dedicated duplicate() clients (one publisher, one subscriber).
 */
export function configureRedisAdapter(
  io: Server,
  pubClient: Redis | null,
  subClient: Redis | null
): boolean {
  if (!pubClient || !subClient) {
    logger.warn("Socket.io Redis adapter disabled - REDIS_URL missing or client failed");
    return false;
  }

  pubClient.on("error", (err) => logger.error({ err }, "socket redis pub client error"));
  subClient.on("error", (err) => logger.error({ err }, "socket redis sub client error"));

  io.adapter(createAdapter(pubClient, subClient));
  logger.info("Socket.io Redis adapter enabled");
  return true;
}
