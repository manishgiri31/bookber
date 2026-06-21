import type { FastifyError, FastifyReply, FastifyRequest } from "fastify";
import { ZodError } from "zod";
import { HttpError } from "./http-error.js";

export function errorHandler(error: FastifyError, request: FastifyRequest, reply: FastifyReply) {
  request.log.error({ err: error }, "request failed");

  if (error instanceof HttpError) {
    return reply.status(error.statusCode).send({
      error: {
        code: error.code,
        message: error.message,
        details: (error as any).details,
        requestId: request.id
      }
    });
  }

  if (error instanceof ZodError) {
    return reply.status(400).send({
      error: {
        code: "VALIDATION_ERROR",
        message: "Invalid request payload",
        details: error.flatten(),
        requestId: request.id
      }
    });
  }

  // Handle FastifyError from @fastify/sensible (app.httpErrors.*)
  const statusCode = (error as any).statusCode as number | undefined;
  if (statusCode && statusCode >= 400 && statusCode < 600) {
    const expose = (error as any).expose !== false;
    return reply.status(statusCode).send({
      error: {
        code: error.code ?? "HTTP_ERROR",
        message: expose ? error.message : "An error occurred",
        requestId: request.id
      }
    });
  }

  return reply.status(500).send({
    error: {
      code: "INTERNAL_SERVER_ERROR",
      message: "Unexpected error",
      requestId: request.id
    }
  });
}
