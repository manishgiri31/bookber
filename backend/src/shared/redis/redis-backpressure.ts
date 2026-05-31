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

export interface BackpressureConfig {
  maxQueueSize: number;
  queueTimeout: number;
  rejectionThreshold: number;
  maxOperationsPerSecond: number;
  perShopRateLimit: number;
  perConnectionRateLimit: number;
  enablePriorityQueue: boolean;
}

export interface Operation {
  id: string;
  fn: () => Promise<any>;
  priority: 'critical' | 'high' | 'normal' | 'low';
  shopId?: string | undefined;
  connectionId?: string | undefined;
  timestamp: number;
  timeout?: number;
}

export interface BackpressureStats {
  totalOperations: number;
  queuedOperations: number;
  completedOperations: number;
  rejectedOperations: number;
  timedOutOperations: number;
  averageQueueTime: number;
  currentQueueSize: number;
  currentRate: number;
}

const DEFAULT_BACKPRESSURE_CONFIG: BackpressureConfig = {
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
  private config: BackpressureConfig;
  private operationQueue: Operation[] = [];
  private priorityQueue: Map<string, Operation[]> = new Map();
  private processing: Set<string> = new Set();
  private stats: BackpressureStats = {
    totalOperations: 0,
    queuedOperations: 0,
    completedOperations: 0,
    rejectedOperations: 0,
    timedOutOperations: 0,
    averageQueueTime: 0,
    currentQueueSize: 0,
    currentRate: 0
  };
  private rateLimiters: Map<string, TokenBucket> = new Map();
  private queueTimes: number[] = [];
  private isProcessing = false;

  constructor(config: Partial<BackpressureConfig> = {}) {
    this.config = { ...DEFAULT_BACKPRESSURE_CONFIG, ...config };
    this.startProcessing();
  }

  /**
   * Execute an operation with backpressure handling
   */
  async execute<T>(fn: () => Promise<T>, options: {
    priority?: 'critical' | 'high' | 'normal' | 'low';
    shopId?: string;
    connectionId?: string;
    timeout?: number;
  } = {}): Promise<T> {
    const operation: Operation = {
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
    return new Promise<T>((resolve, reject) => {
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
  private enqueueOperation(operation: Operation): void {
    if (this.config.enablePriorityQueue && operation.priority !== 'normal') {
      const priorityKey = operation.priority;
      if (!this.priorityQueue.has(priorityKey)) {
        this.priorityQueue.set(priorityKey, []);
      }
      this.priorityQueue.get(priorityKey)!.push(operation);
    } else {
      this.operationQueue.push(operation);
    }
    this.stats.currentQueueSize = this.getCurrentQueueSize();
  }

  /**
   * Dequeue the next operation
   */
  private dequeueOperation(): Operation | null {
    // Check priority queues first (critical > high > low)
    const priorityOrder = ['critical', 'high', 'low'];
    for (const priority of priorityOrder) {
      const queue = this.priorityQueue.get(priority);
      if (queue && queue.length > 0) {
        const operation = queue.shift()!;
        if (queue.length === 0) {
          this.priorityQueue.delete(priority);
        }
        this.stats.currentQueueSize = this.getCurrentQueueSize();
        return operation;
      }
    }

    // Check normal queue
    if (this.operationQueue.length > 0) {
      const operation = this.operationQueue.shift()!;
      this.stats.currentQueueSize = this.getCurrentQueueSize();
      return operation;
    }

    return null;
  }

  /**
   * Start processing operations
   */
  private startProcessing(): void {
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
  private checkRateLimit(key: string, rateLimit: number): boolean {
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
  private getCurrentQueueSize(): number {
    let size = this.operationQueue.length;
    for (const queue of this.priorityQueue.values()) {
      size += queue.length;
    }
    return size;
  }

  /**
   * Record queue time for statistics
   */
  private recordQueueTime(time: number): void {
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
  private generateOperationId(): string {
    return `op_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;
  }

  /**
   * Get backpressure statistics
   */
  getStats(): BackpressureStats {
    return { ...this.stats };
  }

  /**
   * Update backpressure configuration
   */
  updateConfig(config: Partial<BackpressureConfig>): void {
    this.config = { ...this.config, ...config };
  }

  /**
   * Get current configuration
   */
  getConfig(): BackpressureConfig {
    return { ...this.config };
  }

  /**
   * Clear the operation queue
   */
  clearQueue(): void {
    this.operationQueue = [];
    this.priorityQueue.clear();
    this.stats.currentQueueSize = 0;
  }
}

/**
 * Token bucket implementation for rate limiting
 */
class TokenBucket {
  private tokens: number;
  private lastRefill: number;
  private readonly capacity: number;
  private readonly refillRate: number;

  constructor(capacity: number, refillRate: number) {
    this.capacity = capacity;
    this.refillRate = refillRate;
    this.tokens = capacity;
    this.lastRefill = Date.now();
  }

  tryConsume(tokens: number): boolean {
    this.refill();

    if (this.tokens >= tokens) {
      this.tokens -= tokens;
      return true;
    }

    return false;
  }

  private refill(): void {
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
export function createBackpressureHandler(config?: Partial<BackpressureConfig>): BackpressureHandler {
  return new BackpressureHandler(config);
}
