import { getRedisManager } from "../../infrastructure/redis/redis-manager.js";
/** Primary Redis command client (null when REDIS_URL is unset). */
export const redis = getRedisManager().client;
