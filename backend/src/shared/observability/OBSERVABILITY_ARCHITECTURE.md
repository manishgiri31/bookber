# BookBer Observability Architecture

## Overview

Production-grade observability stack for BookBer queue system, providing comprehensive monitoring, tracing, and logging capabilities.

## Components

### 1. Metrics Collection (Prometheus)

**Technology Stack:**
- `prom-client` for Prometheus metrics
- Custom metrics for business logic
- Standard metrics for infrastructure

**Metric Types:**
- **Counters**: Monotonically increasing values (e.g., total bookings processed)
- **Gauges**: Point-in-time values (e.g., active queue size)
- **Histograms**: Distributions of values (e.g., request latency)
- **Summaries**: Quantiles of values (e.g., p95 latency)

### 2. Distributed Tracing (OpenTelemetry)

**Technology Stack:**
- `@opentelemetry/api` for tracing API
- `@opentelemetry/sdk-trace-node` for Node.js SDK
- `@opentelemetry/instrumentation` for auto-instrumentation
- `@opentelemetry/exporter-trace-otlp-grpc` for OTLP export
- `@opentelemetry/instrumentation-http` for HTTP tracing
- `@opentelemetry/instrumentation-redis-4` for Redis tracing
- `@opentelemetry/instrumentation-pg` for PostgreSQL tracing

**Trace Spans:**
- Queue operations (enqueue, dequeue, position updates)
- Booking lifecycle (create, update, complete, cancel)
- Wait time calculations
- Socket events (connect, disconnect, message)
- Redis operations (get, set, publish, subscribe)
- PostgreSQL queries (select, insert, update, delete)

### 3. Structured Logging (Pino)

**Technology Stack:**
- `pino` for structured logging
- `pino-pretty` for development formatting
- `pino-http` for HTTP request logging
- Custom serializers for sensitive data

**Log Levels:**
- `trace`: Very detailed debugging information
- `debug`: Debugging information
- `info`: General informational messages
- `warn`: Warning messages
- `error`: Error messages
- `fatal`: Critical errors requiring immediate attention

**Log Structure:**
```json
{
  "level": "info",
  "time": "2024-05-30T01:21:00.000Z",
  "shopId": "shop_123",
  "bookingId": "booking_456",
  "action": "queue_enqueue",
  "duration": 45,
  "queuePosition": 5,
  "waitTime": 300
}
```

## Metrics Architecture

### Queue Metrics

**Queue Latency Histogram**
- Name: `bookber_queue_latency_seconds`
- Labels: `shop_id`, `lane`, `operation`
- Buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
- Description: Time taken for queue operations

**Booking Throughput Counter**
- Name: `bookber_booking_throughput_total`
- Labels: `shop_id`, `status`, `lane`
- Description: Total number of bookings processed

**Active Queues Gauge**
- Name: `bookber_active_queues`
- Labels: `shop_id`, `lane`
- Description: Number of active queues per shop

**Queue Size Gauge**
- Name: `bookber_queue_size`
- Labels: `shop_id`, `lane`
- Description: Current size of each queue

**Wait Time Accuracy Gauge**
- Name: `bookber_wait_time_accuracy`
- Labels: `shop_id`, `lane`
- Description: Accuracy of wait time predictions (0-1)

### Socket Metrics

**Socket Connections Gauge**
- Name: `bookber_socket_connections`
- Labels: `shop_id`, `connection_type`
- Description: Number of active socket connections

**Socket Messages Counter**
- Name: `bookber_socket_messages_total`
- Labels: `shop_id`, `message_type`, `direction`
- Description: Total number of socket messages

**Socket Latency Histogram**
- Name: `bookber_socket_latency_seconds`
- Labels: `shop_id`, `message_type`
- Buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1]
- Description: Socket message round-trip time

### Redis Metrics

**Redis Latency Histogram**
- Name: `bookber_redis_latency_seconds`
- Labels: `operation`, `command`
- Buckets: [0.0001, 0.0005, 0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1]
- Description: Redis command execution time

**Redis Connection Pool Gauge**
- Name: `bookber_redis_pool_connections`
- Labels: `state` (active, idle, waiting)
- Description: Redis connection pool state

**Redis Operations Counter**
- Name: `bookber_redis_operations_total`
- Labels: `operation`, `status`
- Description: Total Redis operations

**Redis Errors Counter**
- Name: `bookber_redis_errors_total`
- Labels: `error_type`
- Description: Total Redis errors

### PostgreSQL Metrics

**PostgreSQL Latency Histogram**
- Name: `bookber_postgres_latency_seconds`
- Labels: `operation`, `table`
- Buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5]
- Description: PostgreSQL query execution time

**PostgreSQL Connections Gauge**
- Name: `bookber_postgres_connections`
- Labels: `state` (active, idle, waiting)
- Description: PostgreSQL connection pool state

**PostgreSQL Queries Counter**
- Name: `bookber_postgres_queries_total`
- Labels: `operation`, `table`, `status`
- Description: Total PostgreSQL queries

**PostgreSQL Errors Counter**
- Name: `bookber_postgres_errors_total`
- Labels: `error_type`
- Description: Total PostgreSQL errors

### Chair Metrics

**Chair Utilization Gauge**
- Name: `bookber_chair_utilization`
- Labels: `shop_id`, `chair_id`
- Description: Chair utilization percentage (0-100)

**Chair State Gauge**
- Name: `bookber_chair_state`
- Labels: `shop_id`, `chair_id`, `state`
- Description: Current chair state (0 or 1)

**Chair Service Time Histogram**
- Name: `bookber_chair_service_time_seconds`
- Labels: `shop_id`, `chair_id`, `service_type`
- Buckets: [60, 300, 600, 900, 1200, 1800, 2700, 3600]
- Description: Time spent on service per chair

### Business Metrics

**Bookings Created Counter**
- Name: `bookber_bookings_created_total`
- Labels: `shop_id`, `lane`, `service_type`
- Description: Total bookings created

**Bookings Completed Counter**
- Name: `bookber_bookings_completed_total`
- Labels: `shop_id`, `lane`, `service_type`
- Description: Total bookings completed

**Bookings Cancelled Counter**
- Name: `bookber_bookings_cancelled_total`
- Labels: `shop_id`, `lane`, `reason`
- Description: Total bookings cancelled

**Average Wait Time Gauge**
- Name: `bookber_average_wait_time_seconds`
- Labels: `shop_id`, `lane`
- Description: Current average wait time

**No-Shows Counter**
- Name: `bookber_no_shows_total`
- Labels: `shop_id`, `lane`
- Description: Total no-show bookings

## Tracing Architecture

### Trace Context Propagation

**Trace ID**: Unique identifier for the entire trace
**Span ID**: Unique identifier for each span within a trace
**Parent Span ID**: Reference to the parent span for nested operations

### Span Naming Convention

**Format**: `{service}.{operation}.{resource}`

Examples:
- `queue.enqueue.booking`
- `queue.update.position`
- `wait.calculate.estimate`
- `socket.connect.client`
- `redis.get.queue`
- `postgres.select.booking`

### Span Attributes

**Standard Attributes:**
- `shop.id`: Shop identifier
- `booking.id`: Booking identifier
- `queue.lane`: Queue lane (BOOKBER/WALKIN)
- `chair.id`: Chair identifier
- `user.id`: User identifier
- `operation.name`: Operation name
- `operation.result`: Operation result (success/failure)
- `error.type`: Error type (if applicable)
- `error.message`: Error message (if applicable)

**Custom Attributes:**
- `queue.position`: Queue position
- `wait.time.estimated`: Estimated wait time
- `wait.time.actual`: Actual wait time
- `socket.connection.id`: Socket connection ID
- `redis.command`: Redis command
- `postgres.query`: PostgreSQL query hash

## Health Check Architecture

### Health Check Endpoints

**`/health`**: Basic health check
- Returns 200 if service is healthy
- Returns 503 if service is unhealthy

**`/health/ready`**: Readiness check
- Checks if service is ready to accept traffic
- Includes dependencies (Redis, PostgreSQL)

**`/health/live`**: Liveness check
- Checks if service is alive
- Quick check without external dependencies

**`/metrics`**: Prometheus metrics endpoint
- Exposes all metrics in Prometheus format

### Health Check Components

**Database Health**
- PostgreSQL connection check
- Query execution test
- Connection pool status

**Redis Health**
- Redis connection check
- PING command test
- Connection pool status

**Queue Health**
- Queue size check
- Queue latency check
- Recovery worker status

**Socket Health**
- Socket connection count
- Message queue size
- Connection pool status

## Alerting Strategy

### Alert Severity Levels

**Critical (P0)**
- Service down
- Database connection failure
- Redis connection failure
- Queue processing stopped
- System-wide outage

**High (P1)**
- High error rate (> 5%)
- High latency (> 5s p95)
- Queue backlog (> 1000)
- Memory pressure (> 90%)
- CPU pressure (> 90%)

**Medium (P2)**
- Elevated error rate (> 1%)
- Elevated latency (> 2s p95)
- Queue backlog (> 500)
- Memory pressure (> 80%)
- CPU pressure (> 80%)

**Low (P3)**
- Minor error rate (> 0.5%)
- Minor latency (> 1s p95)
- Queue backlog (> 200)
- Memory pressure (> 70%)
- CPU pressure (> 70%)

### Alert Rules

**Queue Latency**
- Alert if p95 latency > 5s for 5 minutes
- Alert if p95 latency > 10s for 2 minutes

**Booking Throughput**
- Alert if throughput drops by 50% for 5 minutes
- Alert if throughput drops by 80% for 2 minutes

**Active Queues**
- Alert if active queues drop by 50% for 5 minutes
- Alert if active queues drop to 0 for 1 minute

**Wait Time Accuracy**
- Alert if accuracy < 80% for 10 minutes
- Alert if accuracy < 60% for 5 minutes

**Chair Utilization**
- Alert if utilization < 50% for 30 minutes
- Alert if utilization > 100% for 5 minutes

**Socket Connections**
- Alert if connections drop by 50% for 5 minutes
- Alert if connections = 0 for 1 minute

**Redis Latency**
- Alert if p95 latency > 100ms for 5 minutes
- Alert if p95 latency > 500ms for 2 minutes

**PostgreSQL Latency**
- Alert if p95 latency > 1s for 5 minutes
- Alert if p95 latency > 5s for 2 minutes

### Alert Notifications

**Channels:**
- PagerDuty for critical alerts
- Slack for high/medium alerts
- Email for low alerts

**Escalation:**
- Critical: Immediate escalation to on-call engineer
- High: Escalate after 15 minutes
- Medium: Escalate after 30 minutes
- Low: No escalation

## Dashboard Architecture

### Grafana Dashboards

**1. Overview Dashboard**
- System health overview
- Key metrics at a glance
- Recent alerts
- Service status

**2. Queue Performance Dashboard**
- Queue latency distribution
- Booking throughput
- Active queues
- Queue size trends
- Wait time accuracy

**3. Socket Performance Dashboard**
- Socket connections
- Message throughput
- Socket latency
- Connection errors

**4. Database Performance Dashboard**
- PostgreSQL latency
- Query performance
- Connection pool status
- Slow queries

**5. Redis Performance Dashboard**
- Redis latency
- Command performance
- Connection pool status
- Memory usage

**6. Chair Utilization Dashboard**
- Chair utilization
- Service time distribution
- Chair state
- No-show rate

**7. Error Dashboard**
- Error rate by service
- Error rate by type
- Error distribution
- Recent errors

**8. Tracing Dashboard**
- Trace search
- Span analysis
- Service dependency graph
- Trace waterfall

## Implementation Priority

**Phase 1: Core Observability**
- Prometheus metrics setup
- Structured logging
- Basic health checks
- Queue metrics

**Phase 2: Enhanced Metrics**
- Socket metrics
- Redis metrics
- PostgreSQL metrics
- Chair metrics

**Phase 3: Tracing**
- OpenTelemetry setup
- Auto-instrumentation
- Custom instrumentation
- Trace visualization

**Phase 4: Dashboards & Alerting**
- Grafana dashboards
- Alert rules
- Notification channels
- Alert tuning

## Configuration

### Environment Variables

```bash
# Observability
OTEL_SERVICE_NAME=bookber-backend
OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger:4317
OTEL_EXPORTER_OTLP_PROTOCOL=grpc
OTEL_RESOURCE_ATTRIBUTES=service.version=1.0.0,deployment.environment=production

# Logging
LOG_LEVEL=info
LOG_FORMAT=json

# Metrics
METRICS_ENABLED=true
METRICS_PORT=9090

# Health Checks
HEALTH_CHECK_ENABLED=true
HEALTH_CHECK_PORT=8080
```

## Best Practices

1. **Metric Naming**: Use consistent naming conventions with prefixes
2. **Label Cardinality**: Keep label cardinality low (< 100 unique values)
3. **Sampling**: Use appropriate sampling rates for tracing
4. **Log Levels**: Use appropriate log levels for severity
5. **Sensitive Data**: Never log sensitive information (PII, tokens)
6. **Performance**: Ensure observability doesn't impact performance
7. **Testing**: Test observability in staging before production
8. **Documentation**: Document custom metrics and alerts
9. **Review**: Regularly review and update alert thresholds
10. **Training**: Train team on observability tools and practices
