import type { FastifyInstance } from "fastify";
import { PrismaBookingRepository } from "./infrastructure/booking.repository.js";
import { BookingService } from "./application/booking.service.js";
import { BookingCompletionCascade } from "./application/booking-completion.cascade.js";
import type { QueueEngineService } from "../queue/application/queue-engine.service.js";
import type { LoyaltyService } from "../loyalty/application/loyalty.service.js";
import type { NotificationService } from "../notification/application/notification.service.js";

export interface BookingCascadeServices {
  loyalty: LoyaltyService;
  notification: NotificationService;
}

export function buildBookingDependencies(
  engine: QueueEngineService,
  cascadeServices?: BookingCascadeServices
) {
  const repository = new PrismaBookingRepository();
  const cascade = cascadeServices
    ? new BookingCompletionCascade(cascadeServices.loyalty, cascadeServices.notification)
    : undefined;
  const service = new BookingService(repository, engine, cascade);

  return { repository, service };
}

export function buildBookingDependenciesFromApp(app: FastifyInstance) {
  return buildBookingDependencies(app.queueDeps.engine, {
    loyalty: app.loyaltyDeps.service,
    notification: app.notificationDeps.service
  });
}

declare module "fastify" {
  interface FastifyInstance {
    bookingDeps: ReturnType<typeof buildBookingDependencies>;
  }
}
