import type { FastifyInstance } from "fastify";
import { PrismaNotificationRepository } from "./infrastructure/notification.repository.js";
import { NotificationService } from "./application/notification.service.js";

export function buildNotificationDependencies(app: FastifyInstance) {
  const repository = new PrismaNotificationRepository();
  const service = new NotificationService(repository, app.socketPublisher);

  return { repository, service };
}

declare module "fastify" {
  interface FastifyInstance {
    notificationDeps: ReturnType<typeof buildNotificationDependencies>;
  }
}
