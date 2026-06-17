import { prisma } from "../../shared/prisma/client.js";
import { createModuleLogger } from "../logging/structured-logger.js";
import type { NotificationService } from "../../modules/notification/application/notification.service.js";

const log = createModuleLogger("smart-notification-worker");

const APPOINTMENT_REMINDER_MINUTES = 30;

/**
 * Smart Arrival Notification Worker
 *
 * Two responsibilities:
 * 1. Queue-proximity alerts — fired when a customer reaches position ≤ 2.
 *    Called from the queue engine after each rebalance via the event bus.
 *
 * 2. Appointment reminders — periodic sweep that finds bookings whose
 *    arrivalWindowStart is ~30 min from now and sends a "leave now" push.
 */
export class SmartNotificationWorker {
  private timer: ReturnType<typeof setInterval> | null = null;

  constructor(
    private readonly notification: NotificationService,
    private readonly reminderIntervalMs = 5 * 60 * 1000
  ) {}

  // Called directly from QueueRealtimeEmitter after every position change.
  async onPositionChanged(event: {
    shopId: string;
    bookingId: string;
    userId: string;
    position: number;
    estimatedWaitMinutes: number;
  }): Promise<void> {
    if (event.position > 2) return;

    const label = event.position === 1 ? "You're next!" : "Almost your turn";
    const body =
      event.position === 1
        ? "Please head to the shop — you're up next."
        : `You're #${event.position} in queue. Estimated wait: ${event.estimatedWaitMinutes} min.`;

    try {
      await this.notification.send({
        userId: event.userId,
        type: "ARRIVAL_ALERT",
        title: label,
        body,
        data: {
          shopId: event.shopId,
          bookingId: event.bookingId,
          position: String(event.position),
          estimatedWaitMinutes: String(event.estimatedWaitMinutes),
          type: "ARRIVAL_ALERT",
        },
      });
    } catch (err) {
      log.error({ err, userId: event.userId, position: event.position }, "arrival alert send failed");
    }
  }

  // Sweeps for bookings whose arrival window opens in ~30 min.
  async sweepAppointmentReminders(): Promise<void> {
    const now = new Date();
    const windowOpen = new Date(now.getTime() + APPOINTMENT_REMINDER_MINUTES * 60_000);
    const windowClose = new Date(windowOpen.getTime() + 5 * 60_000);

    const upcoming = await prisma.booking.findMany({
      where: {
        status: "QUEUED",
        walkIn: false,
        arrivalWindowStart: { gte: windowOpen, lt: windowClose },
      },
      select: {
        id: true,
        userId: true,
        shopId: true,
        arrivalWindowStart: true,
        shop: { select: { name: true, address: true } },
      },
      take: 200,
    });

    for (const booking of upcoming) {
      try {
        const minutesUntil = Math.round(
          (booking.arrivalWindowStart.getTime() - now.getTime()) / 60_000
        );

        await this.notification.send({
          userId: booking.userId,
          type: "BOOKING_REMINDER",
          title: `Your appointment at ${booking.shop.name}`,
          body: `Leave now — your slot opens in ${minutesUntil} min at ${booking.shop.address}.`,
          data: {
            shopId: booking.shopId,
            bookingId: booking.id,
            type: "BOOKING_REMINDER",
          },
        });
      } catch (err) {
        log.error({ err, bookingId: booking.id }, "appointment reminder send failed");
      }
    }

    if (upcoming.length > 0) {
      log.info({ count: upcoming.length }, "appointment reminders sent");
    }
  }

  start(): () => void {
    this.timer = setInterval(() => {
      this.sweepAppointmentReminders().catch((err) =>
        log.error({ err }, "appointment reminder sweep failed")
      );
    }, this.reminderIntervalMs);

    this.sweepAppointmentReminders().catch(() => undefined);

    log.info({ reminderIntervalMs: this.reminderIntervalMs }, "smart notification worker started");
    return () => this.stop();
  }

  stop(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
      log.info("smart notification worker stopped");
    }
  }
}
