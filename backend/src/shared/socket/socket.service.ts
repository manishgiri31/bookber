import type { Server } from "socket.io";
import { socketRooms } from "./socket.rooms.js";
import type { BookBerSocketEvents } from "./socket.types.js";

export class SocketService {
  constructor(private readonly io: Server) { }

  emit<E extends keyof BookBerSocketEvents>(event: E, payload: BookBerSocketEvents[E]) {
    const typedPayload = payload as any;
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

  joinShop(socketId: string, shopId: string) {
    return socketRooms.shop(shopId);
  }
}
