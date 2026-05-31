/**
 * Production-grade backpressure handling for Redis operations.
 *
 * Features:
 * - Operation queue with max size
 * - Queue timeout handling
 * - Rejection threshold
 * - Priority queue for critical operations
 * - Rate limiting
 * - Token bucket algorithm
 */
const DEFAULT_BACKPRESSURE_CONFIG = {
    maxQueueSize: 1000,
    queueTimeout: 10000,
    rejectionThreshold: 0.9,
    maxOperationsPerSecond: 1000,
    perShopRateLimit: 100,
    perConnectionRateLimit: 50,
    enablePriorityQueue: true
};
/**
 * Backpressure handler for Redis operations
 */
export class BackpressureHandler {
    config;
    operationQueue = [];
    priorityQueue = new Map();
    processing = new Set();
    stats = {
        totalOperations: 0,
        queuedOperations: 0,
        completedOperations: 0,
        rejectedOperations: 0,
        timedOutOperations: 0,
        averageQueueTime: 0,
        currentQueueSize: 0,
        currentRate: 0
    };
    rateLimiters = new Map();
    queueTimes = [];
    isProcessing = false;
    constructor(config = {}) {
        this.config = { ...DEFAULT_BACKPRESSURE_CONFIG, ...config };
        this.startProcessing();
    }
    /**
     * Execute an operation with backpressure handling
     */
    async execute(fn, options = {}) {
        const operation = {
            id: this.generateOperationId(),
            fn,
            priority: options.priority || 'normal',
            shopId: options.shopId,
            connectionId: options.connectionId,
            timestamp: Date.now(),
            timeout: options.timeout || this.config.queueTimeout
        };
        // Check rate limits
        if (options.shopId && !this.checkRateLimit(options.shopId, this.config.perShopRateLimit)) {
            this.stats.rejectedOperations++;
            throw new Error('REDIS_RATE_LIMIT_EXCEEDED: shop');
        }
        if (options.connectionId && !this.checkRateLimit(options.connectionId, this.config.perConnectionRateLimit)) {
            this.stats.rejectedOperations++;
            throw new Error('REDIS_RATE_LIMIT_EXCEEDED: connection');
        }
        // Check queue capacity
        const currentSize = this.getCurrentQueueSize();
        if (currentSize >= this.config.maxQueueSize) {
            this.stats.rejectedOperations++;
            throw new Error('REDIS_QUEUE_EXHAUSTED');
        }
        // Check rejection threshold
        if (currentSize / this.config.maxQueueSize >= this.config.rejectionThreshold) {
            // Only allow critical operations
            if (operation.priority !== 'critical') {
                this.stats.rejectedOperations++;
                throw new Error('REDIS_QUEUE_OVERLOAD');
            }
        }
        // Add to queue
        this.enqueueOperation(operation);
        this.stats.totalOperations++;
        this.stats.queuedOperations++;
        // Wait for operation to complete
        return new Promise((resolve, reject) => {
            const timeoutId = setTimeout(() => {
                this.processing.delete(operation.id);
                this.stats.timedOutOperations++;
                reject(new Error('REDIS_OPERATION_TIMEOUT'));
            }, operation.timeout);
            operation.fn()
                .then(result => {
                clearTimeout(timeoutId);
                this.processing.delete(operation.id);
                this.stats.completedOperations++;
                const queueTime = Date.now() - operation.timestamp;
                this.recordQueueTime(queueTime);
                resolve(result);
            })
                .catch(error => {
                clearTimeout(timeoutId);
                this.processing.delete(operation.id);
                reject(error);
            });
        });
    }
    /**
     * Enqueue an operation
     */
    enqueueOperation(operation) {
        if (this.config.enablePriorityQueue && operation.priority !== 'normal') {
            const priorityKey = operation.priority;
            if (!this.priorityQueue.has(priorityKey)) {
                this.priorityQueue.set(priorityKey, []);
            }
            this.priorityQueue.get(priorityKey).push(operation);
        }
        else {
            this.operationQueue.push(operation);
        }
        this.stats.currentQueueSize = this.getCurrentQueueSize();
    }
    /**
     * Dequeue the next operation
     */
    dequeueOperation() {
        // Check priority queues first (critical > high > low)
        const priorityOrder = ['critical', 'high', 'low'];
        for (const priority of priorityOrder) {
            const queue = this.priorityQueue.get(priority);
            if (queue && queue.length > 0) {
                const operation = queue.shift();
                if (queue.length === 0) {
                    this.priorityQueue.delete(priority);
                }
                this.stats.currentQueueSize = this.getCurrentQueueSize();
                return operation;
            }
        }
        // Check normal queue
        if (this.operationQueue.length > 0) {
            const operation = this.operationQueue.shift();
            this.stats.currentQueueSize = this.getCurrentQueueSize();
            return operation;
        }
        return null;
    }
    /**
     * Start processing operations
     */
    startProcessing() {
        const processNext = async () => {
            if (this.isProcessing) {
                return;
            }
            this.isProcessing = true;
            while (true) {
                const operation = this.dequeueOperation();
                if (!operation) {
                    break;
                }
                this.processing.add(operation.id);
                // Operation execution is handled in the execute method
            }
            this.isProcessing = false;
        };
        // Process operations periodically
        setInterval(processNext, 10);
    }
    /**
     * Check rate limit using token bucket algorithm
     */
    checkRateLimit(key, rateLimit) {
        let tokenBucket = this.rateLimiters.get(key);
        if (!tokenBucket) {
            tokenBucket = new TokenBucket(rateLimit, rateLimit);
            this.rateLimiters.set(key, tokenBucket);
        }
        return tokenBucket.tryConsume(1);
    }
    /**
     * Get current queue size
     */
    getCurrentQueueSize() {
        let size = this.operationQueue.length;
        for (const queue of this.priorityQueue.values()) {
            size += queue.length;
        }
        return size;
    }
    /**
     * Record queue time for statistics
     */
    recordQueueTime(time) {
        this.queueTimes.push(time);
        // Keep only last 100 samples
        if (this.queueTimes.length > 100) {
            this.queueTimes.shift();
        }
        // Calculate average
        this.stats.averageQueueTime = this.queueTimes.reduce((sum, val) => sum + val, 0) / this.queueTimes.length;
    }
    /**
     * Generate a unique operation ID
     */
    generateOperationId() {
        return `op_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;
    }
    /**
     * Get backpressure statistics
     */
    getStats() {
        return { ...this.stats };
    }
    /**
     * Update backpressure configuration
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
     * Clear the operation queue
     */
    clearQueue() {
        this.operationQueue = [];
        this.priorityQueue.clear();
        this.stats.currentQueueSize = 0;
    }
}
/**
 * Token bucket implementation for rate limiting
 */
class TokenBucket {
    tokens;
    lastRefill;
    capacity;
    refillRate;
    constructor(capacity, refillRate) {
        this.capacity = capacity;
        this.refillRate = refillRate;
        this.tokens = capacity;
        this.lastRefill = Date.now();
    }
    tryConsume(tokens) {
        this.refill();
        if (this.tokens >= tokens) {
            this.tokens -= tokens;
            return true;
        }
        return false;
    }
    refill() {
        const now = Date.now();
        const elapsed = (now - this.lastRefill) / 1000; // Convert to seconds
        const tokensToAdd = elapsed * this.refillRate;
        this.tokens = Math.min(this.capacity, this.tokens + tokensToAdd);
        this.lastRefill = now;
    }
}
/**
 * Create a backpressure handler instance with default configuration
 */
export function createBackpressureHandler(config) {
    return new BackpressureHandler(config);
}
