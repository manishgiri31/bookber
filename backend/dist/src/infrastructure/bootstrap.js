import { env } from "../shared/config/env.js";
import { registerHealthRoutes } from "./health/health.routes.js";
import { registerRequestLogging } from "./logging/request-logging.plugin.js";
import { rootLogger } from "./logging/structured-logger.js";
import { registerMetricsRoutes, startGaugeCollector } from "./metrics/metrics.routes.js";
import { getRedisManager } from "./redis/redis-manager.js";
import { startRecoveryWorkers } from "./workers/recovery-bootstrap.js";
export async function bootstrapInfrastructure(app, io) {
    await registerRequestLogging(app);
    registerMetricsRoutes(app);
    const redisManager = getRedisManager();
    await redisManager.connect();
    redisManager.startHealthChecks();
    registerHealthRoutes(app, {
        prisma: app.prisma,
        redisManager,
        io
    });
    const stopGaugeCollector = env.PROMETHEUS_ENABLED
        ? startGaugeCollector(app.prisma, io)
        : () => undefined;
    const stopRecoveryWorkers = startRecoveryWorkers(app, redisManager.client);
    rootLogger.info({
        prometheus: env.PROMETHEUS_ENABLED,
        otel: env.OTEL_ENABLED,
        redis: redisManager.client !== null
    }, "infrastructure initialized");
    return { stopGaugeCollector, stopRecoveryWorkers, redisManager };
}
