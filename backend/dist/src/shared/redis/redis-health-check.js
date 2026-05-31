import { EventEmitter } from "node:events";
import { env } from "../config/env.js";
const DEFAULT_HEALTH_CHECK_CONFIG = {
    connectionCheckInterval: 5000,
    memoryCheckInterval: env.REDIS_MEMORY_CHECK_INTERVAL_MS,
    latencyCheckInterval: env.REDIS_LATENCY_CHECK_INTERVAL_MS,
    replicationCheckInterval: env.REDIS_REPLICATION_CHECK_INTERVAL_MS,
    connectionTimeout: env.REDIS_CONNECTION_TIMEOUT_MS,
    memoryThreshold: env.REDIS_MEMORY_THRESHOLD,
    latencyThreshold: env.REDIS_LATENCY_THRESHOLD_MS,
    replicationLagThreshold: env.REDIS_REPLICATION_LAG_THRESHOLD_MS
};
/**
 * Production-grade Redis health check and monitoring service.
 *
 * Features:
 * - Connection health monitoring
 * - Memory usage monitoring
 * - Latency monitoring
 * - Replication health monitoring
 * - Automatic health status aggregation
 * - Event emission for health changes
 */
export class RedisHealthCheck extends EventEmitter {
    config;
    redis;
    connectionTimer;
    memoryTimer;
    latencyTimer;
    replicationTimer;
    currentStatus;
    latencySamples = [];
    constructor(redis, config = {}) {
        super();
        this.redis = redis;
        this.config = { ...DEFAULT_HEALTH_CHECK_CONFIG, ...config };
        this.currentStatus = this.createInitialStatus();
        if (this.redis) {
            this.startHealthChecks();
        }
    }
    /**
     * Create initial health status
     */
    createInitialStatus() {
        return {
            status: 'unhealthy',
            connection: {
                status: 'unhealthy',
                connected: false,
                lastCheck: Date.now()
            },
            memory: {
                status: 'healthy',
                usedMemory: 0,
                maxMemory: 0,
                memoryUsagePercent: 0,
                fragmentationRatio: 0,
                evictionCount: 0,
                lastCheck: Date.now()
            },
            latency: {
                status: 'healthy',
                averageLatency: 0,
                p95Latency: 0,
                p99Latency: 0,
                samples: [],
                lastCheck: Date.now()
            },
            replication: {
                status: 'healthy',
                role: 'unknown',
                connectedSlaves: 0,
                replicationLag: 0,
                masterLinkStatus: 'unknown',
                lastCheck: Date.now()
            },
            timestamp: Date.now()
        };
    }
    /**
     * Start all health checks
     */
    startHealthChecks() {
        this.connectionTimer = setInterval(() => {
            this.checkConnection();
        }, this.config.connectionCheckInterval);
        this.memoryTimer = setInterval(() => {
            this.checkMemory();
        }, this.config.memoryCheckInterval);
        this.latencyTimer = setInterval(() => {
            this.checkLatency();
        }, this.config.latencyCheckInterval);
        this.replicationTimer = setInterval(() => {
            this.checkReplication();
        }, this.config.replicationCheckInterval);
    }
    /**
     * Stop all health checks
     */
    stopHealthChecks() {
        if (this.connectionTimer) {
            clearInterval(this.connectionTimer);
        }
        if (this.memoryTimer) {
            clearInterval(this.memoryTimer);
        }
        if (this.latencyTimer) {
            clearInterval(this.latencyTimer);
        }
        if (this.replicationTimer) {
            clearInterval(this.replicationTimer);
        }
    }
    /**
     * Check connection health
     */
    async checkConnection() {
        if (!this.redis) {
            const health = {
                status: 'unhealthy',
                connected: false,
                lastCheck: Date.now(),
                error: 'Redis client not available'
            };
            this.currentStatus.connection = health;
            this.emitStatusChange();
            return health;
        }
        try {
            const startTime = Date.now();
            await this.redis.ping();
            const latency = Date.now() - startTime;
            const health = {
                status: 'healthy',
                connected: true,
                lastCheck: Date.now()
            };
            this.currentStatus.connection = health;
            this.emitStatusChange();
            return health;
        }
        catch (error) {
            const health = {
                status: 'unhealthy',
                connected: false,
                lastCheck: Date.now(),
                error: error instanceof Error ? error.message : String(error)
            };
            this.currentStatus.connection = health;
            this.emitStatusChange();
            return health;
        }
    }
    /**
     * Check memory health
     */
    async checkMemory() {
        if (!this.redis) {
            return this.currentStatus.memory;
        }
        try {
            const info = await this.redis.info('memory');
            const memoryInfo = this.parseRedisInfo(info);
            const usedMemory = this.parseNumericValue(memoryInfo['used_memory'], 0);
            const maxMemory = this.parseNumericValue(memoryInfo['maxmemory'], 0);
            const memoryUsagePercent = maxMemory > 0 ? (usedMemory / maxMemory) * 100 : 0;
            const fragmentationRatio = this.parseNumericValue(memoryInfo['mem_fragmentation_ratio'], 1);
            const evictionCount = this.parseNumericValue(memoryInfo['evicted_keys'], 0);
            let status = 'healthy';
            if (memoryUsagePercent > this.config.memoryThreshold) {
                status = 'critical';
            }
            else if (memoryUsagePercent > this.config.memoryThreshold * 0.8) {
                status = 'warning';
            }
            const health = {
                status,
                usedMemory,
                maxMemory,
                memoryUsagePercent,
                fragmentationRatio,
                evictionCount,
                lastCheck: Date.now()
            };
            this.currentStatus.memory = health;
            this.emitStatusChange();
            return health;
        }
        catch (error) {
            console.error('Error checking memory health:', error);
            return this.currentStatus.memory;
        }
    }
    /**
     * Check latency health
     */
    async checkLatency() {
        if (!this.redis) {
            return this.currentStatus.latency;
        }
        try {
            const startTime = Date.now();
            await this.redis.ping();
            const latency = Date.now() - startTime;
            this.latencySamples.push(latency);
            // Keep only last 100 samples
            if (this.latencySamples.length > 100) {
                this.latencySamples.shift();
            }
            const sorted = [...this.latencySamples].sort((a, b) => a - b);
            const averageLatency = sorted.reduce((sum, val) => sum + val, 0) / sorted.length;
            const p95Latency = sorted[Math.floor(sorted.length * 0.95)] ?? 0;
            const p99Latency = sorted[Math.floor(sorted.length * 0.99)] ?? 0;
            let status = 'healthy';
            if (averageLatency > this.config.latencyThreshold) {
                status = 'unhealthy';
            }
            else if (averageLatency > this.config.latencyThreshold * 0.7) {
                status = 'degraded';
            }
            const health = {
                status,
                averageLatency,
                p95Latency,
                p99Latency,
                samples: [...this.latencySamples],
                lastCheck: Date.now()
            };
            this.currentStatus.latency = health;
            this.emitStatusChange();
            return health;
        }
        catch (error) {
            console.error('Error checking latency health:', error);
            return this.currentStatus.latency;
        }
    }
    /**
     * Check replication health
     */
    async checkReplication() {
        if (!this.redis) {
            return this.currentStatus.replication;
        }
        try {
            const info = await this.redis.info('replication');
            const replicationInfo = this.parseRedisInfo(info);
            const role = replicationInfo['role'] === 'master' ? 'master' :
                replicationInfo['role'] === 'slave' ? 'slave' : 'unknown';
            const connectedSlaves = this.parseNumericValue(replicationInfo['connected_slaves'], 0);
            const masterLinkStatus = replicationInfo['master_link_status'] || 'unknown';
            const replicationLag = this.parseNumericValue(replicationInfo['master_link_down_since_seconds'], 0) * 1000;
            let status = 'healthy';
            if (replicationLag > this.config.replicationLagThreshold) {
                status = 'unhealthy';
            }
            else if (replicationLag > this.config.replicationLagThreshold * 0.7) {
                status = 'degraded';
            }
            const health = {
                status,
                role,
                connectedSlaves,
                replicationLag,
                masterLinkStatus,
                lastCheck: Date.now()
            };
            this.currentStatus.replication = health;
            this.emitStatusChange();
            return health;
        }
        catch (error) {
            console.error('Error checking replication health:', error);
            return this.currentStatus.replication;
        }
    }
    /**
     * Parse Redis INFO output
     */
    parseRedisInfo(info) {
        const result = {};
        const lines = info.split('\r\n');
        for (const line of lines) {
            if (line.startsWith('#') || line.trim() === '') {
                continue;
            }
            const parts = line.split(':');
            if (parts.length === 2 && parts[0] && parts[1] !== undefined) {
                result[parts[0]] = parts[1];
            }
        }
        return result;
    }
    /**
     * Parse numeric value from Redis info
     */
    parseNumericValue(value, fallback) {
        if (value === undefined || value === '') {
            return fallback;
        }
        const parsed = Number.parseFloat(value);
        return Number.isFinite(parsed) ? parsed : fallback;
    }
    /**
     * Aggregate health status from all checks
     */
    aggregateStatus() {
        const { connection, memory, latency, replication } = this.currentStatus;
        // Connection is critical
        if (connection.status === 'unhealthy') {
            return 'unhealthy';
        }
        // Memory critical status
        if (memory.status === 'critical') {
            return 'unhealthy';
        }
        // Latency unhealthy status
        if (latency.status === 'unhealthy') {
            return 'unhealthy';
        }
        // Replication unhealthy status
        if (replication.status === 'unhealthy') {
            return 'unhealthy';
        }
        // Any degraded status
        if (memory.status === 'warning' || latency.status === 'degraded' || replication.status === 'degraded') {
            return 'degraded';
        }
        return 'healthy';
    }
    /**
     * Emit status change if status has changed
     */
    emitStatusChange() {
        const newStatus = this.aggregateStatus();
        this.currentStatus.status = newStatus;
        this.currentStatus.timestamp = Date.now();
        this.emit('healthStatusChange', this.currentStatus);
    }
    /**
     * Get current health status
     */
    getHealthStatus() {
        return { ...this.currentStatus };
    }
    /**
     * Run all health checks once
     */
    async runAllChecks() {
        const [connection, memory, latency, replication] = await Promise.all([
            this.checkConnection(),
            this.checkMemory(),
            this.checkLatency(),
            this.checkReplication()
        ]);
        this.currentStatus = {
            status: this.aggregateStatus(),
            connection,
            memory,
            latency,
            replication,
            timestamp: Date.now()
        };
        return this.currentStatus;
    }
    /**
     * Update health check configuration
     */
    updateConfig(config) {
        this.config = { ...this.config, ...config };
        // Restart health checks with new configuration
        this.stopHealthChecks();
        if (this.redis) {
            this.startHealthChecks();
        }
    }
    /**
     * Get current configuration
     */
    getConfig() {
        return { ...this.config };
    }
}
/**
 * Create a Redis health check instance with default configuration
 */
export function createRedisHealthCheck(redis, config) {
    return new RedisHealthCheck(redis, config);
}
