import type { FastifyPluginAsync } from "fastify";
import fp from "fastify-plugin";

import { getRedisManager } from "../../infrastructure/redis/redis-manager.js";

const redisPluginImpl: FastifyPluginAsync = async (app) => {
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

declare module "fastify" {
  interface FastifyInstance {
    redisManager: ReturnType<typeof getRedisManager>;
  }
}
