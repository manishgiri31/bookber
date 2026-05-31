# Production-Grade Observability Architecture for BookBer

## Overview

This document describes the production-grade observability architecture for the BookBer queue system, designed for comprehensive monitoring, tracing, and alerting.

## Architecture Components

### 1. Metrics Collection

**Prometheus Metrics**:
- Counter: Monotonically increasing values (request count, error count)
- Gauge: Values that can go up or down (queue length, active connections)
- Histogram: Distribution of values (request latency, queue wait time)
- Summary: Quantiles of values (p50, p95, p99 latency)

**Metric Categories**:
- **Queue Metrics**: Queue length, enqueue rate, dequeue rate, position updates
- **Booking Metrics**: Booking throughput, booking latency, wait-time accuracy
- **Socket Metrics**: Active connections, message rate, disconnection rate
- **Redis Metrics**: Latency, hit rate, memory usage, connection pool stats
- **PostgreSQL Metrics**: Query latency, connection pool stats, slow queries
- **System Metrics**: CPU, memory, disk, network

### 2. Distributed Tracing

**OpenTelemetry Tracing**:
- Trace: A collection of spans representing a single request
- Span: A single operation within a trace
- Span Attributes: Key-value pairs describing the span
- Span Events: Timestamped events within a span
- Span Links: Links to related spans

**Trace Context Propagation**:
- HTTP headers for inter-service communication
- WebSocket headers for socket communication
- Redis context for cache operations
- Database context for query operations

### 3. Structured Logging

**Log Levels**:
- ERROR: Errors that require immediate attention
- WARN: Warning conditions that might indicate problems
- INFO: Informational messages about normal operation
- DEBUG: Detailed debugging information

**Log Structure**:
- Timestamp
- Level
- Service name
- Trace ID
- Span ID
- Message
- Structured fields (JSON)
- Stack trace (for errors)

### 4. Health Checks

**Health Check Types**:
- **Liveness**: Is the service running?
- **Readiness**: Is the service ready to accept traffic?
- **Startup**: Is the service starting up?
- **Custom**: Domain-specific health checks

**Health Check Components**:
- Database connectivity
- Redis connectivity
- Socket server status
- Queue processor status
- Memory usage
- CPU usage

### 5. Alerting Strategy

**Alert Severity Levels**:
- **Critical**: Service down, data loss, security breach
- **Warning**: Performance degradation, high error rate
- **Info**: Informational alerts (deployments, config changes)

**Alert Channels**:
- PagerDuty (critical)
- Slack (warning, info)
- Email (all)
- Webhook (custom)

## Metric Definitions

### Queue Metrics

```
# Queue length per shop and lane
bookber_queue_length{shop_id, lane}

# Enqueue rate
bookber_enqueue_total{shop_id, lane, status}

# Dequeue rate
bookber_dequeue_total{shop_id, lane, status}

# Position update latency
bookber_position_update_duration_seconds{shop_id, lane}

# Queue wait time
bookber_queue_wait_seconds{shop_id, lane, position}
```

### Booking Metrics

```
# Booking throughput
bookber_booking_total{status, service_type}

# Booking latency
bookber_booking_duration_seconds{stage}

# Wait-time accuracy
bookber_wait_time_accuracy{shop_id, service_type}

# Booking conversion rate
bookber_booking_conversion_rate{shop_id}
```

### Socket Metrics

```
# Active socket connections
bookber_socket_connections{shop_id, user_id}

# Socket message rate
bookber_socket_messages_total{direction, type}

# Socket disconnection rate
bookber_socket_disconnections_total{reason}

# Socket latency
bookber_socket_latency_seconds{shop_id}
```

### Redis Metrics

```
# Redis operation latency
bookber_redis_operation_duration_seconds{operation, key_type}

# Redis hit rate
bookber_redis_cache_hit_rate{key_type}

# Redis memory usage
bookber_redis_memory_bytes{key_type}

# Redis connection pool stats
bookber_redis_pool_connections{state}
```

### PostgreSQL Metrics

```
# Query latency
bookber_db_query_duration_seconds{operation, table}

# Connection pool stats
bookber_db_pool_connections{state}

# Slow query count
bookber_db_slow_queries_total{table}

# Transaction duration
bookber_db_transaction_duration_seconds
```

## Tracing Strategy

### Trace Spans

**Queue Operations**:
- `bookber.queue.enqueue` - Enqueue a booking
- `bookber.queue.dequeue` - Dequeue a booking
- `bookber.queue.update_position` - Update queue position
- `bookber.queue.get_status` - Get queue status

**Booking Operations**:
- `bookber.booking.create` - Create a booking
- `bookber.booking.update` - Update a booking
- `bookber.booking.cancel` - Cancel a booking
- `bookber.booking.complete` - Complete a booking

**Socket Operations**:
- `bookber.socket.connect` - Connect a socket
- `bookber.socket.disconnect` - Disconnect a socket
- `bookber.socket.message` - Send/receive message

**Cache Operations**:
- `bookber.cache.get` - Get from cache
- `bookber.cache.set` - Set in cache
- `bookber.cache.delete` - Delete from cache
- `bookber.cache.invalidate` - Invalidate cache

**Database Operations**:
- `bookber.db.query` - Execute query
- `bookber.db.transaction` - Execute transaction
- `bookber.db.batch` - Execute batch operation

### Span Attributes

**Common Attributes**:
- `service.name` - Service name
- `service.version` - Service version
- `shop.id` - Shop ID
- `user.id` - User ID
- `booking.id` - Booking ID

**Queue Attributes**:
- `queue.lane` - Queue lane
- `queue.position` - Queue position
- `queue.status` - Queue status

**Socket Attributes**:
- `socket.id` - Socket ID
- `socket.type` - Socket type
- `socket.direction` - Message direction

## Logging Strategy

### Log Format

```json
{
  "timestamp": "2026-05-29T02:51:00.000Z",
  "level": "INFO",
  "service": "bookber-api",
  "trace_id": "abc123",
  "span_id": "def456",
  "message": "Booking created successfully",
  "shop_id": "shop123",
  "booking_id": "booking456",
  "duration_ms": 150
}
```

### Log Categories

**Application Logs**:
- Business logic events
- User actions
- State changes

**System Logs**:
- Startup/shutdown events
- Configuration changes
- Health check results

**Error Logs**:
- Exception stack traces
- Error context
- Recovery actions

**Audit Logs**:
- Security events
- Access control
- Data modifications

## Dashboard Configuration

### Key Dashboards

**1. Overview Dashboard**:
- Request rate
- Error rate
- P95 latency
- Active users
- Queue length

**2. Queue Performance Dashboard**:
- Queue length per shop
- Enqueue/dequeue rate
- Average wait time
- Position update latency

**3. Booking Dashboard**:
- Booking throughput
- Booking latency
- Wait-time accuracy
- Conversion rate

**4. Socket Dashboard**:
- Active connections
- Message rate
- Disconnection rate
- Socket latency

**5. Infrastructure Dashboard**:
- CPU usage
- Memory usage
- Disk usage
- Network I/O

**6. Database Dashboard**:
- Query latency
- Connection pool stats
- Slow queries
- Transaction rate

**7. Redis Dashboard**:
- Operation latency
- Hit rate
- Memory usage
- Connection pool stats

## Health Check Endpoints

### Health Check Endpoints

**Liveness Probe**:
- `GET /health/live` - Returns 200 if service is running

**Readiness Probe**:
- `GET /health/ready` - Returns 200 if service is ready to accept traffic

**Startup Probe**:
- `GET /health/startup` - Returns 200 if service is starting up

**Detailed Health**:
- `GET /health` - Returns detailed health status

### Health Check Response

```json
{
  "status": "healthy",
  "timestamp": "2026-05-29T02:51:00.000Z",
  "checks": {
    "database": {
      "status": "healthy",
      "latency_ms": 5
    },
    "redis": {
      "status": "healthy",
      "latency_ms": 2
    },
    "socket_server": {
      "status": "healthy",
      "connections": 100
    }
  }
}
```

## Alerting Rules

### Critical Alerts

**Service Down**:
- Condition: Service not responding for 1 minute
- Severity: Critical
- Channel: PagerDuty, Slack

**High Error Rate**:
- Condition: Error rate > 5% for 5 minutes
- Severity: Critical
- Channel: PagerDuty, Slack

**Database Down**:
- Condition: Database not responding for 30 seconds
- Severity: Critical
- Channel: PagerDuty, Slack

**Redis Down**:
- Condition: Redis not responding for 30 seconds
- Severity: Critical
- Channel: PagerDuty, Slack

### Warning Alerts

**High Latency**:
- Condition: P95 latency > 1 second for 5 minutes
- Severity: Warning
- Channel: Slack

**Queue Backlog**:
- Condition: Queue length > 100 for 10 minutes
- Severity: Warning
- Channel: Slack

**Memory Pressure**:
- Condition: Memory usage > 80%
- Severity: Warning
- Channel: Slack

**Connection Pool Exhaustion**:
- Condition: Connection pool usage > 90%
- Severity: Warning
- Channel: Slack

### Info Alerts

**Deployment**:
- Condition: New deployment detected
- Severity: Info
- Channel: Slack

**Configuration Change**:
- Condition: Configuration change detected
- Severity: Info
- Channel: Slack

## Implementation Components

### Prometheus Metrics Collector

```typescript
class PrometheusMetricsCollector {
  private registry: Registry;
  private queueMetrics: QueueMetrics;
  private bookingMetrics: BookingMetrics;
  private socketMetrics: SocketMetrics;
  private redisMetrics: RedisMetrics;
  private dbMetrics: DatabaseMetrics;
  
  registerMetrics(): void;
  collectQueueMetrics(): void;
  collectBookingMetrics(): void;
  collectSocketMetrics(): void;
  collectRedisMetrics(): void;
  collectDatabaseMetrics(): void;
}
```

### OpenTelemetry Tracer

```typescript
class OpenTelemetryTracer {
  private tracer: Tracer;
  
  startSpan(name: string): Span;
  startSpanWithParent(name: string, parent: Span): Span;
  injectContext(headers: Headers): void;
  extractContext(headers: Headers): Context;
  recordException(span: Span, error: Error): void;
}
```

### Structured Logger

```typescript
class StructuredLogger {
  private logger: Logger;
  
  info(message: string, context?: Record<string, any>): void;
  warn(message: string, context?: Record<string, any>): void;
  error(message: string, error?: Error, context?: Record<string, any>): void;
  debug(message: string, context?: Record<string, any>): void;
}
```

### Health Check Service

```typescript
class HealthCheckService {
  private checks: Map<string, HealthCheck>;
  
  registerCheck(name: string, check: HealthCheck): void;
  runLivenessCheck(): Promise<HealthStatus>;
  runReadinessCheck(): Promise<HealthStatus>;
  runStartupCheck(): Promise<HealthStatus>;
  runAllChecks(): Promise<AggregateHealthStatus>;
}
```

## Configuration

### Prometheus Configuration

```typescript
interface PrometheusConfig {
  enabled: boolean;
  port: number;
  path: string;
  collectDefaultMetrics: boolean;
  collectInterval: number;
}
```

### OpenTelemetry Configuration

```typescript
interface OpenTelemetryConfig {
  enabled: boolean;
  serviceName: string;
  serviceVersion: string;
  exporter: 'otlp' | 'jaeger' | 'zipkin';
  exporterUrl: string;
  sampleRate: number;
}
```

### Logging Configuration

```typescript
interface LoggingConfig {
  level: 'debug' | 'info' | 'warn' | 'error';
  format: 'json' | 'text';
  output: 'stdout' | 'file';
  filePath?: string;
  includeTraceId: boolean;
  includeSpanId: boolean;
}
```

## Best Practices

1. **Always use structured logging** with consistent field names
2. **Include trace and span IDs** in all logs for correlation
3. **Use appropriate metric types** (counter, gauge, histogram, summary)
4. **Label metrics with relevant dimensions** (shop_id, lane, status)
5. **Set appropriate bucket sizes** for histograms
6. **Use sampling for high-volume traces**
7. **Implement proper error handling** in all collectors
8. **Test health checks** regularly
9. **Set up alerting** for critical metrics
10. **Review dashboards** regularly for relevance
