const DEFAULT_HEALTH_CHECK_CONFIG = {
    enableHealthCheck: true,
    enableMetrics: true,
    healthCheckPath: "/health",
    metricsPath: "/metrics",
    redisCheckEnabled: true,
    postgresCheckEnabled: true,
    queueCheckEnabled: true,
    socketCheckEnabled: true
};
/**
 * Health check service
 */
export class HealthCheckService {
    config;
    redis;
    prisma;
    constructor(redis, prisma, config = {}) {
        this.redis = redis;
        this.prisma = prisma;
        this.config = { ...DEFAULT_HEALTH_CHECK_CONFIG, ...config };
    }
    /**
     * Run basic health check
     */
    async basicHealthCheck() {
        return {
            status: "healthy",
            timestamp: new Date().toISOString()
        };
    }
    /**
     * Run liveness check
     */
    async livenessCheck() {
        // Quick check without external dependencies
        return {
            status: "healthy",
            timestamp: new Date().toISOString()
        };
    }
    /**
     * Run readiness check
     */
    async readinessCheck() {
        const checks = {};
        let overallStatus = "healthy";
        // Check Redis
        if (this.config.redisCheckEnabled) {
            const redisCheck = await this.checkRedis();
            checks["redis"] = redisCheck;
            if (redisCheck.status !== "healthy") {
                overallStatus = "unhealthy";
            }
        }
        // Check PostgreSQL
        if (this.config.postgresCheckEnabled) {
            const postgresCheck = await this.checkPostgres();
            checks["postgres"] = postgresCheck;
            if (postgresCheck.status !== "healthy") {
                overallStatus = "unhealthy";
            }
        }
        return {
            status: overallStatus,
            timestamp: new Date().toISOString(),
            checks
        };
    }
    /**
     * Run detailed health check
     */
    async detailedHealthCheck() {
        const checks = {};
        let overallStatus = "healthy";
        // Check Redis
        if (this.config.redisCheckEnabled) {
            const redisCheck = await this.checkRedis();
            checks["redis"] = redisCheck;
            if (redisCheck.status === "unhealthy") {
                overallStatus = "unhealthy";
            }
            else if (redisCheck.status === "degraded" && overallStatus === "healthy") {
                overallStatus = "degraded";
            }
        }
        // Check PostgreSQL
        if (this.config.postgresCheckEnabled) {
            const postgresCheck = await this.checkPostgres();
            checks["postgres"] = postgresCheck;
            if (postgresCheck.status === "unhealthy") {
                overallStatus = "unhealthy";
            }
            else if (postgresCheck.status === "degraded" && overallStatus === "healthy") {
                overallStatus = "degraded";
            }
        }
        // Check Queue
        if (this.config.queueCheckEnabled) {
            const queueCheck = await this.checkQueue();
            checks["queue"] = queueCheck;
            if (queueCheck.status === "unhealthy") {
                overallStatus = "unhealthy";
            }
            else if (queueCheck.status === "degraded" && overallStatus === "healthy") {
                overallStatus = "degraded";
            }
        }
        // Check Socket
        if (this.config.socketCheckEnabled) {
            const socketCheck = await this.checkSocket();
            checks["socket"] = socketCheck;
            if (socketCheck.status === "unhealthy") {
                overallStatus = "unhealthy";
            }
            else if (socketCheck.status === "degraded" && overallStatus === "healthy") {
                overallStatus = "degraded";
            }
        }
        return {
            status: overallStatus,
            timestamp: new Date().toISOString(),
            checks
        };
    }
    /**
     * Check Redis health
     */
    async checkRedis() {
        if (!this.redis) {
            return {
                status: "unhealthy",
                message: "Redis client not configured"
            };
        }
        const startTime = Date.now();
        try {
            await this.redis.ping();
            const duration = Date.now() - startTime;
            if (duration > 1000) {
                return {
                    status: "degraded",
                    message: "Redis latency is high",
                    duration,
                    details: { latency: duration }
                };
            }
            return {
                status: "healthy",
                duration,
                details: { latency: duration }
            };
        }
        catch (error) {
            return {
                status: "unhealthy",
                message: error instanceof Error ? error.message : String(error),
                duration: Date.now() - startTime
            };
        }
    }
    /**
     * Check PostgreSQL health
     */
    async checkPostgres() {
        if (!this.prisma) {
            return {
                status: "unhealthy",
                message: "PostgreSQL client not configured"
            };
        }
        const startTime = Date.now();
        try {
            await this.prisma.$queryRaw `SELECT 1`;
            const duration = Date.now() - startTime;
            if (duration > 5000) {
                return {
                    status: "degraded",
                    message: "PostgreSQL latency is high",
                    duration,
                    details: { latency: duration }
                };
            }
            return {
                status: "healthy",
                duration,
                details: { latency: duration }
            };
        }
        catch (error) {
            return {
                status: "unhealthy",
                message: error instanceof Error ? error.message : String(error),
                duration: Date.now() - startTime
            };
        }
    }
    /**
     * Check Queue health
     */
    async checkQueue() {
        const startTime = Date.now();
        try {
            // Check if queue operations are working
            if (this.redis) {
                await this.redis.ping();
            }
            const duration = Date.now() - startTime;
            return {
                status: "healthy",
                duration,
                details: { latency: duration }
            };
        }
        catch (error) {
            return {
                status: "unhealthy",
                message: error instanceof Error ? error.message : String(error),
                duration: Date.now() - startTime
            };
        }
    }
    /**
     * Check Socket health
     */
    async checkSocket() {
        const startTime = Date.now();
        try {
            // Check if socket operations are working
            // This is a placeholder - actual implementation would check socket server
            const duration = Date.now() - startTime;
            return {
                status: "healthy",
                duration,
                details: { latency: duration }
            };
        }
        catch (error) {
            return {
                status: "unhealthy",
                message: error instanceof Error ? error.message : String(error),
                duration: Date.now() - startTime
            };
        }
    }
    /**
     * Register health check endpoints with Fastify
     */
    registerEndpoints(fastify) {
        if (!this.config.enableHealthCheck) {
            return;
        }
        // Basic health check
        fastify.get(this.config.healthCheckPath, async (request, reply) => {
            const result = await this.basicHealthCheck();
            reply.code(200).send(result);
        });
        // Liveness check
        fastify.get("/health/live", async (request, reply) => {
            const result = await this.livenessCheck();
            reply.code(200).send(result);
        });
        // Readiness check
        fastify.get("/health/ready", async (request, reply) => {
            const result = await this.readinessCheck();
            const statusCode = result.status === "healthy" ? 200 : 503;
            reply.code(statusCode).send(result);
        });
        // Detailed health check
        fastify.get("/health/detailed", async (request, reply) => {
            const result = await this.detailedHealthCheck();
            const statusCode = result.status === "healthy" ? 200 : result.status === "degraded" ? 200 : 503;
            reply.code(statusCode).send(result);
        });
    }
    /**
     * Get current configuration
     */
    getConfig() {
        return { ...this.config };
    }
    /**
     * Update configuration
     */
    updateConfig(config) {
        this.config = { ...this.config, ...config };
    }
}
/**
 * Create a health check service instance
 */
export function createHealthCheckService(redis, prisma, config) {
    return new HealthCheckService(redis, prisma, config);
}
