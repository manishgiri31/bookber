import type { FastifyInstance, FastifyReply, FastifyRequest } from "fastify";
import { createRequestContext, requestContextStorage } from "./request-context.js";
import { rootLogger } from "./structured-logger.js";

export async function registerRequestLogging(app: FastifyInstance): Promise<void> {
  app.addHook("onRequest", async (request: FastifyRequest, reply: FastifyReply) => {
    const ctx = createRequestContext(request.headers as Record<string, string | string[] | undefined>);
    (request as FastifyRequest & { requestId: string; correlationId: string }).requestId = ctx.requestId;
    (request as FastifyRequest & { correlationId: string }).correlationId = ctx.correlationId;
    reply.header("x-request-id", ctx.requestId);
    reply.header("x-correlation-id", ctx.correlationId);
    requestContextStorage.enterWith(ctx);
  });

  app.addHook("onResponse", async (request, reply) => {
    rootLogger.info(
      {
        method: request.method,
        url: request.url,
        statusCode: reply.statusCode,
        responseTime: reply.elapsedTime
      },
      "http request completed"
    );
  });
}

declare module "fastify" {
  interface FastifyRequest {
    requestId?: string;
    correlationId?: string;
  }
}
