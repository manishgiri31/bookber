# Observability Dependencies Installation Guide

## Overview

This guide provides instructions for installing and configuring the observability stack for BookBer.

## Required Dependencies

### Production Dependencies

```bash
# Prometheus Metrics
npm install prom-client

# OpenTelemetry Tracing
npm install @opentelemetry/api
npm install @opentelemetry/sdk-trace-node
npm install @opentelemetry/resources
npm install @opentelemetry/semantic-conventions
npm install @opentelemetry/sdk-trace-base
npm install @opentelemetry/exporter-trace-otlp-grpc
npm install @opentelemetry/instrumentation
npm install @opentelemetry/instrumentation-http
npm install @opentelemetry/instrumentation-redis-4
npm install @opentelemetry/instrumentation-pg

# Structured Logging
npm install pino
npm install pino-pretty
npm install pino-http
```

### Development Dependencies

```bash
# Type Definitions
npm install -D @types/pino
npm install -D @types/pino-http
```

## Installation Steps

### Step 1: Install Dependencies

Run the following command to install all required dependencies:

```bash
npm install prom-client \
  @opentelemetry/api \
  @opentelemetry/sdk-trace-node \
  @opentelemetry/resources \
  @opentelemetry/semantic-conventions \
  @opentelemetry/sdk-trace-base \
  @opentelemetry/exporter-trace-otlp-grpc \
  @opentelemetry/instrumentation \
  @opentelemetry/instrumentation-http \
  @opentelemetry/instrumentation-redis-4 \
  @opentelemetry/instrumentation-pg \
  pino \
  pino-pretty \
  pino-http

npm install -D @types/pino @types/pino-http
```

### Step 2: Configure Environment Variables

Add the following environment variables to your `.env` file:

```bash
# Observability Configuration
OTEL_SERVICE_NAME=bookber-backend
OTEL_SERVICE_VERSION=1.0.0
OTEL_DEPLOYMENT_ENVIRONMENT=production
OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger:4317
OTEL_EXPORTER_OTLP_PROTOCOL=grpc

# Logging Configuration
LOG_LEVEL=info
LOG_FORMAT=json

# Metrics Configuration
METRICS_ENABLED=true
METRICS_PORT=9090

# Health Check Configuration
HEALTH_CHECK_ENABLED=true
HEALTH_CHECK_PORT=8080
```

### Step 3: Initialize OpenTelemetry Tracing

Create or update your application entry point (e.g., `src/index.ts`) to initialize tracing:

```typescript
import { initializeTracing } from "./shared/observability/otel-tracing";

// Initialize tracing before importing other modules
initializeTracing({
  serviceName: process.env.OTEL_SERVICE_NAME || "bookber-backend",
  serviceVersion: process.env.OTEL_SERVICE_VERSION || "1.0.0",
  environment: process.env.OTEL_DEPLOYMENT_ENVIRONMENT || "production",
  exporterEndpoint: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || "http://localhost:4317",
  exporterProtocol: "grpc",
  sampleRate: 1.0,
  enableAutoInstrumentation: true
});
```

### Step 4: Initialize Prometheus Metrics

Create a metrics instance in your application:

```typescript
import { getMetrics } from "./shared/observability/prometheus-metrics";

// Get the singleton metrics instance
const metrics = getMetrics({
  service: "bookber-backend",
  environment: process.env.OTEL_DEPLOYMENT_ENVIRONMENT || "production"
});
```

### Step 5: Initialize Structured Logging

Create a logger instance in your application:

```typescript
import { getLogger } from "./shared/observability/logger";

// Get the singleton logger instance
const logger = getLogger();
```

### Step 6: Register Health Check Endpoints

Register health check endpoints with Fastify:

```typescript
import { createHealthCheckService } from "./shared/observability/health-check";
import { redis } from "./shared/redis/redis";
import { prisma } from "./shared/db/prisma";

// Create health check service
const healthCheckService = createHealthCheckService(redis, prisma);

// Register endpoints
healthCheckService.registerEndpoints(fastify);
```

### Step 7: Expose Metrics Endpoint

Add the Prometheus metrics endpoint to your Fastify application:

```typescript
import { getMetrics } from "./shared/observability/prometheus-metrics";

// Get metrics instance
const metrics = getMetrics();

// Register metrics endpoint
fastify.get("/metrics", async (request, reply) => {
  const metricsData = await metrics.getMetrics();
  reply.type("text/plain").send(metricsData);
});
```

## Infrastructure Setup

### Prometheus

#### Install Prometheus

```bash
# Using Docker
docker run -d \
  --name prometheus \
  -p 9090:9090 \
  -v /path/to/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus
```

#### Configure Prometheus

Create `prometheus.yml`:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'bookber-backend'
    static_configs:
      - targets: ['localhost:9090']
        labels:
          service: 'bookber-backend'
          environment: 'production'
```

### Jaeger (for Tracing)

#### Install Jaeger

```bash
# Using Docker
docker run -d \
  --name jaeger \
  -p 16686:16686 \
  -p 14250:14250 \
  -p 4317:4317 \
  jaegertracing/all-in-one:latest
```

#### Configure Jaeger

Set the environment variable:

```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger:4317
```

### Grafana (for Dashboards)

#### Install Grafana

```bash
# Using Docker
docker run -d \
  --name grafana \
  -p 3000:3000 \
  grafana/grafana
```

#### Configure Grafana

1. Access Grafana at `http://localhost:3000`
2. Add Prometheus as a data source
3. Import the dashboard configurations from `grafana-dashboards.json`

## Verification

### Verify Metrics

```bash
curl http://localhost:9090/metrics
```

You should see Prometheus metrics in the output.

### Verify Health Checks

```bash
curl http://localhost:8080/health
curl http://localhost:8080/health/ready
curl http://localhost:8080/health/live
curl http://localhost:8080/health/detailed
```

### Verify Tracing

1. Access Jaeger UI at `http://localhost:16686`
2. Select the service `bookber-backend`
3. Search for traces
4. Verify traces are being collected

### Verify Logging

Check the application logs to ensure structured logging is working correctly.

## Troubleshooting

### Prometheus Not Collecting Metrics

1. Verify Prometheus is running: `docker ps | grep prometheus`
2. Check Prometheus configuration: `docker exec prometheus cat /etc/prometheus/prometheus.yml`
3. Verify metrics endpoint is accessible: `curl http://localhost:9090/metrics`
4. Check Prometheus logs: `docker logs prometheus`

### Jaeger Not Collecting Traces

1. Verify Jaeger is running: `docker ps | grep jaeger`
2. Check environment variables: `echo $OTEL_EXPORTER_OTLP_ENDPOINT`
3. Verify tracing is initialized in application code
4. Check Jaeger logs: `docker logs jaeger`

### Health Checks Failing

1. Verify Redis is accessible: `redis-cli ping`
2. Verify PostgreSQL is accessible: `psql -U username -d database -c "SELECT 1"`
3. Check health check endpoint: `curl http://localhost:8080/health/detailed`
4. Review application logs for errors

### Logging Not Working

1. Verify log level is set correctly: `echo $LOG_LEVEL`
2. Check logger initialization in application code
3. Review application logs for errors
4. Test logger with a simple log statement

## Production Considerations

### Security

1. Use HTTPS for all external communications
2. Secure the metrics endpoint with authentication
3. Use secrets management for sensitive configuration
4. Rotate API keys and credentials regularly

### Performance

1. Monitor the impact of observability on application performance
2. Adjust sampling rates for tracing in high-traffic scenarios
3. Use batch processing for metrics export
4. Consider using a separate observability stack for production

### Scalability

1. Use a centralized metrics aggregation service
2. Implement log aggregation (e.g., ELK stack, Loki)
3. Use distributed tracing with proper sampling
4. Scale observability infrastructure based on load

### Reliability

1. Implement alerting for observability infrastructure failures
2. Use multiple exporters for redundancy
3. Implement backup and recovery for observability data
4. Monitor the observability stack itself

## Maintenance

### Regular Tasks

- Review and update alert thresholds monthly
- Review and update dashboards quarterly
- Review and update tracing configuration as needed
- Monitor observability infrastructure health
- Review and clean up old metrics and traces

### Updates

- Keep dependencies up to date
- Review and apply security patches
- Test updates in staging before production
- Monitor for breaking changes in dependencies

## Summary

This guide provides comprehensive instructions for installing and configuring the observability stack for BookBer. Follow these steps to ensure proper setup and configuration of all observability components.
