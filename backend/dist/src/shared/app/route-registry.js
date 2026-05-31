export async function registerRoutes(app, routes) {
    for (const route of routes) {
        await app.register(route.plugin, route.prefix ? { prefix: route.prefix } : {});
    }
}
