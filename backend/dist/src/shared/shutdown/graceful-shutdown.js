import { logger } from "../logging/logger.js";
import { env } from "../config/env.js";
export class GracefulShutdown {
    shutdownHandlers = [];
    isShuttingDown = false;
    register(handler) {
        this.shutdownHandlers.push(handler);
    }
    async shutdown(signal) {
        if (this.isShuttingDown) {
            logger.warn("Shutdown already in progress");
            return;
        }
        this.isShuttingDown = true;
        logger.info(`Received ${signal}, starting graceful shutdown...`);
        const timeout = env.SHUTDOWN_TIMEOUT_MS;
        const startTime = Date.now();
        try {
            // Execute all shutdown handlers in parallel
            await Promise.allSettled(this.shutdownHandlers.map(handler => Promise.race([
                handler(),
                new Promise((_, reject) => setTimeout(() => reject(new Error("Handler timeout")), timeout))
            ])));
            const duration = Date.now() - startTime;
            logger.info(`Graceful shutdown completed in ${duration}ms`);
            process.exit(0);
        }
        catch (error) {
            logger.error("Error during graceful shutdown", error);
            process.exit(1);
        }
    }
    setupSignalHandlers() {
        const signals = ["SIGTERM", "SIGINT", "SIGUSR2"];
        signals.forEach(signal => {
            process.on(signal, () => {
                this.shutdown(signal);
            });
        });
        // Handle uncaught exceptions
        process.on("uncaughtException", (error) => {
            logger.error("Uncaught exception", error);
            this.shutdown("uncaughtException");
        });
        // Handle unhandled promise rejections
        process.on("unhandledRejection", (reason, promise) => {
            logger.error("Unhandled promise rejection", { reason, promise });
            this.shutdown("unhandledRejection");
        });
    }
}
let shutdownInstance = null;
export function getGracefulShutdown() {
    if (!shutdownInstance) {
        shutdownInstance = new GracefulShutdown();
        shutdownInstance.setupSignalHandlers();
    }
    return shutdownInstance;
}
export async function registerShutdownHandlers(app, prisma, cache) {
    const shutdown = getGracefulShutdown();
    // Close HTTP server
    shutdown.register(async () => {
        logger.info("Closing HTTP server...");
        await new Promise((resolve) => {
            app.close(() => {
                logger.info("HTTP server closed");
                resolve();
            });
        });
    });
    // Disconnect from database
    shutdown.register(async () => {
        logger.info("Disconnecting from database...");
        await prisma.$disconnect();
        logger.info("Database disconnected");
    });
    // Disconnect from cache
    shutdown.register(async () => {
        logger.info("Disconnecting from cache...");
        if (cache) {
            await cache.disconnect();
            logger.info("Cache disconnected");
        }
    });
    // Close WebSocket connections
    shutdown.register(async () => {
        logger.info("Closing WebSocket connections...");
        if (app.io) {
            await new Promise((resolve) => {
                app.io.close(() => {
                    logger.info("WebSocket connections closed");
                    resolve();
                });
            });
        }
    });
    logger.info("Shutdown handlers registered");
}
