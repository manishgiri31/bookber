import type { FastifyRequest, FastifyReply } from "fastify";

interface RateLimitStore {
  [key: string]: {
    count: number;
    resetTime: number;
  };
}

export class RateLimiter {
  private store: RateLimitStore = {};
  private cleanupInterval: NodeJS.Timeout;

  constructor(
    private windowMs: number = 60000, // 1 minute
    private maxRequests: number = 100,
    private cleanupMs: number = 60000 // cleanup every minute
  ) {
    this.cleanupInterval = setInterval(() => this.cleanup(), cleanupMs);
  }

  middleware() {
    return async (request: FastifyRequest, reply: FastifyReply) => {
      const key = this.getKey(request);
      const now = Date.now();
      const record = this.store[key];

      if (!record || now > record.resetTime) {
        this.store[key] = {
          count: 1,
          resetTime: now + this.windowMs
        };
        return;
      }

      if (record.count >= this.maxRequests) {
        reply.header("X-RateLimit-Limit", this.maxRequests);
        reply.header("X-RateLimit-Remaining", 0);
        reply.header("X-RateLimit-Reset", new Date(record.resetTime).toISOString());
        return reply.status(429).send({
          error: "Too Many Requests",
          message: `Rate limit exceeded. Try again in ${Math.ceil((record.resetTime - now) / 1000)} seconds.`
        });
      }

      record.count++;
      reply.header("X-RateLimit-Limit", this.maxRequests);
      reply.header("X-RateLimit-Remaining", this.maxRequests - record.count);
      reply.header("X-RateLimit-Reset", new Date(record.resetTime).toISOString());
    };
  }

  private getKey(request: FastifyRequest): string {
    const ip = request.headers["x-forwarded-for"] as string || request.ip;
    const userId = (request.user as any)?.id;
    return userId ? `user:${userId}` : `ip:${ip}`;
  }

  private cleanup() {
    const now = Date.now();
    for (const key in this.store) {
      const record = this.store[key];
      if (record && record.resetTime < now) {
        delete this.store[key];
      }
    }
  }

  destroy() {
    clearInterval(this.cleanupInterval);
  }
}

// Redis-based rate limiter for distributed systems
export class RedisRateLimiter {
  constructor(
    private redis: any,
    private windowMs: number = 60000,
    private maxRequests: number = 100
  ) { }

  middleware() {
    return async (request: FastifyRequest, reply: FastifyReply) => {
      const key = this.getKey(request);
      const now = Date.now();
      const windowStart = now - this.windowMs;

      // Remove old entries
      await this.redis.zremrangebyscore(key, 0, windowStart);

      // Count current requests
      const count = await this.redis.zcard(key);

      if (count >= this.maxRequests) {
        const ttl = await this.redis.pttl(key);
        reply.header("X-RateLimit-Limit", this.maxRequests);
        reply.header("X-RateLimit-Remaining", 0);
        reply.header("X-RateLimit-Reset", new Date(now + ttl).toISOString());
        return reply.status(429).send({
          error: "Too Many Requests",
          message: `Rate limit exceeded. Try again in ${Math.ceil(ttl / 1000)} seconds.`
        });
      }

      // Add current request
      await this.redis.zadd(key, now, `${now}-${Math.random()}`);
      await this.redis.expire(key, Math.ceil(this.windowMs / 1000));

      reply.header("X-RateLimit-Limit", this.maxRequests);
      reply.header("X-RateLimit-Remaining", this.maxRequests - count - 1);
      reply.header("X-RateLimit-Reset", new Date(now + this.windowMs).toISOString());
    };
  }

  private getKey(request: FastifyRequest): string {
    const ip = request.headers["x-forwarded-for"] as string || request.ip;
    const userId = (request.user as any)?.id;
    return userId ? `ratelimit:user:${userId}` : `ratelimit:ip:${ip}`;
  }
}
