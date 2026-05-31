import { REALTIME_NAMESPACE } from "./socket.config.js";
import { REALTIME_EVENTS } from "./socket.contracts.js";
import { socketRooms } from "./socket.rooms.js";
export class SocketEventPublisher {
    io;
    journal;
    constructor(io, journal) {
        this.io = io;
        this.journal = journal;
    }
    realtimeNs() {
        return this.io.of(REALTIME_NAMESPACE);
    }
    async publish(event, payload, options) {
        const shopId = payload.shopId;
        const seq = await this.journal.nextShopSeq(shopId);
        const envelope = {
            seq,
            eventId: `${shopId}:${seq}`,
            event,
            payload,
            shopId,
            emittedAt: new Date().toISOString()
        };
        await this.journal.appendShopEvent(shopId, envelope);
        const nsp = this.realtimeNs();
        nsp.to(socketRooms.shop(shopId)).emit(event, envelope);
        const barberId = options?.barberId ?? ("barberId" in payload ? payload.barberId : null);
        if (barberId) {
            nsp.to(socketRooms.barber(barberId)).emit(event, envelope);
        }
        const userId = options?.userId ?? ("userId" in payload ? payload.userId : null);
        if (userId) {
            const userSeq = await this.journal.nextUserSeq(userId);
            const userEnvelope = {
                ...envelope,
                seq: userSeq,
                eventId: `${userId}:${userSeq}`
            };
            await this.journal.appendUserEvent(userId, userEnvelope);
            nsp.to(socketRooms.user(userId)).emit(event, userEnvelope);
        }
        return envelope;
    }
    emitQueueUpdated(payload) {
        return this.publish(REALTIME_EVENTS.QUEUE_UPDATED, payload);
    }
    emitWaitUpdated(payload) {
        return this.publish(REALTIME_EVENTS.WAIT_UPDATED, payload);
    }
    emitBookingCreated(payload) {
        return this.publish(REALTIME_EVENTS.BOOKING_CREATED, payload, {
            userId: payload.userId,
            barberId: payload.barberId
        });
    }
    emitBookingCalled(payload) {
        return this.publish(REALTIME_EVENTS.BOOKING_CALLED, payload, {
            userId: payload.userId,
            barberId: payload.barberId
        });
    }
    emitBookingCompleted(payload) {
        return this.publish(REALTIME_EVENTS.BOOKING_COMPLETED, payload, {
            userId: payload.userId,
            barberId: payload.barberId
        });
    }
    emitChairUpdated(payload) {
        return this.publish(REALTIME_EVENTS.CHAIR_UPDATED, payload);
    }
    /** @deprecated use typed emit methods — envelope broadcast */
    emitToRoom(room, event, payload) {
        this.realtimeNs().to(room).emit(event, payload);
    }
    emitToUser(userId, event, payload) {
        this.realtimeNs().to(socketRooms.user(userId)).emit(event, payload);
    }
}
