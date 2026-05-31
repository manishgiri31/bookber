export { rootLogger as logger, createModuleLogger as createChildLogger } from "../../infrastructure/logging/structured-logger.js";

import { createModuleLogger } from "../../infrastructure/logging/structured-logger.js";
import type pino from "pino";

export class Logger {
  private child: pino.Logger;

  constructor(module: string) {
    this.child = createModuleLogger(module);
  }

  info(message: string, data?: Record<string, unknown>) {
    this.child.info(data, message);
  }

  error(message: string, error?: Error, data?: Record<string, unknown>) {
    this.child.error({ err: error, ...data }, message);
  }

  warn(message: string, data?: Record<string, unknown>) {
    this.child.warn(data, message);
  }

  debug(message: string, data?: Record<string, unknown>) {
    this.child.debug(data, message);
  }

  trace(message: string, data?: Record<string, unknown>) {
    this.child.trace(data, message);
  }
}
