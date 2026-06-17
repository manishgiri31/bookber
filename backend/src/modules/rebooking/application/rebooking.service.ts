import type { RebookingRepository } from "../infrastructure/rebooking.repository.js";
import { DEFAULT_REBOOK_INTERVALS } from "../domain/rebooking.types.js";
import type { NotificationService } from "../../notification/application/notification.service.js";
import { createModuleLogger } from "../../../infrastructure/logging/structured-logger.js";

const log = createModuleLogger("rebooking-service");

export class RebookingService {
  constructor(
    private readonly repo: RebookingRepository,
    private readonly notification: NotificationService
  ) {}

  async scheduleRemindersForRecentCompletions(): Promise<number> {
    const since = new Date(Date.now() - 25 * 60 * 60 * 1000);
    const bookings = await this.repo.findCompletedBookingsSince(since);
    let scheduled = 0;

    for (const booking of bookings) {
      const intervalDays =
        booking.service.rebookIntervalDays ??
        DEFAULT_REBOOK_INTERVALS[booking.service.category] ??
        30;

      const reminderAt = new Date(booking.updatedAt.getTime() + intervalDays * 86400_000);

      try {
        await this.repo.scheduleReminder({
          userId: booking.userId,
          shopId: booking.shopId,
          serviceId: booking.serviceId,
          serviceCategory: booking.service.category,
          lastVisitAt: booking.updatedAt,
          reminderAt,
        });
        scheduled++;
      } catch (err) {
        log.error({ err, userId: booking.userId }, "failed to schedule rebooking reminder");
      }
    }

    return scheduled;
  }

  async dispatchDueReminders(): Promise<{ sent: number; errors: number }> {
    const due = await this.repo.findDueReminders();
    let sent = 0;
    let errors = 0;

    for (const reminder of due) {
      try {
        await this.notification.send({
          userId: reminder.userId,
          type: "REBOOKING_REMINDER",
          title: "Time for a fresh cut?",
          body: `Book your ${reminder.service.name} at your favourite shop.`,
          data: {
            shopId: reminder.shopId,
            serviceId: reminder.serviceId,
            reminderId: reminder.id,
            type: "REBOOKING_REMINDER",
          },
        });
        await this.repo.markSent(reminder.id);
        sent++;
      } catch (err) {
        errors++;
        log.error({ err, reminderId: reminder.id }, "failed to send rebooking reminder");
      }
    }

    if (sent > 0) {
      log.info({ sent, errors }, "rebooking reminders dispatched");
    }

    return { sent, errors };
  }
}
