import crypto from "node:crypto";

import { Redis, type RedisOptions } from "ioredis";

import { env } from "../../shared/config/env.js";
import { createModuleLogger } from "../logging/structured-logger.js";
import { observeRedisLatency } from "../metrics/prometheus.js";

const log = createModuleLogger("redis");

export type RedisHealth = {
  connected: boolean;
  latencyMs: number;
  memoryUsedBytes?: number;
  error?: string;
};

function baseOptions(): RedisOptions {
  return {
    lazyConnect: true,
    maxRetriesPerRequest: 3,
    enableReadyCheck: true,
    connectTimeout: env.REDIS_CONNECTION_TIMEOUT_MS,
    retryStrategy(times: number): number | null {
      if (times > 10) return null;
      return Math.min(times * 200, 3_000);
    },
    reconnectOnError(error: Error): boolean {
      const retryable = ["READONLY", "ECONNRESET", "ETIMEDOUT"];
      return retryable.some((code) => error.message.includes(code));
    }
  };
}

export class RedisManager {
  readonly command: Redis | null;
  readonly pub: Redis | null;
  readonly sub: Redis | null;
  private healthTimer: NodeJS.Timeout | null = null;
  private lastHealth: RedisHealth = { connected: false, latencyMs: -1 };
  private connected = false;
  private connectAttempted = false;

  constructor() {
    if (!env.REDIS_URL) {
      this.command = null;
      this.pub = null;
      this.sub = null;
      return;
    }

    const options = baseOptions();
    this.command = new Redis(env.REDIS_URL, options);
    this.pub = new Redis(env.REDIS_URL, options);
    this.sub = new Redis(env.REDIS_URL, options);

    for (const client of [this.command, this.pub, this.sub]) {
      client.on("error", (error) => {
        if (this.connected) {
          log.error({ err: error }, "redis client error");
          return;
        }
        log.debug({ err: error }, "redis connection attempt failed");
      });
      client.on("connect", () => log.info("redis connected"));
      client.on("reconnecting", () => {
        if (this.connected) {
          log.warn("redis reconnecting");
        } else {
          log.debug("redis reconnecting before initial connection");
        }
      });
    }
  }

  get client(): Redis | null {
    return this.connected ? this.command : null;
  }

  async connect(): Promise<boolean> {
    if (this.connected) return true;
    if (this.connectAttempted) return false;

    const clients = [this.command, this.pub, this.sub].filter((c): c is Redis => c !== null);
    if (clients.length === 0) return false;

    this.connectAttempted = true;
    try {
      await Promise.race([
        Promise.all(clients.map((c) => c.connect())),
        new Promise<never>((_, reject) => {
          setTimeout(
            () => reject(new Error(`Redis connection timed out after ${env.REDIS_CONNECTION_TIMEOUT_MS}ms`)),
            env.REDIS_CONNECTION_TIMEOUT_MS
          );
        })
      ]);
      this.connected = true;
      this.lastHealth = { connected: true, latencyMs: 0 };
      return true;
    } catch (error) {
      this.connected = false;
      this.lastHealth = {
        connected: false,
        latencyMs: -1,
        error: error instanceof Error ? error.message : String(error)
      };
      log.warn("redis unavailable; continuing without redis");
      clients.forEach((client) => client.disconnect());
      return false;
    }
  }

  startHealthChecks(intervalMs = env.REDIS_HEALTH_CHECK_INTERVAL_MS): void {
    if (!this.client) return;
    const check = async () => {
      this.lastHealth = await this.healthCheck();
      if (!this.lastHealth.connected) {
        log.warn(this.lastHealth, "redis health check failed");
      }
    };
    void check();
    this.healthTimer = setInterval(() => void check(), intervalMs);
  }

  stopHealthChecks(): void {
    if (this.healthTimer) clearInterval(this.healthTimer);
    this.healthTimer = null;
  }

  async timedCommand<T>(command: string, fn: () => Promise<T>): Promise<T> {
    const start = process.hrtime.bigint();
    try {
      return await fn();
    } finally {
      observeRedisLatency(command, Number(process.hrtime.bigint() - start) / 1e9);
    }
  }

  async healthCheck(): Promise<RedisHealth> {
    if (!this.command) {
      return { connected: false, latencyMs: -1, error: "REDIS_NOT_CONFIGURED" };
    }

    if (!this.connected) {
      return this.lastHealth;
    }

    const start = Date.now();
    try {
      await this.timedCommand("ping", () => this.command!.ping());
      const info = await this.timedCommand("info", () => this.command!.info("memory"));
      const match = /used_memory:(\d+)/.exec(info);
      const health: RedisHealth = {
        connected: true,
        latencyMs: Date.now() - start
      };
      if (match?.[1]) {
        health.memoryUsedBytes = Number(match[1]);
      }
      return health;
    } catch (error: unknown) {
      return {
        connected: false,
        latencyMs: Date.now() - start,
        error: error instanceof Error ? error.message : String(error)
      };
    }
  }

  getLastHealth(): RedisHealth {
    return this.lastHealth;
  }

  async withLock<T>(key: string, ttlMs: number, fn: () => Promise<T>): Promise<T> {
    if (!this.command) return fn();

    const token = crypto.randomUUID();
    const lockKey = `lock:${key}`;
    const acquired = await this.command.set(lockKey, token, "PX", ttlMs, "NX");
    if (!acquired) {
      throw new Error("REDIS_LOCK_BUSY");
    }

    try {
      return await fn();
    } finally {
      const current = await this.command.get(lockKey);
      if (current === token) {
        await this.command.del(lockKey);
      }
    }
  }

  async publish(channel: string, message: string): Promise<void> {
    if (!this.pub) return;
    await this.pub.publish(channel, message);
  }

  async subscribe(channel: string, handler: (message: string) => void): Promise<void> {
    if (!this.sub) return;
    await this.sub.subscribe(channel);
    this.sub.on("message", (receivedChannel, message) => {
      if (receivedChannel === channel) handler(message);
    });
  }

  async shutdown(): Promise<void> {
    this.stopHealthChecks();
    await Promise.all(
      [this.command, this.pub, this.sub]
        .filter((c): c is Redis => c !== null)
        .map((c) => c.quit().catch(() => undefined))
    );
  }
}

let manager: RedisManager | null = null;

export function getRedisManager(): RedisManager {
  if (!manager) {
    manager = new RedisManager();
  }
  return manager;
}

/** @deprecated Use getRedisManager().client */
export const redis = getRedisManager().client;
