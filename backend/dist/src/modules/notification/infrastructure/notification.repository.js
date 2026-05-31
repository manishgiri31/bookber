// Notification module disabled - NotificationToken and NotificationLog models do not exist in Prisma schema
export class PrismaNotificationRepository {
    async upsertToken(userId, input) {
        throw new Error("Notification module disabled - NotificationToken model does not exist in Prisma schema");
    }
    async deactivateToken(token) {
        throw new Error("Notification module disabled - NotificationToken model does not exist in Prisma schema");
    }
    async listActiveTokens(userId) {
        throw new Error("Notification module disabled - NotificationToken model does not exist in Prisma schema");
    }
    async createLog(data) {
        throw new Error("Notification module disabled - NotificationLog model does not exist in Prisma schema");
    }
    async markSent(id, providerMessageId) {
        throw new Error("Notification module disabled - NotificationLog model does not exist in Prisma schema");
    }
    async markFailed(id, errorMessage, retryCount, nextRetryAt) {
        throw new Error("Notification module disabled - NotificationLog model does not exist in Prisma schema");
    }
    async dueRetries(limit = 100) {
        throw new Error("Notification module disabled - NotificationLog model does not exist in Prisma schema");
    }
}
