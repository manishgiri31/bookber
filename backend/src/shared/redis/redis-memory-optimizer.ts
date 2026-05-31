import type { Redis as RedisClient } from "ioredis";
import { EventEmitter } from "node:events";

export interface MemoryOptimizerConfig {
  enableCompression: boolean;
  compressionThreshold: number;
  enableHashOptimization: boolean;
  enableTTLManagement: boolean;
  defaultTTL: number;
  enableEvictionPolicy: boolean;
  maxMemoryPolicy: string;
  enableMemoryMonitoring: boolean;
  memoryCheckInterval: number;
}

export interface MemoryStats {
  usedMemory: number;
  maxMemory: number;
  memoryUsagePercent: number;
  fragmentationRatio: number;
  keysCount: number;
  evictedKeys: number;
  compressionSavings: number;
  ttlExpiredKeys: number;
}

export interface MemoryOptimizationResult {
  success: boolean;
  memorySaved: number;
  keysOptimized: number;
  duration: number;
  error?: string;
}

const DEFAULT_MEMORY_OPTIMIZER_CONFIG: MemoryOptimizerConfig = {
  enableCompression: true,
  compressionThreshold: 1024, // 1KB
  enableHashOptimization: true,
  enableTTLManagement: true,
  defaultTTL: 3600, // 1 hour
  enableEvictionPolicy: true,
  maxMemoryPolicy: 'allkeys-lru',
  enableMemoryMonitoring: true,
  memoryCheckInterval: 60000 // 1 minute
};

/**
 * Production-grade Redis memory optimizer for queue operations.
 * 
 * Features:
 * - Data compression for large values
 * - Hash optimization for related data
 * - TTL management and expiration
 * - Memory monitoring and alerts
 * - Eviction policy management
 * - Memory usage optimization
 */
export class RedisMemoryOptimizer extends EventEmitter {
  private config: MemoryOptimizerConfig;
  private redis: RedisClient | null;
  private memoryTimer?: NodeJS.Timeout;
  private stats: MemoryStats;
  private compressionSavings: number = 0;

  constructor(redis: RedisClient | null, config: Partial<MemoryOptimizerConfig> = {}) {
    super();
    this.redis = redis;
    this.config = { ...DEFAULT_MEMORY_OPTIMIZER_CONFIG, ...config };
    this.stats = this.createInitialStats();
    
    if (this.redis) {
      this.initializeOptimizer();
    }
  }

  /**
   * Create initial memory stats
   */
  private createInitialStats(): MemoryStats {
    return {
      usedMemory: 0,
      maxMemory: 0,
      memoryUsagePercent: 0,
      fragmentationRatio: 0,
      keysCount: 0,
      evictedKeys: 0,
      compressionSavings: 0,
      ttlExpiredKeys: 0
    };
  }

  /**
   * Initialize memory optimizer
   */
  private async initializeOptimizer(): Promise<void> {
    if (!this.redis) {
      return;
    }

    try {
      // Set max memory policy
      if (this.config.enableEvictionPolicy) {
        await this.redis.config('SET', 'maxmemory-policy', this.config.maxMemoryPolicy);
      }

      // Start memory monitoring
      if (this.config.enableMemoryMonitoring) {
        this.startMemoryMonitoring();
      }
    } catch (error: unknown) {
      console.error('Error initializing memory optimizer:', error);
    }
  }

  /**
   * Start memory monitoring
   */
  private startMemoryMonitoring(): void {
    this.memoryTimer = setInterval(async () => {
      await this.checkMemoryUsage();
    }, this.config.memoryCheckInterval);
  }

  /**
   * Stop memory monitoring
   */
  stopMemoryMonitoring(): void {
    if (this.memoryTimer) {
      clearInterval(this.memoryTimer);
    }
  }

  /**
   * Check memory usage
   */
  async checkMemoryUsage(): Promise<MemoryStats> {
    if (!this.redis) {
      return this.stats;
    }

    try {
      const info = await this.redis.info('memory');
      const memoryInfo = this.parseRedisInfo(info);

      const usedMemory = this.parseNumericValue(memoryInfo['used_memory'], 0);
      const maxMemory = this.parseNumericValue(memoryInfo['maxmemory'], 0);
      const memoryUsagePercent = maxMemory > 0 ? (usedMemory / maxMemory) * 100 : 0;
      const fragmentationRatio = this.parseNumericValue(memoryInfo['mem_fragmentation_ratio'], 1);
      const evictedKeys = this.parseNumericValue(memoryInfo['evicted_keys'], 0);

      const keyspaceInfo = await this.redis.info('keyspace');
      const keyspaceData = this.parseRedisInfo(keyspaceInfo);
      const keysCount = this.parseNumericValue(keyspaceData['keys'], 0);

      this.stats = {
        usedMemory,
        maxMemory,
        memoryUsagePercent,
        fragmentationRatio,
        keysCount,
        evictedKeys,
        compressionSavings: this.compressionSavings,
        ttlExpiredKeys: this.stats.ttlExpiredKeys
      };

      // Emit memory alert if usage is high
      if (memoryUsagePercent > 80) {
        this.emit('memoryAlert', {
          type: 'high_usage',
          usage: memoryUsagePercent,
          threshold: 80
        });
      }

      this.emit('memoryStats', this.stats);
      return this.stats;
    } catch (error: unknown) {
      console.error('Error checking memory usage:', error);
      return this.stats;
    }
  }

  /**
   * Optimize queue memory usage
   */
  async optimizeQueueMemory(shopId: string): Promise<MemoryOptimizationResult> {
    if (!this.redis) {
      return {
        success: false,
        memorySaved: 0,
        keysOptimized: 0,
        duration: 0,
        error: 'Redis client not available'
      };
    }

    const startTime = Date.now();
    let memorySaved = 0;
    let keysOptimized = 0;

    try {
      // Optimize queue sorted sets
      const queueKey = `shop:${shopId}:queue`;
      const queueSize = await this.redis.zcard(queueKey);
      
      if (queueSize > 0) {
        // Remove old queue entries
        const oldEntries = await this.redis.zrange(queueKey, 0, -100);
        if (oldEntries.length > 0) {
          await this.redis.zrem(queueKey, ...oldEntries);
          keysOptimized += oldEntries.length;
        }
      }

      // Optimize booking snapshots
      const bookingPattern = `booking:*`;
      const bookingKeys = await this.scanKeys(bookingPattern);
      
      for (const key of bookingKeys) {
        const size = await this.redis.strlen(key);
        
        // Compress large values
        if (this.config.enableCompression && size > this.config.compressionThreshold) {
          const compressed = await this.compressValue(key);
          if (compressed) {
            memorySaved += size - compressed;
            keysOptimized++;
          }
        }
      }

      // Set TTL on keys without expiration
      if (this.config.enableTTLManagement) {
        const keysWithoutTTL = await this.findKeysWithoutTTL(`shop:${shopId}:*`);
        for (const key of keysWithoutTTL) {
          await this.redis.expire(key, this.config.defaultTTL);
          keysOptimized++;
        }
      }

      const duration = Date.now() - startTime;
      this.compressionSavings += memorySaved;

      return {
        success: true,
        memorySaved,
        keysOptimized,
        duration
      };
    } catch (error: unknown) {
      const duration = Date.now() - startTime;
      
      return {
        success: false,
        memorySaved: 0,
        keysOptimized: 0,
        duration,
        error: error instanceof Error ? error.message : String(error)
      };
    }
  }

  /**
   * Compress a Redis value
   */
  private async compressValue(key: string): Promise<number | null> {
    if (!this.redis) {
      return null;
    }

    try {
      const value = await this.redis.get(key);
      if (!value) {
        return null;
      }

      const originalSize = value.length;
      
      // Simple compression: remove extra whitespace and optimize JSON
      let compressed = value;
      
      try {
        const parsed = JSON.parse(value);
        compressed = JSON.stringify(parsed);
      } catch {
        // Not JSON, just trim whitespace
        compressed = value.trim();
      }

      if (compressed.length < originalSize) {
        await this.redis.set(key, compressed);
        return originalSize - compressed.length;
      }

      return null;
    } catch (error: unknown) {
      console.error('Error compressing value:', error);
      return null;
    }
  }

  /**
   * Find keys without TTL
   */
  private async findKeysWithoutTTL(pattern: string): Promise<string[]> {
    if (!this.redis) {
      return [];
    }

    const keys: string[] = [];
    const allKeys = await this.scanKeys(pattern);

    for (const key of allKeys) {
      const ttl = await this.redis.ttl(key);
      if (ttl === -1) {
        keys.push(key);
      }
    }

    return keys;
  }

  /**
   * Optimize hash memory usage
   */
  async optimizeHashMemory(pattern: string): Promise<MemoryOptimizationResult> {
    if (!this.redis) {
      return {
        success: false,
        memorySaved: 0,
        keysOptimized: 0,
        duration: 0,
        error: 'Redis client not available'
      };
    }

    const startTime = Date.now();
    let memorySaved = 0;
    let keysOptimized = 0;

    try {
      const keys = await this.scanKeys(pattern);

      for (const key of keys) {
        const type = await this.redis.type(key);
        if (type === 'hash') {
          const fields = await this.redis.hkeys(key);
          
          // Optimize hash fields
          for (const field of fields) {
            const value = await this.redis.hget(key, field);
            if (value && value.length > this.config.compressionThreshold) {
              const compressed = await this.compressHashField(key, field);
              if (compressed) {
                memorySaved += compressed;
                keysOptimized++;
              }
            }
          }
        }
      }

      const duration = Date.now() - startTime;
      this.compressionSavings += memorySaved;

      return {
        success: true,
        memorySaved,
        keysOptimized,
        duration
      };
    } catch (error: unknown) {
      const duration = Date.now() - startTime;
      
      return {
        success: false,
        memorySaved: 0,
        keysOptimized: 0,
        duration,
        error: error instanceof Error ? error.message : String(error)
      };
    }
  }

  /**
   * Compress a hash field
   */
  private async compressHashField(key: string, field: string): Promise<number | null> {
    if (!this.redis) {
      return null;
    }

    try {
      const value = await this.redis.hget(key, field);
      if (!value) {
        return null;
      }

      const originalSize = value.length;
      
      try {
        const parsed = JSON.parse(value);
        const compressed = JSON.stringify(parsed);
        
        if (compressed.length < originalSize) {
          await this.redis.hset(key, field, compressed);
          return originalSize - compressed.length;
        }
      } catch {
        // Not JSON, cannot compress
      }

      return null;
    } catch (error: unknown) {
      console.error('Error compressing hash field:', error);
      return null;
    }
  }

  /**
   * Scan Redis keys matching a pattern
   */
  private async scanKeys(pattern: string): Promise<string[]> {
    if (!this.redis) {
      return [];
    }

    const keys: string[] = [];
    let cursor = '0';

    do {
      const result = await this.redis.scan(cursor, 'MATCH', pattern, 'COUNT', 100);
      cursor = result[0];
      keys.push(...result[1]);
    } while (cursor !== '0');

    return keys;
  }

  /**
   * Clean up expired keys
   */
  async cleanupExpiredKeys(): Promise<number> {
    if (!this.redis) {
      return 0;
    }

    let cleaned = 0;

    try {
      // Redis automatically expires keys with TTL
      // This method can be used to force cleanup of specific patterns
      const keys = await this.scanKeys('*');
      
      for (const key of keys) {
        const ttl = await this.redis.ttl(key);
        if (ttl === -2) {
          // Key doesn't exist
          continue;
        }
        
        if (ttl === -1) {
          // Key has no expiration, check if it should have one
          if (key.startsWith('booking:')) {
            await this.redis.expire(key, this.config.defaultTTL);
            cleaned++;
          }
        }
      }

      this.stats.ttlExpiredKeys += cleaned;
      return cleaned;
    } catch (error: unknown) {
      console.error('Error cleaning up expired keys:', error);
      return 0;
    }
  }

  /**
   * Parse Redis INFO output
   */
  private parseRedisInfo(info: string): Record<string, string> {
    const result: Record<string, string> = {};
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
  private parseNumericValue(value: string | undefined, fallback: number): number {
    if (value === undefined || value === '') {
      return fallback;
    }
    const parsed = Number.parseFloat(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  }

  /**
   * Get memory statistics
   */
  getStats(): MemoryStats {
    return { ...this.stats };
  }

  /**
   * Update optimizer configuration
   */
  updateConfig(config: Partial<MemoryOptimizerConfig>): void {
    this.config = { ...this.config, ...config };
    
    // Reinitialize with new configuration
    if (this.redis) {
      this.initializeOptimizer();
    }
  }

  /**
   * Get current configuration
   */
  getConfig(): MemoryOptimizerConfig {
    return { ...this.config };
  }
}

/**
 * Create a memory optimizer instance with default configuration
 */
export function createRedisMemoryOptimizer(redis: RedisClient | null, config?: Partial<MemoryOptimizerConfig>): RedisMemoryOptimizer {
  return new RedisMemoryOptimizer(redis, config);
}
