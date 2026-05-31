import type { FastifyInstance } from "fastify";
import { PrismaBookingRepository } from "./infrastructure/booking.repository.js";
import { BookingService } from "./application/booking.service.js";
import type { QueueEngineService } from "../queue/application/queue-engine.service.js";

export function buildBookingDependencies(engine: QueueEngineService) {
  const repository = new PrismaBookingRepository();
  const service = new BookingService(repository, engine);

  return { repository, service };
}

export function buildBookingDependenciesFromApp(app: FastifyInstance) {
  return buildBookingDependencies(app.queueDeps.engine);
}

declare module "fastify" {
  interface FastifyInstance {
    bookingDeps: ReturnType<typeof buildBookingDependencies>;
  }
}
