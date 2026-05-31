/**
 * Production-grade retry strategy with exponential backoff and jitter.
 *
 * Features:
 * - Exponential backoff with configurable parameters
 * - Jitter to prevent thundering herd
 * - Retry condition filtering
 * - Max retry limits
 * - Retry attempt tracking
 */
const DEFAULT_RETRY_CONFIG = {
    maxRetries: 5,
    initialDelay: 100,
    maxDelay: 5000,
    backoffMultiplier: 2,
    jitter: 0.25,
    retryableErrors: [
        'ECONNREFUSED',
        'ECONNRESET',
        'ETIMEDOUT',
        'EHOSTUNREACH',
        'EPIPE',
        'REDIS_CONNECTION_CLOSED',
        'REDIS_LOADING',
        'REDIS_MASTER_DOWN',
        'REDIS_CLUSTER_DOWN',
        'MOVED',
        'ASK',
        'TRYAGAIN',
        'CLUSTERDOWN',
        'CROSSSLOT',
        'LOADING'
    ],
    nonRetryableErrors: [
        'NOAUTH',
        'WRONGPASS',
        'NOPERM',
        'ERR',
        'EXECABORT',
        'WATCH',
        'NOREPLICAS'
    ]
};
/**
 * Retry strategy with exponential backoff and jitter
 */
export class RetryStrategy {
    config;
    constructor(config = {}) {
        this.config = { ...DEFAULT_RETRY_CONFIG, ...config };
    }
    /**
     * Execute a function with retry logic
     */
    async execute(fn) {
        let lastError;
        let attempts = 0;
        let totalDelay = 0;
        while (attempts <= this.config.maxRetries) {
            attempts++;
            try {
                const result = await fn();
                return result;
            }
            catch (error) {
                lastError = error instanceof Error ? error : new Error(String(error));
                // Check if error is non-retryable
                if (this.isNonRetryableError(lastError)) {
                    throw lastError;
                }
                // Check if we've exceeded max retries
                if (attempts > this.config.maxRetries) {
                    throw lastError;
                }
                // Calculate delay with exponential backoff and jitter
                const delay = this.calculateDelay(attempts);
                totalDelay += delay;
                // Wait before retry
                await this.sleep(delay);
            }
        }
        throw lastError;
    }
    /**
     * Execute a function with retry logic and return detailed result
     */
    async executeWithResult(fn) {
        let lastError;
        let attempts = 0;
        let totalDelay = 0;
        while (attempts <= this.config.maxRetries) {
            attempts++;
            try {
                const result = await fn();
                return {
                    success: true,
                    value: result,
                    attempts,
                    totalDelay
                };
            }
            catch (error) {
                lastError = error instanceof Error ? error : new Error(String(error));
                // Check if error is non-retryable
                if (this.isNonRetryableError(lastError)) {
                    return {
                        success: false,
                        error: lastError,
                        attempts,
                        totalDelay
                    };
                }
                // Check if we've exceeded max retries
                if (attempts > this.config.maxRetries) {
                    return {
                        success: false,
                        error: lastError,
                        attempts,
                        totalDelay
                    };
                }
                // Calculate delay with exponential backoff and jitter
                const delay = this.calculateDelay(attempts);
                totalDelay += delay;
                // Wait before retry
                await this.sleep(delay);
            }
        }
        return {
            success: false,
            error: lastError,
            attempts,
            totalDelay
        };
    }
    /**
     * Calculate delay with exponential backoff and jitter
     */
    calculateDelay(attempt) {
        // Exponential backoff
        const baseDelay = this.config.initialDelay * Math.pow(this.config.backoffMultiplier, attempt - 1);
        // Cap at max delay
        const cappedDelay = Math.min(baseDelay, this.config.maxDelay);
        // Add jitter (±jitter%)
        const jitterAmount = cappedDelay * this.config.jitter;
        const jitter = (Math.random() - 0.5) * 2 * jitterAmount;
        return Math.max(0, cappedDelay + jitter);
    }
    /**
     * Check if error is non-retryable
     */
    isNonRetryableError(error) {
        const errorMessage = error.message.toUpperCase();
        // Check against non-retryable errors
        for (const nonRetryableError of this.config.nonRetryableErrors) {
            if (errorMessage.includes(nonRetryableError)) {
                return true;
            }
        }
        // Check if error is retryable
        for (const retryableError of this.config.retryableErrors) {
            if (errorMessage.includes(retryableError)) {
                return false;
            }
        }
        // Default to non-retryable for unknown errors
        return true;
    }
    /**
     * Sleep for specified milliseconds
     */
    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
    /**
     * Update retry configuration
     */
    updateConfig(config) {
        this.config = { ...this.config, ...config };
    }
    /**
     * Get current retry configuration
     */
    getConfig() {
        return { ...this.config };
    }
}
/**
 * Decorator for retrying functions
 */
export function withRetry(config = {}) {
    const retryStrategy = new RetryStrategy(config);
    return function (target, propertyKey, descriptor) {
        const originalMethod = descriptor.value;
        descriptor.value = async function (...args) {
            return retryStrategy.execute(() => originalMethod.apply(this, args));
        };
        return descriptor;
    };
}
/**
 * Create a retry strategy instance with default configuration
 */
export function createRetryStrategy(config) {
    return new RetryStrategy(config);
}
