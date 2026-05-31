import { socketRooms } from "./socket.rooms.js";
export class SocketService {
    io;
    constructor(io) {
        this.io = io;
    }
    emit(event, payload) {
        const typedPayload = payload;
        if ("shopId" in typedPayload && typedPayload.shopId) {
            this.io.to(socketRooms.shop(typedPayload.shopId)).emit(event, payload);
        }
        if ("barberId" in typedPayload && typedPayload.barberId) {
            this.io.to(socketRooms.barber(typedPayload.barberId)).emit(event, payload);
        }
        if ("bookingId" in typedPayload && typedPayload.bookingId) {
            this.io.to(socketRooms.booking(typedPayload.bookingId)).emit(event, payload);
        }
        if ("clientId" in typedPayload && typedPayload.clientId) {
            this.io.to(socketRooms.customer(typedPayload.clientId)).emit(event, payload);
        }
    }
    joinShop(socketId, shopId) {
        return socketRooms.shop(shopId);
    }
}
