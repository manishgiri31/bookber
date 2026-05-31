
import type { SocketEventPublisher } from "../../../shared/socket/socket.publisher.js";
import type { NotificationPayload } from "../domain/notification.types.js";
import { buildNotificationTemplate } from "./notification.templates.js";
import type { PrismaNotificationRepository } from "../infrastructure/notification.repository.js";
import { getMessaging } from "../infrastructure/fcm.client.js";
import { HttpError } from "../../../shared/errors/http-error.js";

function backoffMinutes(retryCount: number) {
  return Math.min(60, 2 ** retryCount);
}

export class NotificationService {
  constructor(
    private readonly repository: PrismaNotificationRepository,
    private readonly socketPublisher: SocketEventPublisher
  ) { }

  async registerToken(userId: string, input: { token: string; platform?: string; deviceId?: string }) {
    return this.repository.upsertToken(userId, input);
  }

  async deactivateToken(token: string) {
    return this.repository.deactivateToken(token);
  }

  async send(input: NotificationPayload) {
    const template = buildNotificationTemplate(input);
    const tokens = await this.repository.listActiveTokens(input.userId);
    if (tokens.length === 0) {
      return { sent: 0 };
    }

    const log = await this.repository.createLog({
      userId: input.userId,
      type: input.type,
      title: template.title,
      body: template.body,
      data: template.data,
      status: "PENDING"
    });

    try {
      const response = await getMessaging().sendEachForMulticast({
        tokens: tokens.map((token: { token: string }) => token.token),
        notification: {
          title: template.title,
          body: template.body
        },
        data: template.data
      });

      if (response.failureCount > 0) {
        const failedTokens: string[] = response.responses
          .map((item, index) => ({
            item,
            token: tokens[index],
          }))
          .filter(
            (
              entry
            ): entry is {
              item: typeof response.responses[number];
              token: (typeof tokens)[number];
            } => {
              return !entry.item.success && !!entry.token;
            }
          )
          .map((entry) => entry.token.token);

        for (const token of failedTokens as string[]) {
          await this.deactivateToken(token);
        }
      }

      await this.repository.markSent(log.id, response.responses.find((r) => r.success)?.messageId);
      this.socketPublisher.emitToUser(input.userId, "notification.sent", {
        userId: input.userId,
        type: input.type,
        title: template.title,
        body: template.body
      });
      return { sent: response.successCount };
    } catch (error) {
      const retryCount = 1;
      await this.repository.markFailed(
        log.id,
        error instanceof Error ? error.message : "FCM send failed",
        retryCount,
        new Date(Date.now() + backoffMinutes(retryCount) * 60000)
      );
      throw HttpError.conflict("Notification dispatch failed");
    }
  }

  async retryDue(limit = 100) {
    const logs = await this.repository.dueRetries(limit);
    for (const log of logs) {
      try {
        await this.send({
          userId: log.userId,
          type: log.type as any,
          title: log.title,
          body: log.body,
          data: (log.data as Record<string, string>) ?? undefined
        });
      } catch {
        // retry attempts are persisted in logs; fail closed
      }
    }
  }
}
