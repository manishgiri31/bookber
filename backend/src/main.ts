console.log("Starting BookBer...");

// Add error handlers BEFORE any imports to catch silent async failures
process.on('uncaughtException', (error) => {
  console.error('UNCAUGHT EXCEPTION:', error);
  console.error('Stack:', error.stack);
  process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  console.error('UNHANDLED REJECTION:', reason);
  console.error('Stack:', reason instanceof Error ? reason.stack : 'No stack');
  process.exit(1);
});

import { buildApp } from "./app.js";
import { env } from "./shared/config/index.js";
import { bootstrapInfrastructure } from "./infrastructure/bootstrap.js";
import { rootLogger } from "./infrastructure/logging/structured-logger.js";
import { validateEnvOnStartup } from "./shared/config/validation.js";
import { createSocketInfrastructure } from "./shared/socket/socket.js";
import { REALTIME_NAMESPACE } from "./shared/socket/socket.config.js";
import { shutdownServer } from "./shared/utils/graceful-shutdown.js";
import { initializeTracing } from "./infrastructure/tracing/otel.js";

try {
  console.log("Validating environment...");
  validateEnvOnStartup();
  console.log("✓ Environment validated");

  console.log("Initializing tracing...");
  await initializeTracing();
  console.log("✓ Tracing initialized");

  console.log("Building app...");
  const app = await buildApp();
  console.log("✓ App built");

  console.log("Creating socket infrastructure...");
  const socketInfra = createSocketInfrastructure(app);
  console.log("✓ Socket infrastructure created");

  app.decorate("io", socketInfra.io);
  app.decorate("socketPublisher", socketInfra.publisher);

  async function bootstrap(): Promise<void> {
    try {
      console.log("Bootstrapping infrastructure...");
      const infra = await bootstrapInfrastructure(app, socketInfra.io);
      console.log("✓ Infrastructure bootstrapped");

      console.log("Making app ready...");
      await app.ready();
      console.log("✓ App ready");

      const shutdown = async (signal: string): Promise<void> => {
        console.log(`Shutting down due to ${signal}...`);
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
        console.log(`✓ Server listening on ${env.HOST}:${env.PORT}`);
      });
    } catch (error) {
      console.error("Bootstrap error:", error);
      console.error("Stack:", error instanceof Error ? error.stack : "No stack");
      process.exit(1);
    }
  }

  await bootstrap();
} catch (error) {
  console.error("Startup error:", error);
  console.error("Stack:", error instanceof Error ? error.stack : "No stack");
  process.exit(1);
}
