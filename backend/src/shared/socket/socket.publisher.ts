import type { Server } from "socket.io";
import { REALTIME_NAMESPACE } from "./socket.config.js";
import { REALTIME_EVENTS, type RealtimeEnvelope } from "./socket.contracts.js";
import { SocketEventJournal } from "./socket.event-journal.js";
import { socketRooms } from "./socket.rooms.js";
import type {
  BookingCalledPayload,
  BookingCompletedPayload,
  BookingCreatedPayload,
  ChairUpdatedPayload,
  QueueUpdatedPayload,
  RealtimeEventPayloadMap,
  WaitUpdatedPayload
} from "./socket.types.js";

export class SocketEventPublisher {
  constructor(
    private readonly io: Server,
    private readonly journal: SocketEventJournal
  ) {}

  private realtimeNs() {
    return this.io.of(REALTIME_NAMESPACE);
  }

  private async publish<E extends keyof RealtimeEventPayloadMap>(
    event: E,
    payload: RealtimeEventPayloadMap[E],
    options?: { userId?: string | null; barberId?: string | null }
  ): Promise<RealtimeEnvelope<E>> {
    const shopId = payload.shopId;
    const seq = await this.journal.nextShopSeq(shopId);
    const envelope: RealtimeEnvelope<E> = {
      seq,
      eventId: `${shopId}:${seq}`,
      event,
      payload,
      shopId,
      emittedAt: new Date().toISOString()
    };

    await this.journal.appendShopEvent(shopId, envelope as RealtimeEnvelope);

    const nsp = this.realtimeNs();
    nsp.to(socketRooms.shop(shopId)).emit(event, envelope);

    const barberId = options?.barberId ?? ("barberId" in payload ? payload.barberId : null);
    if (barberId) {
      nsp.to(socketRooms.barber(barberId)).emit(event, envelope);
    }

    const userId = options?.userId ?? ("userId" in payload ? payload.userId : null);
    if (userId) {
      const userSeq = await this.journal.nextUserSeq(userId);
      const userEnvelope: RealtimeEnvelope<E> = {
        ...envelope,
        seq: userSeq,
        eventId: `${userId}:${userSeq}`
      };
      await this.journal.appendUserEvent(userId, userEnvelope as RealtimeEnvelope);
      nsp.to(socketRooms.user(userId)).emit(event, userEnvelope);
    }

    return envelope;
  }

  emitQueueUpdated(payload: QueueUpdatedPayload) {
    return this.publish(REALTIME_EVENTS.QUEUE_UPDATED, payload);
  }

  emitWaitUpdated(payload: WaitUpdatedPayload) {
    return this.publish(REALTIME_EVENTS.WAIT_UPDATED, payload);
  }

  emitBookingCreated(payload: BookingCreatedPayload) {
    return this.publish(REALTIME_EVENTS.BOOKING_CREATED, payload, {
      userId: payload.userId,
      barberId: payload.barberId
    });
  }

  emitBookingCalled(payload: BookingCalledPayload) {
    return this.publish(REALTIME_EVENTS.BOOKING_CALLED, payload, {
      userId: payload.userId,
      barberId: payload.barberId
    });
  }

  emitBookingCompleted(payload: BookingCompletedPayload) {
    return this.publish(REALTIME_EVENTS.BOOKING_COMPLETED, payload, {
      userId: payload.userId,
      barberId: payload.barberId
    });
  }

  emitChairUpdated(payload: ChairUpdatedPayload) {
    return this.publish(REALTIME_EVENTS.CHAIR_UPDATED, payload);
  }

  /** @deprecated use typed emit methods — envelope broadcast */
  emitToRoom(room: string, event: string, payload: unknown) {
    this.realtimeNs().to(room).emit(event as keyof RealtimeEventPayloadMap, payload as never);
  }

  emitToUser(userId: string, event: string, payload: unknown) {
    this.realtimeNs().to(socketRooms.user(userId)).emit(event as keyof RealtimeEventPayloadMap, payload as never);
  }
}
