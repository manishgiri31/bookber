import { Registry, Counter, Gauge, Histogram, Summary, collectDefaultMetrics } from 'prom-client';
import type { QueueLane } from '@prisma/client';

export interface PrometheusConfig {
  enabled: boolean;
  port: number;
  path: string;
  collectDefaultMetrics: boolean;
  collectInterval: number;
  defaultLabels: Record<string, string>;
}

const DEFAULT_PROMETHEUS_CONFIG: PrometheusConfig = {
  enabled: true,
  port: 9090,
  path: '/metrics',
  collectDefaultMetrics: true,
  collectInterval: 15000,
  defaultLabels: {
    service: 'bookber-api',
    environment: process.env['NODE_ENV'] || 'development'
  }
};

/**
 * Production-grade Prometheus metrics collector for BookBer.
 * 
 * Features:
 * - Counter, Gauge, Histogram, Summary metrics
 * - Queue metrics (length, enqueue/dequeue rate, latency)
 * - Booking metrics (throughput, latency, wait-time accuracy)
 * - Socket metrics (connections, message rate, latency)
 * - Redis metrics (latency, hit rate, memory, pool stats)
 * - PostgreSQL metrics (query latency, pool stats, slow queries)
 * - Default metrics collection
 * - Custom label support
 */
export class PrometheusMetricsCollector {
  private config: PrometheusConfig;
  private registry: Registry;
  private collectTimer?: NodeJS.Timeout;

  // Queue metrics
  private queueLength!: Gauge;
  private enqueueTotal!: Counter;
  private dequeueTotal!: Counter;
  private positionUpdateDuration!: Histogram;
  private queueWaitTime!: Histogram;

  // Booking metrics
  private bookingTotal!: Counter;
  private bookingDuration!: Histogram;
  private waitTimeAccuracy!: Gauge;
  private bookingConversionRate!: Gauge;

  // Socket metrics
  private socketConnections!: Gauge;
  private socketMessagesTotal!: Counter;
  private socketDisconnectionsTotal!: Counter;
  private socketLatency!: Histogram;

  // Redis metrics
  private redisOperationDuration!: Histogram;
  private redisCacheHitRate!: Gauge;
  private redisMemoryBytes!: Gauge;
  private redisPoolConnections!: Gauge;

  // PostgreSQL metrics
  private dbQueryDuration!: Histogram;
  private dbPoolConnections!: Gauge;
  private dbSlowQueriesTotal!: Counter;
  private dbTransactionDuration!: Histogram;

  constructor(config: Partial<PrometheusConfig> = {}) {
    this.config = { ...DEFAULT_PROMETHEUS_CONFIG, ...config };
    this.registry = new Registry();

    this.initializeMetrics();
    this.startCollection();
  }

  /**
   * Initialize all metrics
   */
  private initializeMetrics(): void {
    // Apply default labels
    this.registry.setDefaultLabels(this.config.defaultLabels);

    // Collect default metrics
    if (this.config.collectDefaultMetrics) {
      collectDefaultMetrics({ register: this.registry });
    }

    // Queue metrics
    this.queueLength = new Gauge({
      name: 'bookber_queue_length',
      help: 'Current queue length per shop and lane',
      labelNames: ['shop_id', 'lane'],
      registers: [this.registry]
    });

    this.enqueueTotal = new Counter({
      name: 'bookber_enqueue_total',
      help: 'Total number of enqueues',
      labelNames: ['shop_id', 'lane', 'status'],
      registers: [this.registry]
    });

    this.dequeueTotal = new Counter({
      name: 'bookber_dequeue_total',
      help: 'Total number of dequeues',
      labelNames: ['shop_id', 'lane', 'status'],
      registers: [this.registry]
    });

    this.positionUpdateDuration = new Histogram({
      name: 'bookber_position_update_duration_seconds',
      help: 'Duration of position update operations',
      labelNames: ['shop_id', 'lane'],
      buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
      registers: [this.registry]
    });

    this.queueWaitTime = new Histogram({
      name: 'bookber_queue_wait_seconds',
      help: 'Queue wait time distribution',
      labelNames: ['shop_id', 'lane'],
      buckets: [60, 120, 300, 600, 900, 1200, 1800, 2700, 3600],
      registers: [this.registry]
    });

    // Booking metrics
    this.bookingTotal = new Counter({
      name: 'bookber_booking_total',
      help: 'Total number of bookings',
      labelNames: ['status', 'service_type'],
      registers: [this.registry]
    });

    this.bookingDuration = new Histogram({
      name: 'bookber_booking_duration_seconds',
      help: 'Duration of booking operations',
      labelNames: ['stage'],
      buckets: [0.1, 0.5, 1, 2, 5, 10, 30, 60],
      registers: [this.registry]
    });

    this.waitTimeAccuracy = new Gauge({
      name: 'bookber_wait_time_accuracy',
      help: 'Wait-time accuracy percentage',
      labelNames: ['shop_id', 'service_type'],
      registers: [this.registry]
    });

    this.bookingConversionRate = new Gauge({
      name: 'bookber_booking_conversion_rate',
      help: 'Booking conversion rate',
      labelNames: ['shop_id'],
      registers: [this.registry]
    });

    // Socket metrics
    this.socketConnections = new Gauge({
      name: 'bookber_socket_connections',
      help: 'Current number of active socket connections',
      labelNames: ['shop_id', 'user_id'],
      registers: [this.registry]
    });

    this.socketMessagesTotal = new Counter({
      name: 'bookber_socket_messages_total',
      help: 'Total number of socket messages',
      labelNames: ['direction', 'type'],
      registers: [this.registry]
    });

    this.socketDisconnectionsTotal = new Counter({
      name: 'bookber_socket_disconnections_total',
      help: 'Total number of socket disconnections',
      labelNames: ['reason'],
      registers: [this.registry]
    });

    this.socketLatency = new Histogram({
      name: 'bookber_socket_latency_seconds',
      help: 'Socket message latency',
      labelNames: ['shop_id'],
      buckets: [0.001, 0.01, 0.05, 0.1, 0.5, 1],
      registers: [this.registry]
    });

    // Redis metrics
    this.redisOperationDuration = new Histogram({
      name: 'bookber_redis_operation_duration_seconds',
      help: 'Duration of Redis operations',
      labelNames: ['operation', 'key_type'],
      buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1],
      registers: [this.registry]
    });

    this.redisCacheHitRate = new Gauge({
      name: 'bookber_redis_cache_hit_rate',
      help: 'Redis cache hit rate',
      labelNames: ['key_type'],
      registers: [this.registry]
    });

    this.redisMemoryBytes = new Gauge({
      name: 'bookber_redis_memory_bytes',
      help: 'Redis memory usage',
      labelNames: ['key_type'],
      registers: [this.registry]
    });

    this.redisPoolConnections = new Gauge({
      name: 'bookber_redis_pool_connections',
      help: 'Redis connection pool connections',
      labelNames: ['state'],
      registers: [this.registry]
    });

    // PostgreSQL metrics
    this.dbQueryDuration = new Histogram({
      name: 'bookber_db_query_duration_seconds',
      help: 'Duration of database queries',
      labelNames: ['operation', 'table'],
      buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
      registers: [this.registry]
    });

    this.dbPoolConnections = new Gauge({
      name: 'bookber_db_pool_connections',
      help: 'Database connection pool connections',
      labelNames: ['state'],
      registers: [this.registry]
    });

    this.dbSlowQueriesTotal = new Counter({
      name: 'bookber_db_slow_queries_total',
      help: 'Total number of slow database queries',
      labelNames: ['table'],
      registers: [this.registry]
    });

    this.dbTransactionDuration = new Histogram({
      name: 'bookber_db_transaction_duration_seconds',
      help: 'Duration of database transactions',
      buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
      registers: [this.registry]
    });
  }

  /**
   * Start metrics collection
   */
  private startCollection(): void {
    if (this.config.collectInterval > 0) {
      this.collectTimer = setInterval(async () => {
        await this.collectMetrics();
      }, this.config.collectInterval);
    }
  }

  /**
   * Collect all metrics
   */
  private async collectMetrics(): Promise<void> {
    // This would be implemented to collect metrics from various sources
    // For now, it's a placeholder for custom collection logic
  }

  /**
   * Stop metrics collection
   */
  stopCollection(): void {
    if (this.collectTimer) {
      clearInterval(this.collectTimer);
    }
  }

  /**
   * Get metrics registry
   */
  getRegistry(): Registry {
    return this.registry;
  }

  /**
   * Get metrics as string
   */
  async getMetrics(): Promise<string> {
    return await this.registry.metrics();
  }

  // Queue metrics methods

  /**
   * Record queue length
   */
  recordQueueLength(shopId: string, lane: QueueLane, length: number): void {
    this.queueLength.set({ shop_id: shopId, lane }, length);
  }

  /**
   * Increment enqueue counter
   */
  incrementEnqueue(shopId: string, lane: QueueLane, status: 'success' | 'error'): void {
    this.enqueueTotal.inc({ shop_id: shopId, lane, status });
  }

  /**
   * Increment dequeue counter
   */
  incrementDequeue(shopId: string, lane: QueueLane, status: 'success' | 'error'): void {
    this.dequeueTotal.inc({ shop_id: shopId, lane, status });
  }

  /**
   * Record position update duration
   */
  recordPositionUpdateDuration(shopId: string, lane: QueueLane, duration: number): void {
    this.positionUpdateDuration.observe({ shop_id: shopId, lane }, duration);
  }

  /**
   * Record queue wait time
   */
  recordQueueWaitTime(shopId: string, lane: QueueLane, waitTime: number): void {
    this.queueWaitTime.observe({ shop_id: shopId, lane }, waitTime);
  }

  // Booking metrics methods

  /**
   * Increment booking counter
   */
  incrementBooking(status: string, serviceType: string): void {
    this.bookingTotal.inc({ status, service_type: serviceType });
  }

  /**
   * Record booking duration
   */
  recordBookingDuration(stage: string, duration: number): void {
    this.bookingDuration.observe({ stage }, duration);
  }

  /**
   * Set wait-time accuracy
   */
  setWaitTimeAccuracy(shopId: string, serviceType: string, accuracy: number): void {
    this.waitTimeAccuracy.set({ shop_id: shopId, service_type: serviceType }, accuracy);
  }

  /**
   * Set booking conversion rate
   */
  setBookingConversionRate(shopId: string, rate: number): void {
    this.bookingConversionRate.set({ shop_id: shopId }, rate);
  }

  // Socket metrics methods

  /**
   * Set socket connections
   */
  setSocketConnections(shopId: string, userId: string, count: number): void {
    this.socketConnections.set({ shop_id: shopId, user_id: userId }, count);
  }

  /**
   * Increment socket messages
   */
  incrementSocketMessages(direction: 'in' | 'out', type: string): void {
    this.socketMessagesTotal.inc({ direction, type });
  }

  /**
   * Increment socket disconnections
   */
  incrementSocketDisconnections(reason: string): void {
    this.socketDisconnectionsTotal.inc({ reason });
  }

  /**
   * Record socket latency
   */
  recordSocketLatency(shopId: string, latency: number): void {
    this.socketLatency.observe({ shop_id: shopId }, latency);
  }

  // Redis metrics methods

  /**
   * Record Redis operation duration
   */
  recordRedisOperationDuration(operation: string, keyType: string, duration: number): void {
    this.redisOperationDuration.observe({ operation, key_type: keyType }, duration);
  }

  /**
   * Set Redis cache hit rate
   */
  setRedisCacheHitRate(keyType: string, hitRate: number): void {
    this.redisCacheHitRate.set({ key_type: keyType }, hitRate);
  }

  /**
   * Set Redis memory usage
   */
  setRedisMemoryBytes(keyType: string, bytes: number): void {
    this.redisMemoryBytes.set({ key_type: keyType }, bytes);
  }

  /**
   * Set Redis pool connections
   */
  setRedisPoolConnections(state: string, count: number): void {
    this.redisPoolConnections.set({ state }, count);
  }

  // PostgreSQL metrics methods

  /**
   * Record database query duration
   */
  recordDbQueryDuration(operation: string, table: string, duration: number): void {
    this.dbQueryDuration.observe({ operation, table }, duration);
  }

  /**
   * Set database pool connections
   */
  setDbPoolConnections(state: string, count: number): void {
    this.dbPoolConnections.set({ state }, count);
  }

  /**
   * Increment slow queries counter
   */
  incrementSlowQueries(table: string): void {
    this.dbSlowQueriesTotal.inc({ table });
  }

  /**
   * Record transaction duration
   */
  recordTransactionDuration(duration: number): void {
    this.dbTransactionDuration.observe(duration);
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
    this.initializeMetrics();
  }

  /**
   * Update configuration
   */
  updateConfig(config: Partial<PrometheusConfig>): void {
    this.config = { ...this.config, ...config };

    // Restart collection with new configuration
    this.stopCollection();
    this.startCollection();
  }

  /**
   * Get current configuration
   */
  getConfig(): PrometheusConfig {
    return { ...this.config };
  }
}

/**
 * Create a Prometheus metrics collector instance with default configuration
 */
export function createPrometheusMetricsCollector(config?: Partial<PrometheusConfig>): PrometheusMetricsCollector {
  return new PrometheusMetricsCollector(config);
}
