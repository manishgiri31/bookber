import type { FastifyPluginAsync } from "fastify";

export const socketPlugin: FastifyPluginAsync = async (app) => {
  app.decorate("io", null);
};
