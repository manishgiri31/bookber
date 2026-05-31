import crypto from "node:crypto";
/**
 * Improved distributed lock with lock extension and monitoring.
 *
 * Improvements over basic lock:
 * - Lock extension for long-running operations
 * - Lock ownership verification
 * - Lock timeout monitoring
 * - Better error handling
 */
export class QueueLock {
    redis;
    lockTimeoutMs;
    lockExtensionIntervalMs;
    constructor(redis, lockTimeoutMs = 10000, lockExtensionIntervalMs = 5000) {
        this.redis = redis;
        this.lockTimeoutMs = lockTimeoutMs;
        this.lockExtensionIntervalMs = lockExtensionIntervalMs;
    }
    async withLock(key, ttlMs, fn) {
        if (!this.redis) {
            return fn();
        }
        const token = crypto.randomUUID();
        const locked = await this.redis.set(key, token, "PX", this.lockTimeoutMs, "NX");
        if (!locked) {
            throw new Error("QUEUE_LOCK_BUSY");
        }
        // Set up lock extension for long operations
        let extensionTimer = null;
        let shouldExtend = ttlMs > this.lockTimeoutMs;
        if (shouldExtend) {
            extensionTimer = setInterval(async () => {
                try {
                    if (!this.redis)
                        return;
                    const current = await this.redis.get(key);
                    if (current !== null && current === token) {
                        await this.redis.pexpire(key, this.lockTimeoutMs);
                    }
                }
                catch (error) {
                    console.error("Failed to extend lock:", error);
                }
            }, this.lockExtensionIntervalMs);
        }
        try {
            return await fn();
        }
        finally {
            // Clear extension timer
            if (extensionTimer) {
                clearInterval(extensionTimer);
            }
            // Safe lock release with ownership verification
            try {
                if (this.redis) {
                    const current = await this.redis.get(key);
                    if (current !== null && current === token) {
                        await this.redis.del(key);
                    }
                }
            }
            catch (error) {
                console.error("Failed to release lock:", error);
            }
        }
    }
    /**
     * Check if a lock is currently held
     */
    async isLocked(key) {
        if (!this.redis) {
            return false;
        }
        const exists = await this.redis.exists(key);
        return exists === 1;
    }
    /**
     * Get remaining TTL for a lock
     */
    async getLockTTL(key) {
        if (!this.redis) {
            return 0;
        }
        const ttl = await this.redis.pttl(key);
        return ttl;
    }
    /**
     * Force release a lock (emergency only)
     */
    async forceRelease(key) {
        if (!this.redis) {
            return;
        }
        await this.redis.del(key);
    }
}
