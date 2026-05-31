import type { Redis as RedisClient } from "ioredis";
import type { Namespace } from "socket.io";

const sessionKey = (socketId: string) => `socket:session:${socketId}`;
const userSocketsKey = (userId: string) => `socket:user:${userId}`;

export class SocketConnectionRegistry {
  constructor(private readonly redis: RedisClient | null) {}

  async register(args: {
    socketId: string;
    userId: string;
    namespace: string;
    nodeId: string;
  }): Promise<void> {
    if (!this.redis) return;
    const pipeline = this.redis.pipeline();
    pipeline.sadd(userSocketsKey(args.userId), args.socketId);
    pipeline.hset(sessionKey(args.socketId), {
      userId: args.userId,
      namespace: args.namespace,
      nodeId: args.nodeId,
      connectedAt: String(Date.now()),
      lastPing: String(Date.now())
    });
    pipeline.expire(sessionKey(args.socketId), 120);
    await pipeline.exec();
  }

  async touch(socketId: string): Promise<void> {
    if (!this.redis) return;
    await this.redis.hset(sessionKey(socketId), "lastPing", String(Date.now()));
    await this.redis.expire(sessionKey(socketId), 120);
  }

  async unregister(socketId: string, userId: string): Promise<void> {
    if (!this.redis) return;
    const pipeline = this.redis.pipeline();
    pipeline.del(sessionKey(socketId));
    pipeline.srem(userSocketsKey(userId), socketId);
    await pipeline.exec();
  }
}

/**
 * Disconnects local sockets that missed application heartbeats (per-node sweep).
 */
export function startStaleSocketCleanup(
  nsp: Namespace,
  staleMs: number,
  sweepMs: number,
  onStale?: (socketId: string) => void
): () => void {
  const timer = setInterval(() => {
    const now = Date.now();
    for (const socket of nsp.sockets.values()) {
      const lastPing = socket.data.lastPing ?? Date.now();
      if (now - lastPing > staleMs) {
        onStale?.(socket.id);
        socket.emit("connection.state", { connected: false, reason: "stale" });
        socket.disconnect(true);
      }
    }
  }, sweepMs);

  return () => clearInterval(timer);
}
