import { buildApp } from "./app.js";
import { env } from "./shared/config/index.js";
import { bootstrapInfrastructure } from "./infrastructure/bootstrap.js";
import { rootLogger } from "./infrastructure/logging/structured-logger.js";
import { validateEnvOnStartup } from "./shared/config/validation.js";
import { createSocketInfrastructure } from "./shared/socket/socket.js";
import { REALTIME_NAMESPACE } from "./shared/socket/socket.config.js";
import { shutdownServer } from "./shared/utils/graceful-shutdown.js";
import { initializeTracing } from "./infrastructure/tracing/otel.js";
validateEnvOnStartup();
await initializeTracing();
const app = await buildApp();
const socketInfra = createSocketInfrastructure(app);
app.decorate("io", socketInfra.io);
app.decorate("socketPublisher", socketInfra.publisher);
async function bootstrap() {
    const infra = await bootstrapInfrastructure(app, socketInfra.io);
    await app.ready();
    const shutdown = async (signal) => {
        infra.stopGaugeCollector();
        infra.stopRecoveryWorkers();
        socketInfra.stop();
        await shutdownServer({
            app,
            httpServer: socketInfra.httpServer,
            io: socketInfra.io,
            pubClient: socketInfra.pubClient,
            subClient: socketInfra.subClient,
            redisManager: infra.redisManager,
            signal,
            timeoutMs: env.SHUTDOWN_TIMEOUT_MS
        });
        process.exit(0);
    };
    process.on("SIGTERM", () => void shutdown("SIGTERM"));
    process.on("SIGINT", () => void shutdown("SIGINT"));
    process.on("uncaughtException", async (error) => {
        rootLogger.fatal({ err: error }, "uncaught exception");
        await shutdown("UNCAUGHT_EXCEPTION");
    });
    process.on("unhandledRejection", async (reason) => {
        rootLogger.fatal({ err: reason }, "unhandled rejection");
        await shutdown("UNHANDLED_REJECTION");
    });
    socketInfra.httpServer.listen(env.PORT, env.HOST, () => {
        rootLogger.info({
            host: env.HOST,
            port: env.PORT,
            namespace: REALTIME_NAMESPACE,
            redisAdapter: socketInfra.adapterEnabled
        }, "BookBer backend started");
    });
}
await bootstrap();
