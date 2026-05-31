import type { QueueLane } from "@prisma/client";
import { Counter, Gauge, Histogram, Registry, Summary } from "prom-client";

/**
 * Production-grade Prometheus metrics collector for BookBer.
 * 
 * Features:
 * - Queue metrics (latency, throughput, size)
 * - Socket metrics (connections, messages, latency)
 * - Redis metrics (latency, operations, errors)
 * - PostgreSQL metrics (latency, queries, errors)
 * - Chair metrics (utilization, state, service time)
 * - Business metrics (bookings, wait time, no-shows)
 */

export class PrometheusMetrics {
  private registry: Registry;
  private defaultLabels: Record<string, string>;

  // Queue Metrics
  private queueLatency!: Histogram<string>;
  private bookingThroughput!: Counter<string>;
  private activeQueues!: Gauge<string>;
  private queueSize!: Gauge<string>;
  private waitTimeAccuracy!: Gauge<string>;

  // Socket Metrics
  private socketConnections!: Gauge<string>;
  private socketMessages!: Counter<string>;
  private socketLatency!: Histogram<string>;

  // Redis Metrics
  private redisLatency!: Histogram<string>;
  private redisPoolConnections!: Gauge<string>;
  private redisOperations!: Counter<string>;
  private redisErrors!: Counter<string>;

  // PostgreSQL Metrics
  private postgresLatency!: Histogram<string>;
  private postgresConnections!: Gauge<string>;
  private postgresQueries!: Counter<string>;
  private postgresErrors!: Counter<string>;

  // Chair Metrics
  private chairUtilization!: Gauge<string>;
  private chairState!: Gauge<string>;
  private chairServiceTime!: Histogram<string>;

  // Business Metrics
  private bookingsCreated!: Counter<string>;
  private bookingsCompleted!: Counter<string>;
  private bookingsCancelled!: Counter<string>;
  private averageWaitTime!: Gauge<string>;
  private noShows!: Counter<string>;

  // HTTP Metrics
  private httpRequests!: Counter<string>;
  private httpRequestDuration!: Histogram<string>;
  private httpErrors!: Counter<string>;

  constructor(registry?: Registry, defaultLabels: Record<string, string> = {}) {
    this.registry = registry || new Registry();
    this.defaultLabels = defaultLabels;

    this.initializeMetrics();
  }

  /**
   * Initialize all Prometheus metrics
   */
  private initializeMetrics(): void {
    // Queue Metrics
    this.queueLatency = new Histogram({
      name: "bookber_queue_latency_seconds",
      help: "Time taken for queue operations",
      labelNames: ["shop_id", "lane", "operation"],
      buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
      registers: [this.registry]
    });

    this.bookingThroughput = new Counter({
      name: "bookber_booking_throughput_total",
      help: "Total number of bookings processed",
      labelNames: ["shop_id", "status", "lane"],
      registers: [this.registry]
    });

    this.activeQueues = new Gauge({
      name: "bookber_active_queues",
      help: "Number of active queues per shop",
      labelNames: ["shop_id", "lane"],
      registers: [this.registry]
    });

    this.queueSize = new Gauge({
      name: "bookber_queue_size",
      help: "Current size of each queue",
      labelNames: ["shop_id", "lane"],
      registers: [this.registry]
    });

    this.waitTimeAccuracy = new Gauge({
      name: "bookber_wait_time_accuracy",
      help: "Accuracy of wait time predictions (0-1)",
      labelNames: ["shop_id", "lane"],
      registers: [this.registry]
    });

    // Socket Metrics
    this.socketConnections = new Gauge({
      name: "bookber_socket_connections",
      help: "Number of active socket connections",
      labelNames: ["shop_id", "connection_type"],
      registers: [this.registry]
    });

    this.socketMessages = new Counter({
      name: "bookber_socket_messages_total",
      help: "Total number of socket messages",
      labelNames: ["shop_id", "message_type", "direction"],
      registers: [this.registry]
    });

    this.socketLatency = new Histogram({
      name: "bookber_socket_latency_seconds",
      help: "Socket message round-trip time",
      labelNames: ["shop_id", "message_type"],
      buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1],
      registers: [this.registry]
    });

    // Redis Metrics
    this.redisLatency = new Histogram({
      name: "bookber_redis_latency_seconds",
      help: "Redis command execution time",
      labelNames: ["operation", "command"],
      buckets: [0.0001, 0.0005, 0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1],
      registers: [this.registry]
    });

    this.redisPoolConnections = new Gauge({
      name: "bookber_redis_pool_connections",
      help: "Redis connection pool state",
      labelNames: ["state"],
      registers: [this.registry]
    });

    this.redisOperations = new Counter({
      name: "bookber_redis_operations_total",
      help: "Total Redis operations",
      labelNames: ["operation", "status"],
      registers: [this.registry]
    });

    this.redisErrors = new Counter({
      name: "bookber_redis_errors_total",
      help: "Total Redis errors",
      labelNames: ["error_type"],
      registers: [this.registry]
    });

    // PostgreSQL Metrics
    this.postgresLatency = new Histogram({
      name: "bookber_postgres_latency_seconds",
      help: "PostgreSQL query execution time",
      labelNames: ["operation", "table"],
      buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
      registers: [this.registry]
    });

    this.postgresConnections = new Gauge({
      name: "bookber_postgres_connections",
      help: "PostgreSQL connection pool state",
      labelNames: ["state"],
      registers: [this.registry]
    });

    this.postgresQueries = new Counter({
      name: "bookber_postgres_queries_total",
      help: "Total PostgreSQL queries",
      labelNames: ["operation", "table", "status"],
      registers: [this.registry]
    });

    this.postgresErrors = new Counter({
      name: "bookber_postgres_errors_total",
      help: "Total PostgreSQL errors",
      labelNames: ["error_type"],
      registers: [this.registry]
    });

    // Chair Metrics
    this.chairUtilization = new Gauge({
      name: "bookber_chair_utilization",
      help: "Chair utilization percentage (0-100)",
      labelNames: ["shop_id", "chair_id"],
      registers: [this.registry]
    });

    this.chairState = new Gauge({
      name: "bookber_chair_state",
      help: "Current chair state (0 or 1)",
      labelNames: ["shop_id", "chair_id", "state"],
      registers: [this.registry]
    });

    this.chairServiceTime = new Histogram({
      name: "bookber_chair_service_time_seconds",
      help: "Time spent on service per chair",
      labelNames: ["shop_id", "chair_id", "service_type"],
      buckets: [60, 300, 600, 900, 1200, 1800, 2700, 3600],
      registers: [this.registry]
    });

    // Business Metrics
    this.bookingsCreated = new Counter({
      name: "bookber_bookings_created_total",
      help: "Total bookings created",
      labelNames: ["shop_id", "lane", "service_type"],
      registers: [this.registry]
    });

    this.bookingsCompleted = new Counter({
      name: "bookber_bookings_completed_total",
      help: "Total bookings completed",
      labelNames: ["shop_id", "lane", "service_type"],
      registers: [this.registry]
    });

    this.bookingsCancelled = new Counter({
      name: "bookber_bookings_cancelled_total",
      help: "Total bookings cancelled",
      labelNames: ["shop_id", "lane", "reason"],
      registers: [this.registry]
    });

    this.averageWaitTime = new Gauge({
      name: "bookber_average_wait_time_seconds",
      help: "Current average wait time",
      labelNames: ["shop_id", "lane"],
      registers: [this.registry]
    });

    this.noShows = new Counter({
      name: "bookber_no_shows_total",
      help: "Total no-show bookings",
      labelNames: ["shop_id", "lane"],
      registers: [this.registry]
    });

    // HTTP Metrics
    this.httpRequests = new Counter({
      name: "bookber_http_requests_total",
      help: "Total HTTP requests",
      labelNames: ["method", "route", "status_code"],
      registers: [this.registry]
    });

    this.httpRequestDuration = new Histogram({
      name: "bookber_http_request_duration_seconds",
      help: "HTTP request duration",
      labelNames: ["method", "route", "status_code"],
      buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
      registers: [this.registry]
    });

    this.httpErrors = new Counter({
      name: "bookber_http_errors_total",
      help: "Total HTTP errors",
      labelNames: ["method", "route", "status_code"],
      registers: [this.registry]
    });

    // Apply default labels
    this.registry.setDefaultLabels(this.defaultLabels);
  }

  /**
   * Record queue latency
   */
  recordQueueLatency(shopId: string, lane: QueueLane, operation: string, duration: number): void {
    this.queueLatency.observe({ shop_id: shopId, lane, operation }, duration);
  }

  /**
   * Increment booking throughput
   */
  incrementBookingThroughput(shopId: string, status: string, lane: QueueLane): void {
    this.bookingThroughput.inc({ shop_id: shopId, status, lane });
  }

  /**
   * Set active queues count
   */
  setActiveQueues(shopId: string, lane: QueueLane, count: number): void {
    this.activeQueues.set({ shop_id: shopId, lane }, count);
  }

  /**
   * Set queue size
   */
  setQueueSize(shopId: string, lane: QueueLane, size: number): void {
    this.queueSize.set({ shop_id: shopId, lane }, size);
  }

  /**
   * Set wait time accuracy
   */
  setWaitTimeAccuracy(shopId: string, lane: QueueLane, accuracy: number): void {
    this.waitTimeAccuracy.set({ shop_id: shopId, lane }, accuracy);
  }

  /**
   * Set socket connections count
   */
  setSocketConnections(shopId: string, connectionType: string, count: number): void {
    this.socketConnections.set({ shop_id: shopId, connection_type: connectionType }, count);
  }

  /**
   * Increment socket messages
   */
  incrementSocketMessages(shopId: string, messageType: string, direction: string): void {
    this.socketMessages.inc({ shop_id: shopId, message_type: messageType, direction });
  }

  /**
   * Record socket latency
   */
  recordSocketLatency(shopId: string, messageType: string, duration: number): void {
    this.socketLatency.observe({ shop_id: shopId, message_type: messageType }, duration);
  }

  /**
   * Record Redis latency
   */
  recordRedisLatency(operation: string, command: string, duration: number): void {
    this.redisLatency.observe({ operation, command }, duration);
  }

  /**
   * Set Redis pool connections
   */
  setRedisPoolConnections(state: string, count: number): void {
    this.redisPoolConnections.set({ state }, count);
  }

  /**
   * Increment Redis operations
   */
  incrementRedisOperations(operation: string, status: string): void {
    this.redisOperations.inc({ operation, status });
  }

  /**
   * Increment Redis errors
   */
  incrementRedisErrors(errorType: string): void {
    this.redisErrors.inc({ error_type: errorType });
  }

  /**
   * Record PostgreSQL latency
   */
  recordPostgresLatency(operation: string, table: string, duration: number): void {
    this.postgresLatency.observe({ operation, table }, duration);
  }

  /**
   * Set PostgreSQL connections
   */
  setPostgresConnections(state: string, count: number): void {
    this.postgresConnections.set({ state }, count);
  }

  /**
   * Increment PostgreSQL queries
   */
  incrementPostgresQueries(operation: string, table: string, status: string): void {
    this.postgresQueries.inc({ operation, table, status });
  }

  /**
   * Increment PostgreSQL errors
   */
  incrementPostgresErrors(errorType: string): void {
    this.postgresErrors.inc({ error_type: errorType });
  }

  /**
   * Set chair utilization
   */
  setChairUtilization(shopId: string, chairId: string, utilization: number): void {
    this.chairUtilization.set({ shop_id: shopId, chair_id: chairId }, utilization);
  }

  /**
   * Set chair state
   */
  setChairState(shopId: string, chairId: string, state: string, value: number): void {
    this.chairState.set({ shop_id: shopId, chair_id: chairId, state }, value);
  }

  /**
   * Record chair service time
   */
  recordChairServiceTime(shopId: string, chairId: string, serviceType: string, duration: number): void {
    this.chairServiceTime.observe({ shop_id: shopId, chair_id: chairId, service_type: serviceType }, duration);
  }

  /**
   * Increment bookings created
   */
  incrementBookingsCreated(shopId: string, lane: QueueLane, serviceType: string): void {
    this.bookingsCreated.inc({ shop_id: shopId, lane, service_type: serviceType });
  }

  /**
   * Increment bookings completed
   */
  incrementBookingsCompleted(shopId: string, lane: QueueLane, serviceType: string): void {
    this.bookingsCompleted.inc({ shop_id: shopId, lane, service_type: serviceType });
  }

  /**
   * Increment bookings cancelled
   */
  incrementBookingsCancelled(shopId: string, lane: QueueLane, reason: string): void {
    this.bookingsCancelled.inc({ shop_id: shopId, lane, reason });
  }

  /**
   * Set average wait time
   */
  setAverageWaitTime(shopId: string, lane: QueueLane, waitTime: number): void {
    this.averageWaitTime.set({ shop_id: shopId, lane }, waitTime);
  }

  /**
   * Increment no-shows
   */
  incrementNoShows(shopId: string, lane: QueueLane): void {
    this.noShows.inc({ shop_id: shopId, lane });
  }

  /**
   * Increment HTTP requests
   */
  incrementHttpRequests(method: string, route: string, statusCode: number): void {
    this.httpRequests.inc({ method, route, status_code: statusCode.toString() });
  }

  /**
   * Record HTTP request duration
   */
  recordHttpRequestDuration(method: string, route: string, statusCode: number, duration: number): void {
    this.httpRequestDuration.observe({ method, route, status_code: statusCode.toString() }, duration);
  }

  /**
   * Increment HTTP errors
   */
  incrementHttpErrors(method: string, route: string, statusCode: number): void {
    this.httpErrors.inc({ method, route, status_code: statusCode.toString() });
  }

  /**
   * Get metrics registry
   */
  getRegistry(): Registry {
    return this.registry;
  }

  /**
   * Get metrics in Prometheus format
   */
  async getMetrics(): Promise<string> {
    return await this.registry.metrics();
  }

  /**
   * Reset all metrics
   */
  resetMetrics(): void {
    this.registry.resetMetrics();
  }

  /**
   * Clear all metrics
   */
  clearMetrics(): void {
    this.registry.clear();
  }

  /**
   * Merge metrics from another registry
   */
  mergeRegistry(otherRegistry: Registry): void {
    Registry.merge([this.registry, otherRegistry]);
  }
}

/**
 * Create a singleton Prometheus metrics instance
 */
let metricsInstance: PrometheusMetrics | null = null;

export function getMetrics(defaultLabels?: Record<string, string>): PrometheusMetrics {
  if (!metricsInstance) {
    metricsInstance = new PrometheusMetrics(undefined, defaultLabels);
  }
  return metricsInstance;
}

export function createMetrics(registry?: Registry, defaultLabels?: Record<string, string>): PrometheusMetrics {
  return new PrometheusMetrics(registry, defaultLabels);
}
