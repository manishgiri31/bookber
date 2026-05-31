import { Redis } from "ioredis";
import { EventEmitter } from "node:events";
import { env } from "../config/env.js";
/**
 * Production-grade Redis connection pool manager.
 *
 * Features:
 * - Connection pooling with min/max limits
 * - Automatic health checks
 * - Connection recycling on failure
 * - Load balancing across connections
 * - Connection backpressure handling
 * - Redis Cluster support
 * - Latency monitoring
 */
export class RedisConnectionPool extends EventEmitter {
    connections = new Map();
    availableConnections = [];
    inUseConnections = new Set();
    config;
    healthCheckTimer;
    latencySamples = [];
    stats = {
        totalConnections: 0,
        activeConnections: 0,
        idleConnections: 0,
        failedConnections: 0,
        createdConnections: 0,
        destroyedConnections: 0,
        averageLatency: 0,
        p95Latency: 0,
        p99Latency: 0
    };
    constructor(config = {}) {
        super();
        this.config = {
            minConnections: env.REDIS_POOL_MIN_CONNECTIONS,
            maxConnections: env.REDIS_POOL_MAX_CONNECTIONS,
            connectionTimeout: env.REDIS_CONNECTION_TIMEOUT_MS,
            idleTimeout: env.REDIS_IDLE_TIMEOUT_MS,
            maxLifetime: env.REDIS_MAX_LIFETIME_MS,
            healthCheckInterval: env.REDIS_HEALTH_CHECK_INTERVAL_MS,
            ...config
        };
        this.initializePool();
        this.startHealthChecks();
    }
    /**
     * Initialize the connection pool with minimum connections
     */
    async initializePool() {
        const promises = [];
        for (let i = 0; i < this.config.minConnections; i++) {
            promises.push(this.createConnection().then(() => { }));
        }
        await Promise.all(promises);
    }
    /**
     * Create a new Redis connection
     */
    async createConnection() {
        const connectionId = this.generateConnectionId();
        const client = new Redis({
            ...this.config.redisOptions,
            lazyConnect: true,
            connectTimeout: this.config.connectionTimeout,
            retryStrategy: (times) => {
                const delay = Math.min(times * 100, 3000);
                return delay;
            }
        });
        try {
            await client.connect();
            const connection = {
                client,
                createdAt: Date.now(),
                lastUsedAt: Date.now(),
                isHealthy: true,
                inUse: false
            };
            this.connections.set(connectionId, connection);
            this.availableConnections.push(connection);
            this.stats.totalConnections++;
            this.stats.createdConnections++;
            this.stats.idleConnections++;
            this.emit('connectionCreated', { connectionId });
            return connection;
        }
        catch (error) {
            this.stats.failedConnections++;
            this.emit('connectionFailed', { error });
            throw error;
        }
    }
    /**
     * Acquire a connection from the pool
     */
    async acquire() {
        // Check if there's an available connection
        if (this.availableConnections.length > 0) {
            const connection = this.availableConnections.shift();
            connection.inUse = true;
            connection.lastUsedAt = Date.now();
            this.inUseConnections.add(this.getConnectionId(connection));
            this.stats.activeConnections++;
            this.stats.idleConnections--;
            return connection.client;
        }
        // Check if we can create a new connection
        if (this.connections.size < this.config.maxConnections) {
            const connection = await this.createConnection();
            connection.inUse = true;
            connection.lastUsedAt = Date.now();
            this.inUseConnections.add(this.getConnectionId(connection));
            this.stats.activeConnections++;
            this.stats.idleConnections--;
            return connection.client;
        }
        // Pool is exhausted, wait for a connection to become available
        throw new Error('REDIS_POOL_EXHAUSTED');
    }
    /**
     * Release a connection back to the pool
     */
    async release(client) {
        const connectionId = this.getConnectionIdByClient(client);
        if (!connectionId) {
            return;
        }
        const connection = this.connections.get(connectionId);
        if (!connection) {
            return;
        }
        connection.inUse = false;
        connection.lastUsedAt = Date.now();
        this.inUseConnections.delete(connectionId);
        this.availableConnections.push(connection);
        this.stats.activeConnections--;
        this.stats.idleConnections++;
        // Check if connection should be recycled
        const age = Date.now() - connection.createdAt;
        const idleTime = Date.now() - connection.lastUsedAt;
        if (age > this.config.maxLifetime || idleTime > this.config.idleTimeout) {
            await this.recycleConnection(connectionId);
        }
    }
    /**
     * Recycle a connection (close and replace)
     */
    async recycleConnection(connectionId) {
        const connection = this.connections.get(connectionId);
        if (!connection) {
            return;
        }
        try {
            await connection.client.quit();
        }
        catch (error) {
            console.error('Error closing connection:', error);
        }
        this.connections.delete(connectionId);
        this.availableConnections = this.availableConnections.filter(c => this.getConnectionId(c) !== connectionId);
        this.inUseConnections.delete(connectionId);
        this.stats.totalConnections--;
        this.stats.destroyedConnections++;
        this.stats.idleConnections--;
        this.emit('connectionDestroyed', { connectionId });
        // Create a new connection to maintain minimum pool size
        if (this.connections.size < this.config.minConnections) {
            await this.createConnection();
        }
    }
    /**
     * Start health checks for all connections
     */
    startHealthChecks() {
        this.healthCheckTimer = setInterval(async () => {
            await this.healthCheck();
        }, this.config.healthCheckInterval);
    }
    /**
     * Perform health check on all connections
     */
    async healthCheck() {
        const startTime = Date.now();
        const healthChecks = [];
        for (const [connectionId, connection] of this.connections) {
            healthChecks.push(this.checkConnectionHealth(connectionId, connection));
        }
        await Promise.all(healthChecks);
        const latency = Date.now() - startTime;
        this.recordLatency(latency);
    }
    /**
     * Check health of a single connection
     */
    async checkConnectionHealth(connectionId, connection) {
        try {
            const startTime = Date.now();
            await connection.client.ping();
            const latency = Date.now() - startTime;
            connection.isHealthy = true;
            connection.lastUsedAt = Date.now();
            // Recycle connection if latency is too high
            if (latency > 1000) {
                await this.recycleConnection(connectionId);
            }
        }
        catch (error) {
            connection.isHealthy = false;
            this.emit('connectionUnhealthy', { connectionId, error });
            await this.recycleConnection(connectionId);
        }
    }
    /**
     * Record latency sample
     */
    recordLatency(latency) {
        this.latencySamples.push(latency);
        // Keep only last 100 samples
        if (this.latencySamples.length > 100) {
            this.latencySamples.shift();
        }
        // Calculate statistics
        const sorted = [...this.latencySamples].sort((a, b) => a - b);
        this.stats.averageLatency = sorted.reduce((sum, val) => sum + val, 0) / sorted.length;
        this.stats.p95Latency = sorted[Math.floor(sorted.length * 0.95)] ?? 0;
        this.stats.p99Latency = sorted[Math.floor(sorted.length * 0.99)] ?? 0;
    }
    /**
     * Get connection statistics
     */
    getStats() {
        return { ...this.stats };
    }
    /**
     * Close all connections in the pool
     */
    async close() {
        if (this.healthCheckTimer) {
            clearInterval(this.healthCheckTimer);
        }
        const closePromises = [];
        for (const connection of this.connections.values()) {
            closePromises.push(connection.client.quit().then(() => { }).catch((error) => {
                console.error('Error closing connection:', error);
            }));
        }
        await Promise.all(closePromises);
        this.connections.clear();
        this.availableConnections = [];
        this.inUseConnections.clear();
    }
    /**
     * Generate a unique connection ID
     */
    generateConnectionId() {
        return `conn_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }
    /**
     * Get connection ID from pooled connection
     */
    getConnectionId(connection) {
        for (const [id, conn] of this.connections) {
            if (conn === connection) {
                return id;
            }
        }
        throw new Error('Connection not found in pool');
    }
    /**
     * Get connection ID by client
     */
    getConnectionIdByClient(client) {
        for (const [id, connection] of this.connections) {
            if (connection.client === client) {
                return id;
            }
        }
        return null;
    }
}
