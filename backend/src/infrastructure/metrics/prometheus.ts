import { Counter, Gauge, Histogram, Registry, collectDefaultMetrics } from "prom-client";

/**
 * Prometheus metrics exposed at GET /metrics.
 * Metric names match operational requirements.
 */
export class BookBerMetrics {
  readonly registry: Registry;

  readonly httpRequestDuration: Histogram<string>;
  readonly bookingCreationDuration: Histogram<string>;
  readonly queueAssignmentDuration: Histogram<string>;
  readonly activeQueueSize: Gauge<string>;
  readonly activeBookings: Gauge<string>;
  readonly activeChairs: Gauge<string>;
  readonly socketConnections: Gauge<string>;
  readonly redisLatency: Histogram<string>;
  readonly databaseQueryDuration: Histogram<string>;

  constructor(registry = new Registry()) {
    this.registry = registry;
    collectDefaultMetrics({ register: registry, prefix: "bookber_" });

    this.httpRequestDuration = new Histogram({
      name: "http_request_duration",
      help: "HTTP request duration in seconds",
      labelNames: ["method", "route", "status_code"],
      buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
      registers: [registry]
    });

    this.bookingCreationDuration = new Histogram({
      name: "booking_creation_duration",
      help: "Booking creation duration in seconds",
      labelNames: ["shop_id", "lane"],
      buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2, 5],
      registers: [registry]
    });

    this.queueAssignmentDuration = new Histogram({
      name: "queue_assignment_duration",
      help: "Queue chair assignment duration in seconds",
      labelNames: ["shop_id", "lane"],
      buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1],
      registers: [registry]
    });

    this.activeQueueSize = new Gauge({
      name: "active_queue_size",
      help: "Active entries in queue by shop and lane",
      labelNames: ["shop_id", "lane"],
      registers: [registry]
    });

    this.activeBookings = new Gauge({
      name: "active_bookings",
      help: "Active bookings by shop",
      labelNames: ["shop_id"],
      registers: [registry]
    });

    this.activeChairs = new Gauge({
      name: "active_chairs",
      help: "Chairs by shop and status",
      labelNames: ["shop_id", "status"],
      registers: [registry]
    });

    this.socketConnections = new Gauge({
      name: "socket_connections",
      help: "Active socket connections",
      labelNames: ["namespace"],
      registers: [registry]
    });

    this.redisLatency = new Histogram({
      name: "redis_latency",
      help: "Redis command latency in seconds",
      labelNames: ["command"],
      buckets: [0.0001, 0.0005, 0.001, 0.005, 0.01, 0.05, 0.1, 0.5],
      registers: [registry]
    });

    this.databaseQueryDuration = new Histogram({
      name: "database_query_duration",
      help: "Database query duration in seconds",
      labelNames: ["model", "operation"],
      buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2],
      registers: [registry]
    });
  }

  async metricsText(): Promise<string> {
    return this.registry.metrics();
  }
}

let metricsInstance: BookBerMetrics | null = null;

export function getMetrics(): BookBerMetrics {
  if (!metricsInstance) {
    metricsInstance = new BookBerMetrics();
  }
  return metricsInstance;
}

export function observeHttpRequest(
  method: string,
  route: string,
  statusCode: number,
  durationSeconds: number
): void {
  getMetrics().httpRequestDuration.observe(
    { method, route, status_code: String(statusCode) },
    durationSeconds
  );
}

export function observeRedisLatency(command: string, durationSeconds: number): void {
  getMetrics().redisLatency.observe({ command }, durationSeconds);
}

export function observeDatabaseQuery(model: string, operation: string, durationSeconds: number): void {
  getMetrics().databaseQueryDuration.observe({ model, operation }, durationSeconds);
}
