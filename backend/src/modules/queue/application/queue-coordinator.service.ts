import type { AuthUser } from "../../auth/domain/auth.types.js";
import type { EnqueueDto } from "./queue.schemas.js";
import type { QueueEngineService } from "./queue-engine.service.js";

/** Facade over {@link QueueEngineService} for HTTP controllers. */
export class QueueCoordinator {
  constructor(private readonly engine: QueueEngineService) {}

  enqueue(user: AuthUser, dto: EnqueueDto) {
    return this.engine.reserveQueue(user, {
      shopId: dto.shopId,
      serviceId: dto.serviceId,
      userId: dto.clientId ?? user.id,
      barberId: dto.barberId,
      walkIn: dto.walkIn
    });
  }

  checkIn(user: AuthUser, bookingId: string) {
    return this.engine.checkIn(user, bookingId);
  }

  rebalance(shopId: string) {
    return this.engine.rebalanceShop(shopId);
  }

  markInService(user: AuthUser, bookingId: string) {
    return this.engine.startService(user, bookingId);
  }

  complete(user: AuthUser, bookingId: string) {
    return this.engine.completeService(user, bookingId);
  }

  skip(user: AuthUser, bookingId: string) {
    return this.engine.markNoShow(user, bookingId);
  }

  list(shopId: string) {
    return this.engine.getShopSnapshot(shopId);
  }
}
