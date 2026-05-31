# BookBer Backend — Operations Guide

Production observability, health checks, recovery workers, and Redis infrastructure for the BookBer queue platform.

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Fastify   │────▶│  Prometheus  │────▶│   Grafana   │
│  /metrics   │     │   scraper    │     │  dashboards │
└─────────────┘     └──────────────┘     └─────────────┘
       │
       ├── Pino JSON logs (requestId, correlationId)
       ├── OpenTelemetry → OTLP collector (Jaeger/Tempo)
       ├── PostgreSQL (Prisma + query metrics)
       └── Redis (command/pub/sub pool + health checks)
```

## File structure

```
backend/src/infrastructure/
├── bootstrap.ts                 # Wires logging, metrics, health, redis, workers
├── logging/
│   ├── structured-logger.ts     # Pino root logger + context mixin
│   ├── request-context.ts       # AsyncLocalStorage request/correlation IDs
│   └── request-logging.plugin.ts
├── metrics/
│   ├── prometheus.ts            # Metric definitions
│   └── metrics.routes.ts        # /metrics + HTTP timing + gauge collector
├── tracing/
│   └── otel.ts                  # Optional OTLP tracing
├── redis/
│   └── redis-manager.ts         # Pool (cmd/pub/sub), locks, health, shutdown
├── health/
│   └── health.routes.ts         # /health, /health/live, /health/ready
├── events/
│   └── event-log.service.ts     # Persistent operational event log
└── workers/
    └── recovery-bootstrap.ts    # Starts queue recovery orchestrator

backend/grafana/bookber-dashboard.json
backend/docs/OPERATIONS.md
```

## Health endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /health` | Basic liveness + service metadata |
| `GET /health/live` | Process alive (no dependency checks) |
| `GET /health/ready` | Postgres + Redis readiness (503 if unhealthy) |
| `GET /metrics` | Prometheus text exposition |

## Prometheus metrics

| Metric | Type | Labels |
|--------|------|--------|
| `http_request_duration` | Histogram | method, route, status_code |
| `booking_creation_duration` | Histogram | shop_id, lane |
| `queue_assignment_duration` | Histogram | shop_id, lane |
| `active_queue_size` | Gauge | shop_id, lane |
| `active_bookings` | Gauge | shop_id |
| `active_chairs` | Gauge | shop_id, status |
| `socket_connections` | Gauge | namespace |
| `redis_latency` | Histogram | command |
| `database_query_duration` | Histogram | model, operation |

Gauges refresh every 30 seconds from PostgreSQL. Socket count uses Socket.io engine client count.

## Logging

- **Format:** JSON in production; pretty-print in development when `LOG_PRETTY_PRINT=true`
- **Request ID:** `x-request-id` header (generated if missing), echoed in response
- **Correlation ID:** `x-correlation-id` header (defaults to request ID)
- **Error serialization:** Pino `err` serializer on all error paths

## OpenTelemetry

Set `OTEL_ENABLED=true` and configure:

```env
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
OTEL_SERVICE_NAME=bookber-backend
```

Auto-instruments HTTP, ioredis, and Prisma. Custom spans: `queue.reserve`, etc.

## Redis infrastructure

`RedisManager` provides:

- **Command client** — primary operations + distributed locks
- **Pub client** — publish
- **Sub client** — subscribe
- **Retry strategy** — exponential backoff, max 10 attempts
- **Health checks** — periodic ping + memory info (`REDIS_HEALTH_CHECK_INTERVAL_MS`)
- **Graceful shutdown** — `quit()` on all clients during SIGTERM

## Recovery workers

Enabled when `RECOVERY_WORKERS_ENABLED=true` (default). Workers:

| Worker | Role |
|--------|------|
| Stale service detector | Flags/recovers stuck IN_SERVICE bookings |
| Chair recovery | Releases orphaned occupied chairs |
| Queue reconciler | Reconciles Postgres queue vs Redis |
| Wait-time reconciler | Rebuilds wait-time estimates |
| Redis repair | Rebuilds Redis queue state from Postgres |

Started in `main.ts` after `app.ready()` via `bootstrapInfrastructure()`.

## Event log

Prisma `EventLog` model persists:

| Type | External name |
|------|---------------|
| `BOOKING_CREATED` | booking.created |
| `BOOKING_CANCELLED` | booking.cancelled |
| `QUEUE_JOINED` | queue.joined |
| `QUEUE_LEFT` | queue.left |
| `CHAIR_ASSIGNED` | chair.assigned |
| `CHAIR_RELEASED` | chair.released |

Written from `QueueEngineService` with correlation ID from request context.

## Environment variables

```env
LOG_LEVEL=info
LOG_PRETTY_PRINT=true
PROMETHEUS_ENABLED=true
OTEL_ENABLED=false
RECOVERY_WORKERS_ENABLED=true
REDIS_HEALTH_CHECK_INTERVAL_MS=5000
```

## Grafana

Import `backend/grafana/bookber-dashboard.json`. Scrape `http://bookber-backend:3000/metrics`.

## Runbook snippets

**High queue assignment latency:** Check `queue_assignment_duration` p95, Redis `redis_latency`, and chair availability via `active_chairs`.

**Readiness failing:** `GET /health/ready` returns per-dependency status. Verify `DATABASE_URL` and `REDIS_URL`.

**Rebuild Redis queue:** Recovery orchestrator runs `RedisRepairService` on interval; trigger manual recovery via queue recovery service if exposed.

**Graceful deploy:** Send SIGTERM; workers stop, Redis pool closes, HTTP drains within `SHUTDOWN_TIMEOUT_MS`.
