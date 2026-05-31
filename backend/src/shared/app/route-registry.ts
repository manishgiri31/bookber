import type { FastifyInstance, FastifyPluginAsync, FastifyPluginCallback } from "fastify";

export type RouteDefinition = {
    plugin: FastifyPluginAsync | FastifyPluginCallback;
    prefix?: string;
};

export async function registerRoutes(app: FastifyInstance, routes: RouteDefinition[]): Promise<void> {
    for (const route of routes) {
        await app.register(route.plugin as FastifyPluginAsync, route.prefix ? { prefix: route.prefix } : {});
    }
}
