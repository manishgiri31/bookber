export class MetricsCollector {
    startTime = Date.now();
    requestCount = 0;
    activeRequests = 0;
    failedRequests = 0;
    incrementRequest() {
        this.requestCount++;
        this.activeRequests++;
    }
    decrementRequest() {
        this.activeRequests--;
    }
    incrementFailedRequest() {
        this.failedRequests++;
    }
    async collectMetrics(prisma, cache) {
        const memoryUsage = process.memoryUsage();
        const cpuUsage = process.cpuUsage();
        let dbConnected = false;
        let dbPool = { total: 0, idle: 0, waiting: 0 };
        let cacheConnected = false;
        let cacheKeys = 0;
        let cacheMemory = 0;
        try {
            await prisma.$connect();
            dbConnected = true;
            dbPool = {
                total: 10,
                idle: 8,
                waiting: 0
            };
        }
        catch (error) {
            dbConnected = false;
        }
        try {
            if (cache) {
                await cache.connect();
                cacheConnected = true;
                cacheKeys = 0;
                cacheMemory = 0;
            }
        }
        catch (error) {
            cacheConnected = false;
        }
        return {
            uptime: Date.now() - this.startTime,
            memory: memoryUsage,
            cpu: cpuUsage,
            requests: {
                total: this.requestCount,
                active: this.activeRequests,
                failed: this.failedRequests
            },
            database: {
                connected: dbConnected,
                pool: dbPool
            },
            cache: {
                connected: cacheConnected,
                keys: cacheKeys,
                memory: cacheMemory
            }
        };
    }
}
let metricsCollector = null;
export function getMetricsCollector() {
    if (!metricsCollector) {
        metricsCollector = new MetricsCollector();
    }
    return metricsCollector;
}
export async function registerMetricsEndpoints(app, prisma, cache) {
    const collector = getMetricsCollector();
    app.get("/metrics", async (request, reply) => {
        const metrics = await collector.collectMetrics(prisma, cache);
        return reply.send(metrics);
    });
    app.get("/metrics/prometheus", async (request, reply) => {
        const metrics = await collector.collectMetrics(prisma, cache);
        const prometheusFormat = `
# HELP bookber_uptime_seconds Uptime of the application in seconds
# TYPE bookber_uptime_seconds gauge
bookber_uptime_seconds ${metrics.uptime / 1000}

# HELP bookber_memory_heap_used_bytes Memory heap used in bytes
# TYPE bookber_memory_heap_used_bytes gauge
bookber_memory_heap_used_bytes ${metrics.memory.heapUsed}

# HELP bookber_memory_heap_total_bytes Memory heap total in bytes
# TYPE bookber_memory_heap_total_bytes gauge
bookber_memory_heap_total_bytes ${metrics.memory.heapTotal}

# HELP bookber_requests_total Total number of requests
# TYPE bookber_requests_total counter
bookber_requests_total ${metrics.requests.total}

# HELP bookber_requests_active Number of active requests
# TYPE bookber_requests_active gauge
bookber_requests_active ${metrics.requests.active}

# HELP bookber_requests_failed Number of failed requests
# TYPE bookber_requests_failed counter
bookber_requests_failed ${metrics.requests.failed}

# HELP bookber_database_connected Database connection status
# TYPE bookber_database_connected gauge
bookber_database_connected ${metrics.database.connected ? 1 : 0}

# HELP bookber_cache_connected Cache connection status
# TYPE bookber_cache_connected gauge
bookber_cache_connected ${metrics.cache.connected ? 1 : 0}
`;
        reply.type("text/plain").send(prometheusFormat.trim());
    });
}
