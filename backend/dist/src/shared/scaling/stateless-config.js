// Stateless configuration for horizontal scaling
// All state is stored externally (Redis, PostgreSQL, etc.)
import { env } from "../config/env.js";
export const scalingConfig = {
    // Session management - use Redis for session storage
    session: {
        store: "redis",
        ttl: 3600, // 1 hour
        cookie: {
            httpOnly: true,
            secure: env.NODE_ENV === "production",
            sameSite: "strict",
            maxAge: 3600000
        }
    },
    // File uploads - use S3 or similar object storage
    uploads: {
        provider: "s3",
        bucket: env.S3_BUCKET || "bookber-uploads",
        region: env.AWS_REGION || "us-east-1",
        acl: "private"
    },
    // Rate limiting - use Redis for distributed rate limiting
    rateLimit: {
        store: "redis",
        windowMs: env.RATE_LIMIT_WINDOW_MS,
        maxRequests: env.RATE_LIMIT_MAX_REQUESTS
    },
    // Caching - use Redis for distributed caching
    cache: {
        provider: "redis",
        ttl: {
            short: 300, // 5 minutes
            medium: 3600, // 1 hour
            long: 86400 // 24 hours
        }
    },
    // WebSocket - use Redis adapter for scaling
    websocket: {
        adapter: "redis",
        pubSubClient: "redis"
    },
    // Database connection pooling
    database: {
        poolMin: Math.floor(env.DATABASE_POOL_SIZE / 2),
        poolMax: env.DATABASE_POOL_SIZE,
        connectionTimeoutMillis: env.REDIS_CONNECTION_TIMEOUT_MS,
        idleTimeoutMillis: env.REDIS_IDLE_TIMEOUT_MS
    },
    // Health check configuration
    healthCheck: {
        interval: env.REDIS_MEMORY_CHECK_INTERVAL_MS,
        timeout: env.REDIS_CONNECTION_TIMEOUT_MS,
        unhealthyThreshold: 3,
        healthyThreshold: 2
    },
    // Graceful shutdown configuration
    shutdown: {
        timeout: env.SHUTDOWN_TIMEOUT_MS,
        drainTimeout: env.SHUTDOWN_DRAIN_TIMEOUT_MS
    }
};
export function isStateless() {
    return env.NODE_ENV === "production";
}
export function getScalingStrategy() {
    return env.SCALING_STRATEGY;
}
