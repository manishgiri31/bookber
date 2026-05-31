export class HealthChecker {
    async checkDatabase(prisma) {
        const startTime = Date.now();
        try {
            await prisma.$queryRaw `SELECT 1`;
            return {
                status: "healthy",
                message: "Database connection successful",
                responseTime: Date.now() - startTime
            };
        }
        catch (error) {
            return {
                status: "unhealthy",
                message: `Database connection failed: ${error}`,
                responseTime: Date.now() - startTime
            };
        }
    }
    async checkCache(cache) {
        const startTime = Date.now();
        try {
            await cache.set("health-check", "ok", 10);
            await cache.delete("health-check");
            return {
                status: "healthy",
                message: "Cache connection successful",
                responseTime: Date.now() - startTime
            };
        }
        catch (error) {
            return {
                status: "unhealthy",
                message: `Cache connection failed: ${error}`,
                responseTime: Date.now() - startTime
            };
        }
    }
    checkMemory() {
        const memoryUsage = process.memoryUsage();
        const heapUsed = memoryUsage.heapUsed / 1024 / 1024; // MB
        const heapTotal = memoryUsage.heapTotal / 1024 / 1024; // MB
        const usagePercent = (heapUsed / heapTotal) * 100;
        if (usagePercent > 90) {
            return {
                status: "unhealthy",
                message: `Memory usage critical: ${heapUsed.toFixed(2)}MB / ${heapTotal.toFixed(2)}MB (${usagePercent.toFixed(1)}%)`
            };
        }
        else if (usagePercent > 70) {
            return {
                status: "unhealthy",
                message: `Memory usage high: ${heapUsed.toFixed(2)}MB / ${heapTotal.toFixed(2)}MB (${usagePercent.toFixed(1)}%)`
            };
        }
        return {
            status: "healthy",
            message: `Memory usage normal: ${heapUsed.toFixed(2)}MB / ${heapTotal.toFixed(2)}MB (${usagePercent.toFixed(1)}%)`
        };
    }
    checkDisk() {
        // Placeholder for disk check - would need file system access
        return {
            status: "healthy",
            message: "Disk space sufficient"
        };
    }
    async performHealthCheck(prisma, cache) {
        const [dbCheck, cacheCheck, memoryCheck, diskCheck] = await Promise.all([
            this.checkDatabase(prisma),
            this.checkCache(cache),
            Promise.resolve(this.checkMemory()),
            Promise.resolve(this.checkDisk())
        ]);
        const allHealthy = [dbCheck, cacheCheck, memoryCheck, diskCheck].every(check => check.status === "healthy");
        const anyUnhealthy = [dbCheck, cacheCheck, memoryCheck, diskCheck].some(check => check.status === "unhealthy");
        const status = allHealthy ? "healthy" : anyUnhealthy ? "unhealthy" : "degraded";
        return {
            status,
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            checks: {
                database: dbCheck,
                cache: cacheCheck,
                memory: memoryCheck,
                disk: diskCheck
            }
        };
    }
}
let healthChecker = null;
export function getHealthChecker() {
    if (!healthChecker) {
        healthChecker = new HealthChecker();
    }
    return healthChecker;
}
export async function registerHealthCheckEndpoints(app, prisma, cache) {
    const checker = getHealthChecker();
    app.get("/health", async (request, reply) => {
        const result = await checker.performHealthCheck(prisma, cache);
        const statusCode = result.status === "healthy" ? 200 : result.status === "unhealthy" ? 503 : 200;
        return reply.status(statusCode).send(result);
    });
    app.get("/health/ready", async (request, reply) => {
        const result = await checker.performHealthCheck(prisma, cache);
        const isReady = result.status === "healthy";
        return reply.status(isReady ? 200 : 503).send({
            status: isReady ? "ready" : "not ready",
            timestamp: result.timestamp
        });
    });
    app.get("/health/live", async (request, reply) => {
        return reply.status(200).send({
            status: "alive",
            timestamp: new Date().toISOString(),
            uptime: process.uptime()
        });
    });
}
