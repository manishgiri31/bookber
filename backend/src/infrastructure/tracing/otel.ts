import { env } from "../../shared/config/env.js";
import { createModuleLogger } from "../logging/structured-logger.js";

const log = createModuleLogger("tracing");

let initialized = false;

export async function initializeTracing(): Promise<void> {
  if (!env.OTEL_ENABLED || initialized) return;

  try {
    const { NodeTracerProvider } = await import("@opentelemetry/sdk-trace-node");
    const { resourceFromAttributes } = await import("@opentelemetry/resources");
    const { SemanticResourceAttributes } = await import("@opentelemetry/semantic-conventions");
    const { BatchSpanProcessor } = await import("@opentelemetry/sdk-trace-base");
    const { OTLPTraceExporter } = await import("@opentelemetry/exporter-trace-otlp-grpc");
    const { registerInstrumentations } = await import("@opentelemetry/instrumentation");
    const { HttpInstrumentation } = await import("@opentelemetry/instrumentation-http");
    const { IORedisInstrumentation } = await import("@opentelemetry/instrumentation-ioredis");
    const { PrismaInstrumentation } = await import("@prisma/instrumentation");

    const resource = resourceFromAttributes({
      [SemanticResourceAttributes.SERVICE_NAME]: env.OTEL_SERVICE_NAME,
      [SemanticResourceAttributes.SERVICE_VERSION]: env.OTEL_SERVICE_VERSION,
      [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: env.OTEL_DEPLOYMENT_ENVIRONMENT
    });

    const exporter = new OTLPTraceExporter({ url: env.OTEL_EXPORTER_OTLP_ENDPOINT });
    const provider = new NodeTracerProvider({
      resource,
      spanProcessors: [new BatchSpanProcessor(exporter)]
    });

    provider.register();

    registerInstrumentations({
      instrumentations: [
        new HttpInstrumentation(),
        new IORedisInstrumentation(),
        new PrismaInstrumentation()
      ]
    });

    initialized = true;
    log.info({ endpoint: env.OTEL_EXPORTER_OTLP_ENDPOINT }, "OpenTelemetry tracing initialized");
  } catch (error: unknown) {
    log.error({ err: error }, "OpenTelemetry initialization failed");
  }
}

export async function withSpan<T>(
  name: string,
  attributes: Record<string, string | number | boolean>,
  fn: () => Promise<T>
): Promise<T> {
  if (!env.OTEL_ENABLED) return fn();

  const { trace, SpanStatusCode } = await import("@opentelemetry/api");
  const tracer = trace.getTracer("bookber");
  return tracer.startActiveSpan(name, { attributes }, async (span) => {
    try {
      const result = await fn();
      span.setStatus({ code: SpanStatusCode.OK });
      return result;
    } catch (error: unknown) {
      span.setStatus({
        code: SpanStatusCode.ERROR,
        message: error instanceof Error ? error.message : String(error)
      });
      if (error instanceof Error) span.recordException(error);
      throw error;
    } finally {
      span.end();
    }
  });
}
