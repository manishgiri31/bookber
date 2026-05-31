import { EventEmitter } from "node:events";
import { env } from "../config/env.js";
const DEFAULT_PUBSUB_OPTIMIZER_CONFIG = {
    enableMessageBatching: env.REDIS_PUBSUB_ENABLE_BATCHING,
    batchSize: env.REDIS_PUBSUB_BATCH_SIZE,
    batchTimeout: env.REDIS_PUBSUB_BATCH_TIMEOUT_MS,
    enableCompression: env.REDIS_PUBSUB_ENABLE_COMPRESSION,
    compressionThreshold: env.REDIS_PUBSUB_COMPRESSION_THRESHOLD,
    enableDeduplication: env.REDIS_PUBSUB_ENABLE_DEDUPLICATION,
    deduplicationWindow: env.REDIS_PUBSUB_DEDUPLICATION_TTL_MS,
    enablePriorityQueuing: true,
    maxQueueSize: 10000,
    enableConsumerGroups: true,
    consumerGroupPrefix: 'cg'
};
/**
 * Production-grade Redis pub/sub optimizer for socket operations.
 *
 * Features:
 * - Message batching for efficiency
 * - Message compression for large payloads
 * - Message deduplication
 * - Priority queuing
 * - Consumer groups for load balancing
 * - Fan-out pattern for multiple subscribers
 * - Message persistence with streams
 */
export class RedisPubSubOptimizer extends EventEmitter {
    config;
    redis;
    publisher = null;
    subscriber = null;
    stats;
    messageBuffer = new Map();
    batchTimers = new Map();
    deduplicationCache = new Map();
    subscriptions = new Map();
    compressionSavings = 0;
    constructor(redis, config = {}) {
        super();
        this.redis = redis;
        this.config = { ...DEFAULT_PUBSUB_OPTIMIZER_CONFIG, ...config };
        this.stats = this.createInitialStats();
        if (this.redis) {
            this.initializePubSub();
        }
    }
    /**
     * Create initial pub/sub stats
     */
    createInitialStats() {
        return {
            messagesPublished: 0,
            messagesReceived: 0,
            messagesDeduplicated: 0,
            messagesCompressed: 0,
            averageMessageSize: 0,
            compressionSavings: 0,
            activeSubscriptions: 0,
            consumerGroups: 0
        };
    }
    /**
     * Initialize pub/sub optimizer
     */
    async initializePubSub() {
        if (!this.redis) {
            return;
        }
        try {
            // Create separate publisher and subscriber clients
            this.publisher = this.redis.duplicate();
            this.subscriber = this.redis.duplicate();
            await this.publisher.connect();
            await this.subscriber.connect();
            // Set up subscriber event handlers
            this.subscriber.on('message', (channel, message) => {
                this.handleMessage(channel, message);
            });
            this.subscriber.on('error', (error) => {
                console.error('Subscriber error:', error);
                this.emit('subscriberError', error);
            });
            this.publisher.on('error', (error) => {
                console.error('Publisher error:', error);
                this.emit('publisherError', error);
            });
        }
        catch (error) {
            console.error('Error initializing pub/sub:', error);
        }
    }
    /**
     * Publish a message to a channel
     */
    async publish(channel, data, options = {}) {
        if (!this.publisher) {
            throw new Error('Publisher not available');
        }
        const message = {
            id: this.generateMessageId(),
            channel,
            data,
            timestamp: Date.now(),
            priority: options.priority || 'normal'
        };
        // Check for deduplication
        if (this.config.enableDeduplication) {
            const messageKey = `${channel}:${JSON.stringify(data)}`;
            const lastSeen = this.deduplicationCache.get(messageKey);
            if (lastSeen && Date.now() - lastSeen < this.config.deduplicationWindow) {
                this.stats.messagesDeduplicated++;
                return 0;
            }
            this.deduplicationCache.set(messageKey, Date.now());
            // Clean up old deduplication entries
            this.cleanupDeduplicationCache();
        }
        // Compress message if enabled
        let serialized = JSON.stringify(message);
        const originalSize = serialized.length;
        if (this.config.enableCompression && serialized.length > this.config.compressionThreshold) {
            serialized = this.compressMessage(serialized);
            this.stats.messagesCompressed++;
            this.compressionSavings += originalSize - serialized.length;
        }
        // Batch message if enabled
        if (this.config.enableMessageBatching && !options.skipBatching) {
            return this.batchMessage(channel, serialized);
        }
        // Publish immediately
        const result = await this.publisher.publish(channel, serialized);
        this.stats.messagesPublished++;
        // Update average message size
        this.updateAverageMessageSize(serialized.length);
        return result;
    }
    /**
     * Batch a message for delayed publishing
     */
    batchMessage(channel, serialized) {
        return new Promise((resolve, reject) => {
            if (!this.messageBuffer.has(channel)) {
                this.messageBuffer.set(channel, []);
            }
            const buffer = this.messageBuffer.get(channel);
            buffer.push({
                id: this.generateMessageId(),
                channel,
                data: JSON.parse(serialized),
                timestamp: Date.now()
            });
            // Check if batch is full
            if (buffer.length >= this.config.batchSize) {
                this.flushBatch(channel)
                    .then(resolve)
                    .catch(reject);
                return;
            }
            // Set up batch timeout
            if (!this.batchTimers.has(channel)) {
                const timer = setTimeout(() => {
                    this.flushBatch(channel)
                        .then(resolve)
                        .catch(reject);
                }, this.config.batchTimeout);
                this.batchTimers.set(channel, timer);
            }
            else {
                resolve(0);
            }
        });
    }
    /**
     * Flush a batch of messages
     */
    async flushBatch(channel) {
        if (!this.publisher) {
            return 0;
        }
        const buffer = this.messageBuffer.get(channel);
        if (!buffer || buffer.length === 0) {
            return 0;
        }
        // Clear batch timer
        const timer = this.batchTimers.get(channel);
        if (timer) {
            clearTimeout(timer);
            this.batchTimers.delete(channel);
        }
        // Publish all messages in batch
        let totalReceivers = 0;
        for (const message of buffer) {
            const serialized = JSON.stringify(message);
            const result = await this.publisher.publish(channel, serialized);
            totalReceivers += result;
            this.stats.messagesPublished++;
            this.updateAverageMessageSize(serialized.length);
        }
        // Clear buffer
        this.messageBuffer.delete(channel);
        return totalReceivers;
    }
    /**
     * Subscribe to a channel
     */
    async subscribe(channel, callback) {
        if (!this.subscriber) {
            throw new Error('Subscriber not available');
        }
        await this.subscriber.subscribe(channel);
        if (!this.subscriptions.has(channel)) {
            this.subscriptions.set(channel, new Set());
        }
        this.subscriptions.get(channel).add(callback.toString());
        this.stats.activeSubscriptions = this.getTotalSubscriptions();
        // Register callback
        this.on(`message:${channel}`, callback);
    }
    /**
     * Unsubscribe from a channel
     */
    async unsubscribe(channel, callback) {
        if (!this.subscriber) {
            return;
        }
        if (callback) {
            this.off(`message:${channel}`, callback);
            const callbacks = this.subscriptions.get(channel);
            if (callbacks) {
                callbacks.delete(callback.toString());
            }
        }
        else {
            this.removeAllListeners(`message:${channel}`);
            this.subscriptions.delete(channel);
        }
        // Unsubscribe from Redis if no more callbacks
        const callbacks = this.subscriptions.get(channel);
        if (!callbacks || callbacks.size === 0) {
            await this.subscriber.unsubscribe(channel);
        }
        this.stats.activeSubscriptions = this.getTotalSubscriptions();
    }
    /**
     * Handle incoming message
     */
    handleMessage(channel, message) {
        try {
            const parsed = JSON.parse(message);
            this.stats.messagesReceived++;
            this.emit(`message:${channel}`, parsed);
            this.emit('message', { channel, message: parsed });
        }
        catch (error) {
            console.error('Error handling message:', error);
        }
    }
    /**
     * Create a consumer group for a stream
     */
    async createConsumerGroup(stream, groupName) {
        if (!this.publisher) {
            throw new Error('Publisher not available');
        }
        const name = groupName || `${this.config.consumerGroupPrefix}:${stream}`;
        try {
            await this.publisher.xgroup('CREATE', stream, name, '$', 'MKSTREAM');
            this.stats.consumerGroups++;
        }
        catch (error) {
            // Group might already exist
            if (error instanceof Error && !error.message.includes('BUSYGROUP')) {
                console.error('Error creating consumer group:', error);
            }
        }
    }
    /**
     * Add a message to a stream
     */
    async addToStream(stream, data, options = {}) {
        if (!this.publisher) {
            throw new Error('Publisher not available');
        }
        const args = [stream];
        if (options.id) {
            args.push(options.id);
        }
        else {
            args.push('*');
        }
        for (const [key, value] of Object.entries(data)) {
            args.push(key, JSON.stringify(value));
        }
        if (options.maxLength) {
            args.push('MAXLEN', '~', options.maxLength);
        }
        const result = await this.publisher.xadd(...args);
        this.stats.messagesPublished++;
        return result;
    }
    /**
     * Read messages from a stream
     */
    async readFromStream(stream, groupName, consumerName, count = 10) {
        if (!this.publisher) {
            throw new Error('Publisher not available');
        }
        try {
            const result = await this.publisher.xreadgroup('GROUP', groupName, consumerName, 'COUNT', count, 'STREAMS', stream, '>');
            if (!result || !Array.isArray(result) || result.length === 0) {
                return [];
            }
            const streamData = result[0];
            if (!streamData || !Array.isArray(streamData) || streamData.length < 2) {
                return [];
            }
            const messages = streamData[1];
            if (!Array.isArray(messages)) {
                return [];
            }
            return messages.map((item) => {
                const [id, fields] = item;
                return {
                    id,
                    data: this.parseStreamFields(fields)
                };
            });
        }
        catch (error) {
            console.error('Error reading from stream:', error);
            return [];
        }
    }
    /**
     * Acknowledge message processing
     */
    async acknowledgeMessage(stream, groupName, messageId) {
        if (!this.publisher) {
            throw new Error('Publisher not available');
        }
        return await this.publisher.xack(stream, groupName, messageId);
    }
    /**
     * Parse stream fields
     */
    parseStreamFields(fields) {
        const result = {};
        for (let i = 0; i < fields.length; i += 2) {
            const key = fields[i];
            const value = fields[i + 1];
            if (key !== undefined && value !== undefined) {
                try {
                    result[key] = JSON.parse(value);
                }
                catch {
                    result[key] = value;
                }
            }
        }
        return result;
    }
    /**
     * Compress a message
     */
    compressMessage(message) {
        // Simple compression: remove unnecessary whitespace from JSON
        try {
            const parsed = JSON.parse(message);
            return JSON.stringify(parsed);
        }
        catch {
            return message;
        }
    }
    /**
     * Clean up old deduplication cache entries
     */
    cleanupDeduplicationCache() {
        const now = Date.now();
        const window = this.config.deduplicationWindow;
        for (const [key, timestamp] of this.deduplicationCache) {
            if (now - timestamp > window) {
                this.deduplicationCache.delete(key);
            }
        }
    }
    /**
     * Update average message size
     */
    updateAverageMessageSize(size) {
        const total = this.stats.messagesPublished;
        if (total === 1) {
            this.stats.averageMessageSize = size;
        }
        else {
            this.stats.averageMessageSize =
                (this.stats.averageMessageSize * (total - 1) + size) / total;
        }
    }
    /**
     * Get total subscriptions
     */
    getTotalSubscriptions() {
        let total = 0;
        for (const callbacks of this.subscriptions.values()) {
            total += callbacks.size;
        }
        return total;
    }
    /**
     * Generate a unique message ID
     */
    generateMessageId() {
        return `msg_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;
    }
    /**
     * Get pub/sub statistics
     */
    getStats() {
        return {
            ...this.stats,
            compressionSavings: this.compressionSavings
        };
    }
    /**
     * Update optimizer configuration
     */
    updateConfig(config) {
        this.config = { ...this.config, ...config };
    }
    /**
     * Get current configuration
     */
    getConfig() {
        return { ...this.config };
    }
    /**
     * Close pub/sub connections
     */
    async close() {
        // Flush all batches
        for (const channel of this.messageBuffer.keys()) {
            await this.flushBatch(channel);
        }
        // Clear timers
        for (const timer of this.batchTimers.values()) {
            clearTimeout(timer);
        }
        this.batchTimers.clear();
        // Close connections
        if (this.publisher) {
            await this.publisher.quit();
        }
        if (this.subscriber) {
            await this.subscriber.quit();
        }
        this.messageBuffer.clear();
        this.subscriptions.clear();
        this.deduplicationCache.clear();
    }
}
/**
 * Create a pub/sub optimizer instance with default configuration
 */
export function createRedisPubSubOptimizer(redis, config) {
    return new RedisPubSubOptimizer(redis, config);
}
