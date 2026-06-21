// Notification module disabled - NotificationToken and NotificationLog models do not exist in Prisma schema

export class PrismaNotificationRepository {
  async upsertToken(userId: string, input: { token: string; platform?: string; deviceId?: string }): Promise<{ token: string }> {
    throw new Error("Notification module disabled - NotificationToken model does not exist in Prisma schema");
  }

  async deactivateToken(token: string): Promise<void> {
    throw new Error("Notification module disabled - NotificationToken model does not exist in Prisma schema");
  }

  async listActiveTokens(userId: string): Promise<{ token: string }[]> {
    throw new Error("Notification module disabled - NotificationToken model does not exist in Prisma schema");
  }

  async createLog(data: {
    userId: string;
    type: string;
    title: string;
    body: string;
    data?: unknown;
    status: string;
  }): Promise<{ id: string }> {
    throw new Error("Notification module disabled - NotificationLog model does not exist in Prisma schema");
  }

  async markSent(id: string, providerMessageId?: string): Promise<void> {
    throw new Error("Notification module disabled - NotificationLog model does not exist in Prisma schema");
  }

  async markFailed(id: string, errorMessage: string, retryCount: number, nextRetryAt?: Date | null): Promise<void> {
    throw new Error("Notification module disabled - NotificationLog model does not exist in Prisma schema");
  }

  async dueRetries(limit = 100): Promise<{ id: string; userId: string; type: string; title: string; body: string; data: unknown }[]> {
    throw new Error("Notification module disabled - NotificationLog model does not exist in Prisma schema");
  }
}
