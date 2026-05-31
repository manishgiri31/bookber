import crypto from "node:crypto";
import type { Redis as RedisClient } from "ioredis";

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
  private readonly lockTimeoutMs: number;
  private readonly lockExtensionIntervalMs: number;

  constructor(
    private readonly redis: RedisClient | null,
    lockTimeoutMs: number = 10000,
    lockExtensionIntervalMs: number = 5000
  ) {
    this.lockTimeoutMs = lockTimeoutMs;
    this.lockExtensionIntervalMs = lockExtensionIntervalMs;
  }

  async withLock<T>(key: string, ttlMs: number, fn: () => Promise<T>): Promise<T> {
    if (!this.redis) {
      return fn();
    }

    const token = crypto.randomUUID();
    const locked = await this.redis.set(key, token, "PX", this.lockTimeoutMs, "NX");
    if (!locked) {
      throw new Error("QUEUE_LOCK_BUSY");
    }

    // Set up lock extension for long operations
    let extensionTimer: NodeJS.Timeout | null = null;
    let shouldExtend = ttlMs > this.lockTimeoutMs;

    if (shouldExtend) {
      extensionTimer = setInterval(async () => {
        try {
          if (!this.redis) return;
          const current = await this.redis.get(key);
          if (current !== null && current === token) {
            await this.redis.pexpire(key, this.lockTimeoutMs);
          }
        } catch (error) {
          console.error("Failed to extend lock:", error);
        }
      }, this.lockExtensionIntervalMs);
    }

    try {
      return await fn();
    } finally {
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
      } catch (error) {
        console.error("Failed to release lock:", error);
      }
    }
  }

  /**
   * Check if a lock is currently held
   */
  async isLocked(key: string): Promise<boolean> {
    if (!this.redis) {
      return false;
    }

    const exists = await this.redis.exists(key);
    return exists === 1;
  }

  /**
   * Get remaining TTL for a lock
   */
  async getLockTTL(key: string): Promise<number> {
    if (!this.redis) {
      return 0;
    }

    const ttl = await this.redis.pttl(key);
    return ttl;
  }

  /**
   * Force release a lock (emergency only)
   */
  async forceRelease(key: string): Promise<void> {
    if (!this.redis) {
      return;
    }

    await this.redis.del(key);
  }
}
