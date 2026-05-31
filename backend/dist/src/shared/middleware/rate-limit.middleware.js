export class RateLimiter {
    windowMs;
    maxRequests;
    cleanupMs;
    store = {};
    cleanupInterval;
    constructor(windowMs = 60000, // 1 minute
    maxRequests = 100, cleanupMs = 60000 // cleanup every minute
    ) {
        this.windowMs = windowMs;
        this.maxRequests = maxRequests;
        this.cleanupMs = cleanupMs;
        this.cleanupInterval = setInterval(() => this.cleanup(), cleanupMs);
    }
    middleware() {
        return async (request, reply) => {
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
    getKey(request) {
        const ip = request.headers["x-forwarded-for"] || request.ip;
        const userId = request.user?.id;
        return userId ? `user:${userId}` : `ip:${ip}`;
    }
    cleanup() {
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
    redis;
    windowMs;
    maxRequests;
    constructor(redis, windowMs = 60000, maxRequests = 100) {
        this.redis = redis;
        this.windowMs = windowMs;
        this.maxRequests = maxRequests;
    }
    middleware() {
        return async (request, reply) => {
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
    getKey(request) {
        const ip = request.headers["x-forwarded-for"] || request.ip;
        const userId = request.user?.id;
        return userId ? `ratelimit:user:${userId}` : `ratelimit:ip:${ip}`;
    }
}
