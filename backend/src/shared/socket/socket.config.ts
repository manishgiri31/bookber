/** Client namespace for mobile/web realtime */
export const REALTIME_NAMESPACE = "/realtime" as const;

/** Internal ops dashboards (same auth, optional stricter roles later) */
import { env } from "../config/env.js";

export const OPS_NAMESPACE = "/ops" as const;

/** Application-level heartbeat (client `ping` → server `heartbeat`) */
export const SOCKET_HEARTBEAT_MS = env.SOCKET_HEARTBEAT_MS;

/** Disconnect local sockets with no app heartbeat within this window */
export const SOCKET_STALE_MS = env.SOCKET_STALE_MS;

/** Stale-socket sweep interval */
export const SOCKET_STALE_SWEEP_MS = env.SOCKET_STALE_SWEEP_MS;

/** Max events retained per shop/user log for sync recovery */
export const SOCKET_EVENT_LOG_MAX = env.SOCKET_EVENT_LOG_MAX;

/** Default events returned on sync when client sends lastSeq=0 */
export const SOCKET_SYNC_DEFAULT_LIMIT = env.SOCKET_SYNC_DEFAULT_LIMIT;
