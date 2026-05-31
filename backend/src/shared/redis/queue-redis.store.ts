import type { Redis as RedisClient } from "ioredis";
import type { QueueLane } from "@prisma/client";
import { waitTimeRedisKeys } from "./wait-time-redis.keys.js";

export type RedisQueueMember = {
  bookingId: string;
  lane: QueueLane;
  position: number;
  estimatedWaitMinutes: number;
  queueStatus: string;
  userId: string;
  serviceId: string;
  barberId: string | null;
};

function chairKey(chairId: string): string {
  return `chair:${chairId}`;
}

/**
 * Legacy facade — queue keys are shared with {@link waitTimeRedisKeys}.
 */
export class QueueRedisStore {
  constructor(private readonly redis: RedisClient | null) {}

  async enqueueMember(shopId: string, member: RedisQueueMember): Promise<void> {
    if (!this.redis) return;
    const key = waitTimeRedisKeys.queue(shopId, member.lane);
    await this.redis.zadd(key, member.position, member.bookingId);
    await this.redis.hset(waitTimeRedisKeys.booking(member.bookingId), {
      shopId,
      lane: member.lane,
      position: String(member.position),
      estimatedWaitMinutes: String(member.estimatedWaitMinutes),
      queueStatus: member.queueStatus,
      userId: member.userId,
      serviceId: member.serviceId,
      barberId: member.barberId ?? ""
    });
  }

  async removeMember(shopId: string, lane: QueueLane, bookingId: string): Promise<void> {
    if (!this.redis) return;
    await this.redis.zrem(waitTimeRedisKeys.queue(shopId, lane), bookingId);
    await this.redis.del(waitTimeRedisKeys.booking(bookingId));
  }

  async updatePosition(
    shopId: string,
    lane: QueueLane,
    bookingId: string,
    position: number,
    estimatedWaitMinutes: number
  ): Promise<void> {
    if (!this.redis) return;
    const key = waitTimeRedisKeys.queue(shopId, lane);
    await this.redis.zadd(key, position, bookingId);
    await this.redis.hset(waitTimeRedisKeys.booking(bookingId), {
      position: String(position),
      estimatedWaitMinutes: String(estimatedWaitMinutes)
    });
  }

  async listQueue(shopId: string, lane: QueueLane): Promise<string[]> {
    if (!this.redis) return [];
    return this.redis.zrange(waitTimeRedisKeys.queue(shopId, lane), 0, -1);
  }

  async setChairCache(args: {
    chairId: string;
    shopId: string;
    status: string;
    reservedForBookBer: boolean;
    bookingId: string | null;
    activeServiceStart: string | null;
    activeServiceEnd: string | null;
  }): Promise<void> {
    if (!this.redis) return;
    await this.redis.hset(chairKey(args.chairId), {
      shopId: args.shopId,
      status: args.status,
      reservedForBookBer: args.reservedForBookBer ? "1" : "0",
      bookingId: args.bookingId ?? "",
      activeServiceStart: args.activeServiceStart ?? "",
      activeServiceEnd: args.activeServiceEnd ?? ""
    });
  }

  async getChairCache(chairId: string): Promise<Record<string, string> | null> {
    if (!this.redis) return null;
    const data = await this.redis.hgetall(chairKey(chairId));
    return Object.keys(data).length > 0 ? data : null;
  }

  async bumpShopQueueVersion(shopId: string): Promise<number> {
    if (!this.redis) return 0;
    return this.redis.incr(waitTimeRedisKeys.queueVersion(shopId));
  }

  async getShopQueueVersion(shopId: string): Promise<number> {
    if (!this.redis) return 0;
    const v = await this.redis.get(waitTimeRedisKeys.queueVersion(shopId));
    return v ? Number(v) : 0;
  }
}
