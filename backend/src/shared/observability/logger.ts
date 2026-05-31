import pino from "pino";
import pinoHttp from "pino-http";

/**
 * Production-grade structured logging with Pino.
 * 
 * Features:
 * - Structured JSON logging
 * - Multiple log levels
 * - Request logging middleware
 * - Custom serializers for sensitive data
 * - Child loggers with context
 * - Pretty printing for development
 */

export interface LoggerConfig {
  level: "trace" | "debug" | "info" | "warn" | "error" | "fatal";
  prettyPrint: boolean;
  redact: string[];
  serializers: Record<string, (value: any) => any>;
}

const DEFAULT_LOGGER_CONFIG: LoggerConfig = {
  level: process.env["LOG_LEVEL"] as LoggerConfig["level"] || "info",
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
export function createLogger(config: Partial<LoggerConfig> = {}): pino.Logger {
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
export function createChildLogger(parent: pino.Logger, context: Record<string, any>): pino.Logger {
  return parent.child(context);
}

/**
 * Create HTTP request logging middleware
 */
export function createHttpLogger(logger?: pino.Logger): any {
  const baseLogger = logger || createLogger();

  return (pinoHttp as any)({
    logger: baseLogger,
    customLogLevel: (req: any, res: any, err: any) => {
      if (res.statusCode >= 500) {
        return "error";
      } else if (res.statusCode >= 400) {
        return "warn";
      } else if (res.statusCode >= 300) {
        return "info";
      }
      return "debug";
    },
    customSuccessMessage: (req: any, res: any) => {
      return `${req.method} ${req.url} completed with status ${res.statusCode}`;
    },
    customErrorMessage: (req: any, res: any, err: any) => {
      return `${req.method} ${req.url} failed with status ${res.statusCode}: ${err?.message}`;
    }
  });
}

/**
 * Logger utility class for common operations
 */
export class Logger {
  private logger: pino.Logger;

  constructor(config?: Partial<LoggerConfig>) {
    this.logger = createLogger(config);
  }

  /**
   * Log a trace message
   */
  trace(message: string, data?: Record<string, any>): void {
    this.logger.trace(data, message);
  }

  /**
   * Log a debug message
   */
  debug(message: string, data?: Record<string, any>): void {
    this.logger.debug(data, message);
  }

  /**
   * Log an info message
   */
  info(message: string, data?: Record<string, any>): void {
    this.logger.info(data, message);
  }

  /**
   * Log a warning message
   */
  warn(message: string, data?: Record<string, any>): void {
    this.logger.warn(data, message);
  }

  /**
   * Log an error message
   */
  error(message: string, error?: Error | unknown, data?: Record<string, any>): void {
    const errorData = error instanceof Error ? { err: error, ...data } : { error, ...data };
    this.logger.error(errorData, message);
  }

  /**
   * Log a fatal message
   */
  fatal(message: string, error?: Error | unknown, data?: Record<string, any>): void {
    const errorData = error instanceof Error ? { err: error, ...data } : { error, ...data };
    this.logger.fatal(errorData, message);
  }

  /**
   * Create a child logger with context
   */
  child(context: Record<string, any>): Logger {
    const childLogger = this.logger.child(context);
    const newLogger = new Logger();
    newLogger.logger = childLogger;
    return newLogger;
  }

  /**
   * Log a queue operation
   */
  queue(operation: string, shopId: string, lane: string, data?: Record<string, any>): void {
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
  booking(operation: string, bookingId: string, shopId: string, data?: Record<string, any>): void {
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
  socket(event: string, socketId: string, shopId: string, data?: Record<string, any>): void {
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
  redis(operation: string, command: string, data?: Record<string, any>): void {
    this.debug(`Redis operation: ${operation}`, {
      operation,
      command,
      ...data
    });
  }

  /**
   * Log a PostgreSQL operation
   */
  postgres(operation: string, table: string, data?: Record<string, any>): void {
    this.debug(`PostgreSQL operation: ${operation}`, {
      operation,
      table,
      ...data
    });
  }

  /**
   * Log a wait time calculation
   */
  waitTime(shopId: string, lane: string, estimated: number, actual?: number): void {
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
  chair(operation: string, chairId: string, shopId: string, data?: Record<string, any>): void {
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
  getPinoLogger(): pino.Logger {
    return this.logger;
  }
}

/**
 * Create a logger instance
 */
export function createAppLogger(config?: Partial<LoggerConfig>): Logger {
  return new Logger(config);
}

/**
 * Get the default logger instance
 */
let defaultLogger: Logger | null = null;

export function getLogger(): Logger {
  if (!defaultLogger) {
    defaultLogger = new Logger();
  }
  return defaultLogger;
}

/**
 * Get the default Pino logger
 */
export function getPinoLogger(): pino.Logger {
  return getLogger().getPinoLogger();
}
