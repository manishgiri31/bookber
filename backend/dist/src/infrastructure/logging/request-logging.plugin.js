import { createRequestContext, requestContextStorage } from "./request-context.js";
import { rootLogger } from "./structured-logger.js";
export async function registerRequestLogging(app) {
    app.addHook("onRequest", async (request, reply) => {
        const ctx = createRequestContext(request.headers);
        request.requestId = ctx.requestId;
        request.correlationId = ctx.correlationId;
        reply.header("x-request-id", ctx.requestId);
        reply.header("x-correlation-id", ctx.correlationId);
        requestContextStorage.enterWith(ctx);
    });
    app.addHook("onResponse", async (request, reply) => {
        rootLogger.info({
            method: request.method,
            url: request.url,
            statusCode: reply.statusCode,
            responseTime: reply.elapsedTime
        }, "http request completed");
    });
}
