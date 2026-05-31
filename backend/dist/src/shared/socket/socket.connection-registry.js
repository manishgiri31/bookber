const sessionKey = (socketId) => `socket:session:${socketId}`;
const userSocketsKey = (userId) => `socket:user:${userId}`;
export class SocketConnectionRegistry {
    redis;
    constructor(redis) {
        this.redis = redis;
    }
    async register(args) {
        if (!this.redis)
            return;
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
    async touch(socketId) {
        if (!this.redis)
            return;
        await this.redis.hset(sessionKey(socketId), "lastPing", String(Date.now()));
        await this.redis.expire(sessionKey(socketId), 120);
    }
    async unregister(socketId, userId) {
        if (!this.redis)
            return;
        const pipeline = this.redis.pipeline();
        pipeline.del(sessionKey(socketId));
        pipeline.srem(userSocketsKey(userId), socketId);
        await pipeline.exec();
    }
}
/**
 * Disconnects local sockets that missed application heartbeats (per-node sweep).
 */
export function startStaleSocketCleanup(nsp, staleMs, sweepMs, onStale) {
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
