import type { QueueSnapshotEntry } from "../../modules/queue/domain/queue.types.js";
import type { RealtimeEnvelope, RealtimeEventName } from "./socket.contracts.js";

export type SocketUser = {
  userId: string;
  role: "CLIENT" | "BARBER" | "ADMIN";
  shopIds: string[];
};

export type QueueUpdatedPayload = {
  shopId: string;
  version: number;
  bookBer: QueueSnapshotEntry[];
  walkIn: QueueSnapshotEntry[];
};

export type WaitUpdatedPayload = {
  shopId: string;
  version: number;
  bookBer: Array<{
    bookingId: string;
    position: number;
    estimatedWaitMinutes: number;
    estimatedServiceStart: string | null;
  }>;
  walkIn: Array<{
    bookingId: string;
    position: number;
    estimatedWaitMinutes: number;
    estimatedServiceStart: string | null;
  }>;
  computedAt: string;
};

export type BookingCreatedPayload = {
  bookingId: string;
  shopId: string;
  userId: string;
  barberId: string | null;
  serviceId: string;
  status: string;
  queueLane: string;
  queuePosition: number;
  estimatedWaitMinutes: number;
  arrivalWindowStart: string;
  arrivalWindowEnd: string;
  estimatedServiceStart: string | null;
  estimatedServiceEnd: string | null;
};

export type BookingCalledPayload = {
  shopId: string;
  bookingId: string;
  userId: string;
  barberId: string | null;
  chairId: string;
  position: number;
};

export type BookingCompletedPayload = {
  shopId: string;
  bookingId: string;
  userId: string;
  barberId: string | null;
};

export type ChairUpdatedPayload = {
  id: string;
  shopId: string;
  number: number;
  status: string;
  reservedForBookBer: boolean;
  bookingId: string | null;
  activeServiceStart: string | null;
  activeServiceEnd: string | null;
};

/** Primary contract — six production events */
export type RealtimeEventPayloadMap = {
  "queue.updated": QueueUpdatedPayload;
  "wait.updated": WaitUpdatedPayload;
  "booking.created": BookingCreatedPayload;
  "booking.called": BookingCalledPayload;
  "booking.completed": BookingCompletedPayload;
  "chair.updated": ChairUpdatedPayload;
};

export type BookBerSocketEvents = {
  [K in keyof RealtimeEventPayloadMap]: RealtimeEnvelope<K>;
} & {
  "socket.ready": { socketId: string; userId: string; serverTime: string };
  "connection.state": { connected: boolean; reason?: string };
  "heartbeat": { timestamp: number; serverTime: string };
  "sync.complete": SyncRecoverResponse;
  /** Push notifications (FCM companion) */
  "notification.sent": {
    userId: string;
    title: string;
    body: string;
    data?: Record<string, string>;
  };
};

export type SyncRecoverRequest = {
  shopId: string;
  lastEventSeq: number;
  /** Optional: also replay user-scoped events */
  includeUserEvents?: boolean;
  lastUserEventSeq?: number;
};

export type SyncRecoverResponse = {
  shopId: string;
  currentShopSeq: number;
  currentUserSeq: number;
  missed: RealtimeEnvelope<RealtimeEventName>[];
  resubscribedRooms: string[];
  serverTime: string;
};

export type RoomSubscribeRequest = {
  shopId?: string;
  barberId?: string;
  userId?: string;
};

export type ClientToServerEvents = {
  "room:subscribe": RoomSubscribeRequest;
  "room:unsubscribe": RoomSubscribeRequest;
  "sync:recover": SyncRecoverRequest;
  ping: () => void;
};

export type ServerToClientEvents = BookBerSocketEvents;

export type InterServerEvents = Record<string, never>;

export type SocketData = {
  user: SocketUser;
  lastPing: number;
  subscribedShops: Set<string>;
  shopLastSeq: Map<string, number>;
};
