import { AsyncLocalStorage } from "node:async_hooks";
import { randomUUID } from "node:crypto";
export const requestContextStorage = new AsyncLocalStorage();
export function getRequestContext() {
    return requestContextStorage.getStore();
}
export function createRequestContext(headers) {
    const requestId = headerValue(headers["x-request-id"]) ?? randomUUID();
    const correlationId = headerValue(headers["x-correlation-id"]) ?? requestId;
    return { requestId, correlationId };
}
export function runWithRequestContext(context, fn) {
    return requestContextStorage.run(context, fn);
}
function headerValue(value) {
    if (Array.isArray(value))
        return value[0];
    return value;
}
