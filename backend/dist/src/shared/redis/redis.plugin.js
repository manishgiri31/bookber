import fp from "fastify-plugin";
import { getRedisManager } from "../../infrastructure/redis/redis-manager.js";
const redisPluginImpl = async (app) => {
    const redisManager = getRedisManager();
    await redisManager.connect();
    app.decorate("redis", redisManager.client);
    app.decorate("redisManager", redisManager);
    app.addHook("onClose", async () => {
        await redisManager.shutdown();
    });
};
export const redisPlugin = fp(redisPluginImpl, {
    name: "redis-plugin"
});
