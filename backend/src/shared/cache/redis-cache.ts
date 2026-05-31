import { Redis } from "ioredis";

export class RedisCache {
  private client: Redis;
  private isConnected: boolean = false;

  constructor(private url: string = process.env["REDIS_URL"] || "redis://localhost:6379") {
    this.client = new Redis(url);
  }

  async connect(): Promise<void> {
    if (this.isConnected) return;

    try {
      await this.client.connect();
      this.isConnected = true;
    } catch (error) {
      console.error("Failed to connect to Redis:", error);
      throw error;
    }
  }

  async disconnect(): Promise<void> {
    if (!this.isConnected) return;

    try {
      await this.client.quit();
      this.isConnected = false;
    } catch (error) {
      console.error("Failed to disconnect from Redis:", error);
    }
  }

  async get<T>(key: string): Promise<T | null> {
    if (!this.isConnected) await this.connect();

    const value = await this.client.get(key);
    if (!value) return null;

    try {
      return JSON.parse(value) as T;
    } catch {
      return value as T;
    }
  }

  async set(key: string, value: any, ttl?: number): Promise<void> {
    if (!this.isConnected) await this.connect();

    const serialized = typeof value === "string" ? value : JSON.stringify(value);

    if (ttl) {
      await this.client.setex(key, ttl, serialized);
    } else {
      await this.client.set(key, serialized);
    }
  }

  async delete(key: string): Promise<void> {
    if (!this.isConnected) await this.connect();
    await this.client.del(key);
  }

  async deletePattern(pattern: string): Promise<void> {
    if (!this.isConnected) await this.connect();

    const keys = await this.client.keys(pattern);
    if (keys.length > 0) {
      await this.client.del(keys);
    }
  }

  async exists(key: string): Promise<boolean> {
    if (!this.isConnected) await this.connect();
    const result = await this.client.exists(key);
    return result === 1;
  }

  async increment(key: string, amount: number = 1): Promise<number> {
    if (!this.isConnected) await this.connect();
    return await this.client.incrby(key, amount);
  }

  async expire(key: string, ttl: number): Promise<void> {
    if (!this.isConnected) await this.connect();
    await this.client.expire(key, ttl);
  }

  async ttl(key: string): Promise<number> {
    if (!this.isConnected) await this.connect();
    return await this.client.ttl(key);
  }

  async flush(): Promise<void> {
    if (!this.isConnected) await this.connect();
    await this.client.flushdb();
  }

  getClient() {
    return this.client;
  }
}

// Singleton instance
let cacheInstance: RedisCache | null = null;

export function getCache(): RedisCache {
  if (!cacheInstance) {
    cacheInstance = new RedisCache();
  }
  return cacheInstance;
}

export async function initializeCache(): Promise<void> {
  const cache = getCache();
  await cache.connect();
}
