import { PrismaNotificationRepository } from "./infrastructure/notification.repository.js";
import { NotificationService } from "./application/notification.service.js";
export function buildNotificationDependencies(app) {
    const repository = new PrismaNotificationRepository();
    const service = new NotificationService(repository, app.socketPublisher);
    return { repository, service };
}
