import type { Redis as RedisClient } from "ioredis";
import type { RealtimeEnvelope, RealtimeEventName } from "./socket.contracts.js";
import { SOCKET_EVENT_LOG_MAX } from "./socket.config.js";

function shopLogKey(shopId: string): string {
  return `shop:${shopId}:eventlog`;
}

function shopSeqKey(shopId: string): string {
  return `shop:${shopId}:event:seq`;
}

function userLogKey(userId: string): string {
  return `user:${userId}:eventlog`;
}

function userSeqKey(userId: string): string {
  return `user:${userId}:event:seq`;
}

export class SocketEventJournal {
  constructor(private readonly redis: RedisClient | null) {}

  isEnabled(): boolean {
    return this.redis != null;
  }

  async nextShopSeq(shopId: string): Promise<number> {
    if (!this.redis) return Date.now();
    return this.redis.incr(shopSeqKey(shopId));
  }

  async nextUserSeq(userId: string): Promise<number> {
    if (!this.redis) return Date.now();
    return this.redis.incr(userSeqKey(userId));
  }

  async appendShopEvent(shopId: string, envelope: RealtimeEnvelope): Promise<void> {
    if (!this.redis) return;
    const key = shopLogKey(shopId);
    const payload = JSON.stringify(envelope);
    await this.redis.zadd(key, envelope.seq, payload);
    const count = await this.redis.zcard(key);
    if (count > SOCKET_EVENT_LOG_MAX) {
      await this.redis.zpopmin(key, count - SOCKET_EVENT_LOG_MAX);
    }
  }

  async appendUserEvent(userId: string, envelope: RealtimeEnvelope): Promise<void> {
    if (!this.redis) return;
    const key = userLogKey(userId);
    const payload = JSON.stringify(envelope);
    await this.redis.zadd(key, envelope.seq, payload);
    const count = await this.redis.zcard(key);
    if (count > SOCKET_EVENT_LOG_MAX) {
      await this.redis.zpopmin(key, count - SOCKET_EVENT_LOG_MAX);
    }
  }

  async getShopEventsSince(shopId: string, afterSeq: number, limit = 100): Promise<RealtimeEnvelope[]> {
    if (!this.redis) return [];
    const raw = await this.redis.zrangebyscore(
      shopLogKey(shopId),
      afterSeq > 0 ? `(${afterSeq}` : "-inf",
      "+inf",
      "LIMIT",
      0,
      limit
    );
    return raw.map(parseEnvelope).filter((e): e is RealtimeEnvelope => e != null);
  }

  async getUserEventsSince(userId: string, afterSeq: number, limit = 100): Promise<RealtimeEnvelope[]> {
    if (!this.redis) return [];
    const raw = await this.redis.zrangebyscore(
      userLogKey(userId),
      afterSeq > 0 ? `(${afterSeq}` : "-inf",
      "+inf",
      "LIMIT",
      0,
      limit
    );
    return raw.map(parseEnvelope).filter((e): e is RealtimeEnvelope => e != null);
  }

  async currentShopSeq(shopId: string): Promise<number> {
    if (!this.redis) return 0;
    const v = await this.redis.get(shopSeqKey(shopId));
    return v ? Number(v) : 0;
  }

  async currentUserSeq(userId: string): Promise<number> {
    if (!this.redis) return 0;
    const v = await this.redis.get(userSeqKey(userId));
    return v ? Number(v) : 0;
  }
}

function parseEnvelope(raw: string): RealtimeEnvelope | null {
  try {
    const parsed = JSON.parse(raw) as RealtimeEnvelope;
    if (typeof parsed.seq !== "number" || typeof parsed.event !== "string") return null;
    return parsed;
  } catch {
    return null;
  }
}
