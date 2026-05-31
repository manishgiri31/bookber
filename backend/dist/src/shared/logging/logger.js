export { rootLogger as logger, createModuleLogger as createChildLogger } from "../../infrastructure/logging/structured-logger.js";
import { createModuleLogger } from "../../infrastructure/logging/structured-logger.js";
export class Logger {
    child;
    constructor(module) {
        this.child = createModuleLogger(module);
    }
    info(message, data) {
        this.child.info(data, message);
    }
    error(message, error, data) {
        this.child.error({ err: error, ...data }, message);
    }
    warn(message, data) {
        this.child.warn(data, message);
    }
    debug(message, data) {
        this.child.debug(data, message);
    }
    trace(message, data) {
        this.child.trace(data, message);
    }
}
