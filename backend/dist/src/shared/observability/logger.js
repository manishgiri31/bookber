import pino from "pino";
import pinoHttp from "pino-http";
const DEFAULT_LOGGER_CONFIG = {
    level: process.env["LOG_LEVEL"] || "info",
    prettyPrint: process.env["NODE_ENV"] === "development",
    redact: ["req.headers.authorization", "req.headers.cookie", "req.body.password", "req.body.token"],
    serializers: {
        err: pino.stdSerializers.err,
        req: pino.stdSerializers.req,
        res: pino.stdSerializers.res
    }
};
/**
 * Create a Pino logger instance
 */
export function createLogger(config = {}) {
    const mergedConfig = { ...DEFAULT_LOGGER_CONFIG, ...config };
    const logger = pino({
        level: mergedConfig.level,
        redact: mergedConfig.redact,
        serializers: mergedConfig.serializers,
        ...(mergedConfig.prettyPrint
            ? {
                transport: {
                    target: "pino-pretty",
                    options: {
                        colorize: true,
                        translateTime: "HH:MM:ss Z",
                        ignore: "pid,hostname"
                    }
                }
            }
            : {})
    });
    return logger;
}
/**
 * Create a child logger with additional context
 */
export function createChildLogger(parent, context) {
    return parent.child(context);
}
/**
 * Create HTTP request logging middleware
 */
export function createHttpLogger(logger) {
    const baseLogger = logger || createLogger();
    return pinoHttp({
        logger: baseLogger,
        customLogLevel: (req, res, err) => {
            if (res.statusCode >= 500) {
                return "error";
            }
            else if (res.statusCode >= 400) {
                return "warn";
            }
            else if (res.statusCode >= 300) {
                return "info";
            }
            return "debug";
        },
        customSuccessMessage: (req, res) => {
            return `${req.method} ${req.url} completed with status ${res.statusCode}`;
        },
        customErrorMessage: (req, res, err) => {
            return `${req.method} ${req.url} failed with status ${res.statusCode}: ${err?.message}`;
        }
    });
}
/**
 * Logger utility class for common operations
 */
export class Logger {
    logger;
    constructor(config) {
        this.logger = createLogger(config);
    }
    /**
     * Log a trace message
     */
    trace(message, data) {
        this.logger.trace(data, message);
    }
    /**
     * Log a debug message
     */
    debug(message, data) {
        this.logger.debug(data, message);
    }
    /**
     * Log an info message
     */
    info(message, data) {
        this.logger.info(data, message);
    }
    /**
     * Log a warning message
     */
    warn(message, data) {
        this.logger.warn(data, message);
    }
    /**
     * Log an error message
     */
    error(message, error, data) {
        const errorData = error instanceof Error ? { err: error, ...data } : { error, ...data };
        this.logger.error(errorData, message);
    }
    /**
     * Log a fatal message
     */
    fatal(message, error, data) {
        const errorData = error instanceof Error ? { err: error, ...data } : { error, ...data };
        this.logger.fatal(errorData, message);
    }
    /**
     * Create a child logger with context
     */
    child(context) {
        const childLogger = this.logger.child(context);
        const newLogger = new Logger();
        newLogger.logger = childLogger;
        return newLogger;
    }
    /**
     * Log a queue operation
     */
    queue(operation, shopId, lane, data) {
        this.info(`Queue operation: ${operation}`, {
            operation,
            shopId,
            lane,
            ...data
        });
    }
    /**
     * Log a booking operation
     */
    booking(operation, bookingId, shopId, data) {
        this.info(`Booking operation: ${operation}`, {
            operation,
            bookingId,
            shopId,
            ...data
        });
    }
    /**
     * Log a socket event
     */
    socket(event, socketId, shopId, data) {
        this.info(`Socket event: ${event}`, {
            event,
            socketId,
            shopId,
            ...data
        });
    }
    /**
     * Log a Redis operation
     */
    redis(operation, command, data) {
        this.debug(`Redis operation: ${operation}`, {
            operation,
            command,
            ...data
        });
    }
    /**
     * Log a PostgreSQL operation
     */
    postgres(operation, table, data) {
        this.debug(`PostgreSQL operation: ${operation}`, {
            operation,
            table,
            ...data
        });
    }
    /**
     * Log a wait time calculation
     */
    waitTime(shopId, lane, estimated, actual) {
        this.info("Wait time calculation", {
            shopId,
            lane,
            estimated,
            actual,
            accuracy: actual ? Math.abs(estimated - actual) / actual : undefined
        });
    }
    /**
     * Log a chair operation
     */
    chair(operation, chairId, shopId, data) {
        this.info(`Chair operation: ${operation}`, {
            operation,
            chairId,
            shopId,
            ...data
        });
    }
    /**
     * Get the underlying Pino logger
     */
    getPinoLogger() {
        return this.logger;
    }
}
/**
 * Create a logger instance
 */
export function createAppLogger(config) {
    return new Logger(config);
}
/**
 * Get the default logger instance
 */
let defaultLogger = null;
export function getLogger() {
    if (!defaultLogger) {
        defaultLogger = new Logger();
    }
    return defaultLogger;
}
/**
 * Get the default Pino logger
 */
export function getPinoLogger() {
    return getLogger().getPinoLogger();
}
