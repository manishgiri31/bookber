import { trace, context, Span, SpanStatusCode, SpanKind, Attributes } from "@opentelemetry/api";
import { NodeTracerProvider } from "@opentelemetry/sdk-trace-node";
import { Resource } from "@opentelemetry/resources";
import { SemanticResourceAttributes } from "@opentelemetry/semantic-conventions";
import { BatchSpanProcessor } from "@opentelemetry/sdk-trace-base";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-grpc";
import { HttpInstrumentation } from "@opentelemetry/instrumentation-http";
import { RedisInstrumentation } from "@opentelemetry/instrumentation-redis-4";
import { PgInstrumentation } from "@opentelemetry/instrumentation-pg";
import { registerInstrumentations } from "@opentelemetry/instrumentation";

/**
 * OpenTelemetry tracing setup for BookBer.
 * 
 * Features:
 * - Automatic instrumentation for HTTP, Redis, PostgreSQL
 * - Custom span creation for business logic
 * - Trace context propagation
 * - OTLP export to Jaeger/Tempo
 * - Resource attributes for service identification
 */

export interface TracingConfig {
  serviceName: string;
  serviceVersion: string;
  environment: string;
  exporterEndpoint: string;
  exporterProtocol: "grpc" | "http";
  sampleRate: number;
  enableAutoInstrumentation: boolean;
}

const DEFAULT_TRACING_CONFIG: TracingConfig = {
  serviceName: "bookber-backend",
  serviceVersion: "1.0.0",
  environment: "production",
  exporterEndpoint: process.env["OTEL_EXPORTER_OTLP_ENDPOINT"] || "http://localhost:4317",
  exporterProtocol: "grpc",
  sampleRate: 1.0,
  enableAutoInstrumentation: true
};

/**
 * Initialize OpenTelemetry tracing
 */
export function initializeTracing(config: Partial<TracingConfig> = {}): void {
  const mergedConfig = { ...DEFAULT_TRACING_CONFIG, ...config };

  // Create resource with service attributes
  const resource = new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: mergedConfig.serviceName,
    [SemanticResourceAttributes.SERVICE_VERSION]: mergedConfig.serviceVersion,
    [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: mergedConfig.environment
  });

  // Create tracer provider
  const provider = new NodeTracerProvider({ resource });

  // Create OTLP exporter
  const exporter = new OTLPTraceExporter({
    url: mergedConfig.exporterEndpoint,
    headers: {}
  });

  // Add batch span processor
  provider.addSpanProcessor(new BatchSpanProcessor(exporter));

  // Register the provider
  provider.register();

  // Enable auto-instrumentation
  if (mergedConfig.enableAutoInstrumentation) {
    registerInstrumentations({
      instrumentations: [
        new HttpInstrumentation(),
        new RedisInstrumentation(),
        new PgInstrumentation()
      ]
    });
  }

  console.log(`OpenTelemetry tracing initialized for ${mergedConfig.serviceName}`);
}

/**
 * Create a custom span
 */
export function createSpan(
  name: string,
  attributes?: Attributes,
  kind: SpanKind = SpanKind.INTERNAL
): Span {
  const tracer = trace.getTracer("bookber-tracer");
  return tracer.startSpan(name, { kind, attributes });
}

/**
 * Run a function within a span
 */
export async function withSpan<T>(
  name: string,
  fn: (span: Span) => Promise<T>,
  attributes?: Attributes,
  kind: SpanKind = SpanKind.INTERNAL
): Promise<T> {
  const span = createSpan(name, attributes, kind);

  try {
    const result = await fn(span);
    span.setStatus({ code: SpanStatusCode.OK });
    return result;
  } catch (error: unknown) {
    span.setStatus({
      code: SpanStatusCode.ERROR,
      message: error instanceof Error ? error.message : String(error)
    });
    span.recordException(error instanceof Error ? error : new Error(String(error)));
    throw error;
  } finally {
    span.end();
  }
}

/**
 * Add attributes to the current span
 */
export function addSpanAttributes(attributes: Attributes): void {
  const span = trace.getActiveSpan();
  if (span) {
    span.setAttributes(attributes);
  }
}

/**
 * Add an event to the current span
 */
export function addSpanEvent(name: string, attributes?: Attributes): void {
  const span = trace.getActiveSpan();
  if (span) {
    span.addEvent(name, attributes);
  }
}

/**
 * Record an exception in the current span
 */
export function recordException(error: Error): void {
  const span = trace.getActiveSpan();
  if (span) {
    span.recordException(error);
    span.setStatus({
      code: SpanStatusCode.ERROR,
      message: error.message
    });
  }
}

/**
 * Set the status of the current span
 */
export function setSpanStatus(code: SpanStatusCode, message?: string): void {
  const span = trace.getActiveSpan();
  if (span) {
    span.setStatus({ code, message });
  }
}

/**
 * Get the current trace ID
 */
export function getCurrentTraceId(): string | undefined {
  const span = trace.getActiveSpan();
  if (span) {
    return span.spanContext().traceId;
  }
  return undefined;
}

/**
 * Get the current span ID
 */
export function getCurrentSpanId(): string | undefined {
  const span = trace.getActiveSpan();
  if (span) {
    return span.spanContext().spanId;
  }
  return undefined;
}

/**
 * Create a child span from the current span
 */
export function createChildSpan(
  name: string,
  attributes?: Attributes,
  kind: SpanKind = SpanKind.INTERNAL
): Span {
  const tracer = trace.getTracer("bookber-tracer");
  const parentSpan = trace.getActiveSpan();

  return tracer.startSpan(name, {
    kind,
    attributes,
    parent: parentSpan ? context.setSpan(context.active(), parentSpan) : undefined
  });
}

/**
 * Run a function within a child span
 */
export async function withChildSpan<T>(
  name: string,
  fn: (span: Span) => Promise<T>,
  attributes?: Attributes,
  kind: SpanKind = SpanKind.INTERNAL
): Promise<T> {
  const span = createChildSpan(name, attributes, kind);

  try {
    const result = await fn(span);
    span.setStatus({ code: SpanStatusCode.OK });
    return result;
  } catch (error: unknown) {
    span.setStatus({
      code: SpanStatusCode.ERROR,
      message: error instanceof Error ? error.message : String(error)
    });
    span.recordException(error instanceof Error ? error : new Error(String(error)));
    throw error;
  } finally {
    span.end();
  }
}

/**
 * Tracing utility class for common operations
 */
export class Tracer {
  private serviceName: string;

  constructor(serviceName: string = "bookber-backend") {
    this.serviceName = serviceName;
  }

  /**
   * Trace a queue operation
   */
  async traceQueueOperation<T>(
    operation: string,
    shopId: string,
    lane: string,
    fn: () => Promise<T>
  ): Promise<T> {
    return withSpan(
      `queue.${operation}`,
      async (span) => {
        span.setAttributes({
          "shop.id": shopId,
          "queue.lane": lane,
          "operation.name": operation
        });
        return await fn();
      },
      { "operation.type": "queue" }
    );
  }

  /**
   * Trace a booking operation
   */
  async traceBookingOperation<T>(
    operation: string,
    bookingId: string,
    shopId: string,
    fn: () => Promise<T>
  ): Promise<T> {
    return withSpan(
      `booking.${operation}`,
      async (span) => {
        span.setAttributes({
          "booking.id": bookingId,
          "shop.id": shopId,
          "operation.name": operation
        });
        return await fn();
      },
      { "operation.type": "booking" }
    );
  }

  /**
   * Trace a socket operation
   */
  async traceSocketOperation<T>(
    operation: string,
    socketId: string,
    shopId: string,
    fn: () => Promise<T>
  ): Promise<T> {
    return withSpan(
      `socket.${operation}`,
      async (span) => {
        span.setAttributes({
          "socket.id": socketId,
          "shop.id": shopId,
          "operation.name": operation
        });
        return await fn();
      },
      { "operation.type": "socket" }
    );
  }

  /**
   * Trace a Redis operation
   */
  async traceRedisOperation<T>(
    operation: string,
    command: string,
    fn: () => Promise<T>
  ): Promise<T> {
    return withSpan(
      `redis.${operation}`,
      async (span) => {
        span.setAttributes({
          "redis.command": command,
          "operation.name": operation
        });
        return await fn();
      },
      { "operation.type": "redis" }
    );
  }

  /**
   * Trace a PostgreSQL operation
   */
  async tracePostgresOperation<T>(
    operation: string,
    table: string,
    fn: () => Promise<T>
  ): Promise<T> {
    return withSpan(
      `postgres.${operation}`,
      async (span) => {
        span.setAttributes({
          "postgres.table": table,
          "operation.name": operation
        });
        return await fn();
      },
      { "operation.type": "postgres" }
    );
  }

  /**
   * Trace a wait time calculation
   */
  async traceWaitTimeCalculation<T>(
    shopId: string,
    lane: string,
    fn: () => Promise<T>
  ): Promise<T> {
    return withSpan(
      "wait.calculate",
      async (span) => {
        span.setAttributes({
          "shop.id": shopId,
          "queue.lane": lane
        });
        return await fn();
      },
      { "operation.type": "wait_time" }
    );
  }

  /**
   * Trace a chair operation
   */
  async traceChairOperation<T>(
    operation: string,
    chairId: string,
    shopId: string,
    fn: () => Promise<T>
  ): Promise<T> {
    return withSpan(
      `chair.${operation}`,
      async (span) => {
        span.setAttributes({
          "chair.id": chairId,
          "shop.id": shopId,
          "operation.name": operation
        });
        return await fn();
      },
      { "operation.type": "chair" }
    );
  }
}

/**
 * Create a tracer instance
 */
export function createTracer(serviceName?: string): Tracer {
  return new Tracer(serviceName);
}

/**
 * Get the default tracer instance
 */
let defaultTracer: Tracer | null = null;

export function getTracer(): Tracer {
  if (!defaultTracer) {
    defaultTracer = new Tracer();
  }
  return defaultTracer;
}
