import { Registry, Counter, Gauge, Histogram, collectDefaultMetrics } from 'prom-client';
const DEFAULT_PROMETHEUS_CONFIG = {
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
    config;
    registry;
    collectTimer;
    // Queue metrics
    queueLength;
    enqueueTotal;
    dequeueTotal;
    positionUpdateDuration;
    queueWaitTime;
    // Booking metrics
    bookingTotal;
    bookingDuration;
    waitTimeAccuracy;
    bookingConversionRate;
    // Socket metrics
    socketConnections;
    socketMessagesTotal;
    socketDisconnectionsTotal;
    socketLatency;
    // Redis metrics
    redisOperationDuration;
    redisCacheHitRate;
    redisMemoryBytes;
    redisPoolConnections;
    // PostgreSQL metrics
    dbQueryDuration;
    dbPoolConnections;
    dbSlowQueriesTotal;
    dbTransactionDuration;
    constructor(config = {}) {
        this.config = { ...DEFAULT_PROMETHEUS_CONFIG, ...config };
        this.registry = new Registry();
        this.initializeMetrics();
        this.startCollection();
    }
    /**
     * Initialize all metrics
     */
    initializeMetrics() {
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
    startCollection() {
        if (this.config.collectInterval > 0) {
            this.collectTimer = setInterval(async () => {
                await this.collectMetrics();
            }, this.config.collectInterval);
        }
    }
    /**
     * Collect all metrics
     */
    async collectMetrics() {
        // This would be implemented to collect metrics from various sources
        // For now, it's a placeholder for custom collection logic
    }
    /**
     * Stop metrics collection
     */
    stopCollection() {
        if (this.collectTimer) {
            clearInterval(this.collectTimer);
        }
    }
    /**
     * Get metrics registry
     */
    getRegistry() {
        return this.registry;
    }
    /**
     * Get metrics as string
     */
    async getMetrics() {
        return await this.registry.metrics();
    }
    // Queue metrics methods
    /**
     * Record queue length
     */
    recordQueueLength(shopId, lane, length) {
        this.queueLength.set({ shop_id: shopId, lane }, length);
    }
    /**
     * Increment enqueue counter
     */
    incrementEnqueue(shopId, lane, status) {
        this.enqueueTotal.inc({ shop_id: shopId, lane, status });
    }
    /**
     * Increment dequeue counter
     */
    incrementDequeue(shopId, lane, status) {
        this.dequeueTotal.inc({ shop_id: shopId, lane, status });
    }
    /**
     * Record position update duration
     */
    recordPositionUpdateDuration(shopId, lane, duration) {
        this.positionUpdateDuration.observe({ shop_id: shopId, lane }, duration);
    }
    /**
     * Record queue wait time
     */
    recordQueueWaitTime(shopId, lane, waitTime) {
        this.queueWaitTime.observe({ shop_id: shopId, lane }, waitTime);
    }
    // Booking metrics methods
    /**
     * Increment booking counter
     */
    incrementBooking(status, serviceType) {
        this.bookingTotal.inc({ status, service_type: serviceType });
    }
    /**
     * Record booking duration
     */
    recordBookingDuration(stage, duration) {
        this.bookingDuration.observe({ stage }, duration);
    }
    /**
     * Set wait-time accuracy
     */
    setWaitTimeAccuracy(shopId, serviceType, accuracy) {
        this.waitTimeAccuracy.set({ shop_id: shopId, service_type: serviceType }, accuracy);
    }
    /**
     * Set booking conversion rate
     */
    setBookingConversionRate(shopId, rate) {
        this.bookingConversionRate.set({ shop_id: shopId }, rate);
    }
    // Socket metrics methods
    /**
     * Set socket connections
     */
    setSocketConnections(shopId, userId, count) {
        this.socketConnections.set({ shop_id: shopId, user_id: userId }, count);
    }
    /**
     * Increment socket messages
     */
    incrementSocketMessages(direction, type) {
        this.socketMessagesTotal.inc({ direction, type });
    }
    /**
     * Increment socket disconnections
     */
    incrementSocketDisconnections(reason) {
        this.socketDisconnectionsTotal.inc({ reason });
    }
    /**
     * Record socket latency
     */
    recordSocketLatency(shopId, latency) {
        this.socketLatency.observe({ shop_id: shopId }, latency);
    }
    // Redis metrics methods
    /**
     * Record Redis operation duration
     */
    recordRedisOperationDuration(operation, keyType, duration) {
        this.redisOperationDuration.observe({ operation, key_type: keyType }, duration);
    }
    /**
     * Set Redis cache hit rate
     */
    setRedisCacheHitRate(keyType, hitRate) {
        this.redisCacheHitRate.set({ key_type: keyType }, hitRate);
    }
    /**
     * Set Redis memory usage
     */
    setRedisMemoryBytes(keyType, bytes) {
        this.redisMemoryBytes.set({ key_type: keyType }, bytes);
    }
    /**
     * Set Redis pool connections
     */
    setRedisPoolConnections(state, count) {
        this.redisPoolConnections.set({ state }, count);
    }
    // PostgreSQL metrics methods
    /**
     * Record database query duration
     */
    recordDbQueryDuration(operation, table, duration) {
        this.dbQueryDuration.observe({ operation, table }, duration);
    }
    /**
     * Set database pool connections
     */
    setDbPoolConnections(state, count) {
        this.dbPoolConnections.set({ state }, count);
    }
    /**
     * Increment slow queries counter
     */
    incrementSlowQueries(table) {
        this.dbSlowQueriesTotal.inc({ table });
    }
    /**
     * Record transaction duration
     */
    recordTransactionDuration(duration) {
        this.dbTransactionDuration.observe(duration);
    }
    /**
     * Reset all metrics
     */
    resetMetrics() {
        this.registry.resetMetrics();
    }
    /**
     * Clear all metrics
     */
    clearMetrics() {
        this.registry.clear();
        this.initializeMetrics();
    }
    /**
     * Update configuration
     */
    updateConfig(config) {
        this.config = { ...this.config, ...config };
        // Restart collection with new configuration
        this.stopCollection();
        this.startCollection();
    }
    /**
     * Get current configuration
     */
    getConfig() {
        return { ...this.config };
    }
}
/**
 * Create a Prometheus metrics collector instance with default configuration
 */
export function createPrometheusMetricsCollector(config) {
    return new PrometheusMetricsCollector(config);
}
