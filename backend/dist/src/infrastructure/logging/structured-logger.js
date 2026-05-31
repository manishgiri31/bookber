import pino from "pino";
import { env } from "../../shared/config/env.js";
import { getRequestContext } from "./request-context.js";
const isProduction = env.NODE_ENV === "production";
export const rootLogger = pino({
    level: env.LOG_LEVEL,
    base: { service: env.APP_NAME, env: env.NODE_ENV },
    timestamp: pino.stdTimeFunctions.isoTime,
    redact: [
        "req.headers.authorization",
        "req.headers.cookie",
        "password",
        "token",
        "refreshToken",
        "accessToken"
    ],
    serializers: {
        err: pino.stdSerializers.err,
        req: pino.stdSerializers.req,
        res: pino.stdSerializers.res
    },
    ...(isProduction || !env.LOG_PRETTY_PRINT
        ? {}
        : {
            transport: {
                target: "pino-pretty",
                options: {
                    colorize: true,
                    translateTime: "HH:MM:ss Z",
                    ignore: "pid,hostname,service,env"
                }
            }
        }),
    mixin() {
        const ctx = getRequestContext();
        if (!ctx)
            return {};
        return {
            requestId: ctx.requestId,
            correlationId: ctx.correlationId
        };
    }
});
export function createModuleLogger(module) {
    return rootLogger.child({ module });
}
export function logError(logger, message, error, extra) {
    if (error instanceof Error) {
        logger.error({ err: error, ...extra }, message);
        return;
    }
    logger.error({ error, ...extra }, message);
}
