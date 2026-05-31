export class QueueRealtimeEmitter {
    getPublisher;
    constructor(getPublisher) {
        this.getPublisher = getPublisher;
    }
    pub() {
        return this.getPublisher();
    }
    emitBookingCreated(booking) {
        const publisher = this.pub();
        if (!publisher)
            return;
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
    emitQueueUpdated(snapshot) {
        const publisher = this.pub();
        if (!publisher)
            return;
        void publisher.emitQueueUpdated({
            shopId: snapshot.shopId,
            version: snapshot.version,
            bookBer: snapshot.bookBer,
            walkIn: snapshot.walkIn
        });
    }
    emitWaitUpdated(args) {
        const publisher = this.pub();
        if (!publisher)
            return;
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
    emitChairUpdated(chair) {
        const publisher = this.pub();
        if (!publisher)
            return;
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
    emitBookingCalled(args) {
        this.pub()?.emitBookingCalled(args);
    }
    emitBookingInService(_args) {
        /* booking.in_service reserved for future contract expansion */
    }
    emitBookingCompleted(args) {
        this.pub()?.emitBookingCompleted(args);
    }
    emitPositionChanged(args) {
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
