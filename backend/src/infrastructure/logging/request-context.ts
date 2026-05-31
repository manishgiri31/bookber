import { AsyncLocalStorage } from "node:async_hooks";
import { randomUUID } from "node:crypto";

export type RequestContext = {
  requestId: string;
  correlationId: string;
};

export const requestContextStorage = new AsyncLocalStorage<RequestContext>();

export function getRequestContext(): RequestContext | undefined {
  return requestContextStorage.getStore();
}

export function createRequestContext(headers: Record<string, string | string[] | undefined>): RequestContext {
  const requestId = headerValue(headers["x-request-id"]) ?? randomUUID();
  const correlationId = headerValue(headers["x-correlation-id"]) ?? requestId;
  return { requestId, correlationId };
}

export function runWithRequestContext<T>(context: RequestContext, fn: () => T): T {
  return requestContextStorage.run(context, fn);
}

function headerValue(value: string | string[] | undefined): string | undefined {
  if (Array.isArray(value)) return value[0];
  return value;
}
