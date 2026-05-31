import { Redis } from "ioredis";
export class RedisCache {
    url;
    client;
    isConnected = false;
    constructor(url = process.env["REDIS_URL"] || "redis://localhost:6379") {
        this.url = url;
        this.client = new Redis(url);
    }
    async connect() {
        if (this.isConnected)
            return;
        try {
            await this.client.connect();
            this.isConnected = true;
        }
        catch (error) {
            console.error("Failed to connect to Redis:", error);
            throw error;
        }
    }
    async disconnect() {
        if (!this.isConnected)
            return;
        try {
            await this.client.quit();
            this.isConnected = false;
        }
        catch (error) {
            console.error("Failed to disconnect from Redis:", error);
        }
    }
    async get(key) {
        if (!this.isConnected)
            await this.connect();
        const value = await this.client.get(key);
        if (!value)
            return null;
        try {
            return JSON.parse(value);
        }
        catch {
            return value;
        }
    }
    async set(key, value, ttl) {
        if (!this.isConnected)
            await this.connect();
        const serialized = typeof value === "string" ? value : JSON.stringify(value);
        if (ttl) {
            await this.client.setex(key, ttl, serialized);
        }
        else {
            await this.client.set(key, serialized);
        }
    }
    async delete(key) {
        if (!this.isConnected)
            await this.connect();
        await this.client.del(key);
    }
    async deletePattern(pattern) {
        if (!this.isConnected)
            await this.connect();
        const keys = await this.client.keys(pattern);
        if (keys.length > 0) {
            await this.client.del(keys);
        }
    }
    async exists(key) {
        if (!this.isConnected)
            await this.connect();
        const result = await this.client.exists(key);
        return result === 1;
    }
    async increment(key, amount = 1) {
        if (!this.isConnected)
            await this.connect();
        return await this.client.incrby(key, amount);
    }
    async expire(key, ttl) {
        if (!this.isConnected)
            await this.connect();
        await this.client.expire(key, ttl);
    }
    async ttl(key) {
        if (!this.isConnected)
            await this.connect();
        return await this.client.ttl(key);
    }
    async flush() {
        if (!this.isConnected)
            await this.connect();
        await this.client.flushdb();
    }
    getClient() {
        return this.client;
    }
}
// Singleton instance
let cacheInstance = null;
export function getCache() {
    if (!cacheInstance) {
        cacheInstance = new RedisCache();
    }
    return cacheInstance;
}
export async function initializeCache() {
    const cache = getCache();
    await cache.connect();
}
