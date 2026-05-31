// Notification module disabled - NotificationToken and NotificationLog models do not exist in Prisma schema

export class PrismaNotificationRepository {
  async upsertToken(userId: string, input: { token: string; platform?: string; deviceId?: string }) {
    throw new Error("Notification module disabled - NotificationToken model does not exist in Prisma schema");
  }

  async deactivateToken(token: string) {
    throw new Error("Notification module disabled - NotificationToken model does not exist in Prisma schema");
  }

  async listActiveTokens(userId: string) {
    throw new Error("Notification module disabled - NotificationToken model does not exist in Prisma schema");
  }

  async createLog(data: any) {
    throw new Error("Notification module disabled - NotificationLog model does not exist in Prisma schema");
  }

  async markSent(id: string, providerMessageId?: string) {
    throw new Error("Notification module disabled - NotificationLog model does not exist in Prisma schema");
  }

  async markFailed(id: string, errorMessage: string, retryCount: number, nextRetryAt?: Date | null) {
    throw new Error("Notification module disabled - NotificationLog model does not exist in Prisma schema");
  }

  async dueRetries(limit = 100) {
    throw new Error("Notification module disabled - NotificationLog model does not exist in Prisma schema");
  }
}
