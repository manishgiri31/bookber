/** Facade over {@link QueueEngineService} for HTTP controllers. */
export class QueueCoordinator {
    engine;
    constructor(engine) {
        this.engine = engine;
    }
    enqueue(user, dto) {
        return this.engine.reserveQueue(user, {
            shopId: dto.shopId,
            serviceId: dto.serviceId,
            userId: dto.clientId ?? user.id,
            barberId: dto.barberId,
            walkIn: dto.walkIn
        });
    }
    checkIn(user, bookingId) {
        return this.engine.checkIn(user, bookingId);
    }
    rebalance(shopId) {
        return this.engine.rebalanceShop(shopId);
    }
    markInService(user, bookingId) {
        return this.engine.startService(user, bookingId);
    }
    complete(user, bookingId) {
        return this.engine.completeService(user, bookingId);
    }
    skip(user, bookingId) {
        return this.engine.markNoShow(user, bookingId);
    }
    list(shopId) {
        return this.engine.getShopSnapshot(shopId);
    }
}
