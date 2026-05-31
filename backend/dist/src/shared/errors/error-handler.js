import { ZodError } from "zod";
import { HttpError } from "./http-error.js";
export function errorHandler(error, request, reply) {
    request.log.error({ err: error }, "request failed");
    if (error instanceof HttpError) {
        return reply.status(error.statusCode).send({
            error: {
                code: error.code,
                message: error.message,
                details: error.details,
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
    return reply.status(500).send({
        error: {
            code: "INTERNAL_SERVER_ERROR",
            message: "Unexpected error",
            requestId: request.id
        }
    });
}
