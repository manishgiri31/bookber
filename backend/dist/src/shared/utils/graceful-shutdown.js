import { rootLogger } from "../../infrastructure/logging/structured-logger.js";
export async function shutdownServer(params) {
    const { app, httpServer, io, pubClient, subClient, redisManager, signal, timeoutMs } = params;
    rootLogger.info({ signal, timeoutMs }, "shutdown initiated");
    const closeHttpServer = new Promise((resolve, reject) => {
        httpServer.close((error) => {
            if (error) {
                reject(error);
                return;
            }
            resolve();
        });
    });
    const closeRedis = redisManager
        ? redisManager.shutdown()
        : Promise.all([pubClient, subClient]
            .filter((client) => client !== null)
            .map((client) => client.quit()));
    const closeAll = Promise.all([closeHttpServer, closeRedis, io.close(), app.close()]);
    const timeout = new Promise((_, reject) => {
        setTimeout(() => reject(new Error("shutdown timeout")), timeoutMs);
    });
    try {
        await Promise.race([closeAll, timeout]);
        rootLogger.info({ signal }, "shutdown completed");
    }
    catch (error) {
        rootLogger.error({ err: error, signal }, "shutdown failed");
        throw error;
    }
}
