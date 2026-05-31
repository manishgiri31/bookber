import type { SocketEventPublisher } from "../../../shared/socket/socket.publisher.js";
import type { QueueSnapshot, ChairView } from "../domain/queue.types.js";

export class QueueRealtimeEmitter {
  constructor(private readonly getPublisher: () => SocketEventPublisher | undefined) {}

  private pub(): SocketEventPublisher | undefined {
    return this.getPublisher();
  }

  emitBookingCreated(booking: {
    id: string;
    shopId: string;
    userId: string;
    barberId: string | null;
    serviceId: string;
    status: string;
    queueLane: string;
    queuePosition: number;
    estimatedWaitMinutes: number;
    arrivalWindowStart: Date;
    arrivalWindowEnd: Date;
    estimatedServiceStart: Date | null;
    estimatedServiceEnd: Date | null;
  }): void {
    const publisher = this.pub();
    if (!publisher) return;
    void publisher.emitBookingCreated({
      bookingId: booking.id,
      shopId: booking.shopId,
      userId: booking.userId,
      barberId: booking.barberId,
      serviceId: booking.serviceId,
      status: booking.status,
      queueLane: booking.queueLane,
      queuePosition: booking.queuePosition,
      estimatedWaitMinutes: booking.estimatedWaitMinutes,
      arrivalWindowStart: booking.arrivalWindowStart.toISOString(),
      arrivalWindowEnd: booking.arrivalWindowEnd.toISOString(),
      estimatedServiceStart: booking.estimatedServiceStart?.toISOString() ?? null,
      estimatedServiceEnd: booking.estimatedServiceEnd?.toISOString() ?? null
    });
  }

  emitQueueUpdated(snapshot: QueueSnapshot): void {
    const publisher = this.pub();
    if (!publisher) return;
    void publisher.emitQueueUpdated({
      shopId: snapshot.shopId,
      version: snapshot.version,
      bookBer: snapshot.bookBer,
      walkIn: snapshot.walkIn
    });
  }

  emitWaitUpdated(args: {
    shopId: string;
    version: number;
    bookBer: Array<{
      bookingId: string;
      position: number;
      estimatedWaitMinutes: number;
      estimatedServiceStart: Date | null;
    }>;
    walkIn: Array<{
      bookingId: string;
      position: number;
      estimatedWaitMinutes: number;
      estimatedServiceStart: Date | null;
    }>;
  }): void {
    const publisher = this.pub();
    if (!publisher) return;
    void publisher.emitWaitUpdated({
      shopId: args.shopId,
      version: args.version,
      bookBer: args.bookBer.map((e) => ({
        bookingId: e.bookingId,
        position: e.position,
        estimatedWaitMinutes: e.estimatedWaitMinutes,
        estimatedServiceStart: e.estimatedServiceStart?.toISOString() ?? null
      })),
      walkIn: args.walkIn.map((e) => ({
        bookingId: e.bookingId,
        position: e.position,
        estimatedWaitMinutes: e.estimatedWaitMinutes,
        estimatedServiceStart: e.estimatedServiceStart?.toISOString() ?? null
      })),
      computedAt: new Date().toISOString()
    });
  }

  emitChairUpdated(chair: ChairView): void {
    const publisher = this.pub();
    if (!publisher) return;
    void publisher.emitChairUpdated({
      id: chair.id,
      shopId: chair.shopId,
      number: chair.number,
      status: chair.status,
      reservedForBookBer: chair.reservedForBookBer,
      bookingId: chair.bookingId,
      activeServiceStart: chair.activeServiceStart?.toISOString() ?? null,
      activeServiceEnd: chair.activeServiceEnd?.toISOString() ?? null
    });
  }

  emitBookingCalled(args: {
    shopId: string;
    bookingId: string;
    userId: string;
    barberId: string | null;
    chairId: string;
    position: number;
  }): void {
    this.pub()?.emitBookingCalled(args);
  }

  emitBookingInService(_args: {
    shopId: string;
    bookingId: string;
    userId: string;
    barberId: string | null;
    chairId: string;
  }): void {
    /* booking.in_service reserved for future contract expansion */
  }

  emitBookingCompleted(args: {
    shopId: string;
    bookingId: string;
    userId: string;
    barberId: string | null;
  }): void {
    this.pub()?.emitBookingCompleted(args);
  }

  emitPositionChanged(args: {
    shopId: string;
    bookingId: string;
    userId: string;
    barberId: string | null;
    position: number;
    estimatedWaitMinutes: number;
    estimatedServiceStart?: Date | null;
  }): void {
    this.emitWaitUpdated({
      shopId: args.shopId,
      version: Date.now(),
      bookBer: [
        {
          bookingId: args.bookingId,
          position: args.position,
          estimatedWaitMinutes: args.estimatedWaitMinutes,
          estimatedServiceStart: args.estimatedServiceStart ?? null
        }
      ],
      walkIn: []
    });
  }
}
