import { buildApp } from "./app.js";
import { env } from "./shared/config/index.js";
import { bootstrapInfrastructure } from "./infrastructure/bootstrap.js";
import { rootLogger } from "./infrastructure/logging/structured-logger.js";
import { validateEnvOnStartup } from "./shared/config/validation.js";
import { createSocketInfrastructure } from "./shared/socket/socket.js";
import { REALTIME_NAMESPACE } from "./shared/socket/socket.config.js";
import { shutdownServer } from "./shared/utils/graceful-shutdown.js";
import { initializeTracing } from "./infrastructure/tracing/otel.js";

async function main() {
  try {
    console.log("Step 1: Validating environment...");
    validateEnvOnStartup();
    console.log("✓ Environment validated");

    console.log("Step 2: Initializing tracing...");
    await initializeTracing();
    console.log("✓ Tracing initialized");

    console.log("Step 3: Building app...");
    const app = await buildApp();
    console.log("✓ App built");

    console.log("Step 4: Creating socket infrastructure...");
    const socketInfra = createSocketInfrastructure(app);
    console.log("✓ Socket infrastructure created");

    app.decorate("io", socketInfra.io);
    app.decorate("socketPublisher", socketInfra.publisher);

    console.log("Step 5: Bootstrapping infrastructure...");
    const infra = await bootstrapInfrastructure(app, socketInfra.io);
    console.log("✓ Infrastructure bootstrapped");

    console.log("Step 6: Making app ready...");
    await app.ready();
    console.log("✓ App ready");

    const shutdown = async (signal: string): Promise<void> => {
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
      rootLogger.info(
        {
          host: env.HOST,
          port: env.PORT,
          namespace: REALTIME_NAMESPACE,
          redisAdapter: socketInfra.adapterEnabled
        },
        "BookBer backend started"
      );
    });
  } catch (error) {
    console.error("ERROR:", error);
    console.error("Stack:", error instanceof Error ? error.stack : "No stack");
    process.exit(1);
  }
}

main().catch((error) => {
  console.error("UNHANDLED ERROR:", error);
  console.error("Stack:", error instanceof Error ? error.stack : "No stack");
  process.exit(1);
});
