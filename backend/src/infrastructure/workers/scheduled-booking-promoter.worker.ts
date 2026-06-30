/**
 * ScheduledBookingPromoterWorker
 *
 * Sweeps SCHEDULED bookings whose scheduledStart is ≤ 25 minutes from now
 * and promotes them to QUEUED by creating a QueueEntry and updating status.
 * Sends a "Leave Now" FCM push once promoted.
 */

import type { EventLogType } from "@prisma/client";
import { prisma } from "../../shared/prisma/client.js";
import { createModuleLogger } from "../logging/structured-logger.js";
import type { NotificationService } from "../../modules/notification/application/notification.service.js";
import { getEventLogService } from "../events/event-log.service.js";

const log = createModuleLogger("scheduled-booking-promoter");
const PROMOTE_WINDOW_MINUTES = 25;

export class ScheduledBookingPromoterWorker {
  private timer: ReturnType<typeof setInterval> | null = null;

  constructor(
    private readonly notification: NotificationService,
    private readonly intervalMs = 2 * 60 * 1000
  ) {}

  async sweep(): Promise<void> {
    const now = new Date();
    const cutoff = new Date(now.getTime() + PROMOTE_WINDOW_MINUTES * 60_000);

    const bookings = await prisma.booking.findMany({
      where: {
        status: "SCHEDULED",
        scheduledStart: { lte: cutoff }
      },
      include: {
        service: { select: { durationMinutes: true, category: true } },
        shop: { select: { name: true, address: true } }
      },
      take: 100
    });

    for (const booking of bookings) {
      try {
        await prisma.$transaction(async (tx) => {
          // Re-read inside transaction to guard against concurrent promotion
          const locked = await tx.booking.findUnique({
            where: { id: booking.id },
            select: { status: true }
          });
          if (locked?.status !== "SCHEDULED") return;

          const lane = booking.walkIn ? "WALKIN" : "BOOKBER";

          const maxEntry = await tx.queueEntry.findFirst({
            where: { shopId: booking.shopId, lane },
            orderBy: { position: "desc" },
            select: { position: true }
          });
          const position = (maxEntry?.position ?? 0) + 1;

          await tx.queueEntry.create({
            data: {
              shopId: booking.shopId,
              bookingId: booking.id,
              ...(booking.barberId ? { barberId: booking.barberId } : {}),
              lane,
              position,
              queueStatus: "WAITING",
              estimatedWaitMinutes: 0,
              estimatedServiceStart: booking.scheduledStart ?? now
            }
          });

          await tx.booking.update({
            where: { id: booking.id },
            data: { status: "QUEUED" }
          });
        });

        const minutesUntil = booking.scheduledStart
          ? Math.round((booking.scheduledStart.getTime() - now.getTime()) / 60_000)
          : PROMOTE_WINDOW_MINUTES;

        await this.notification.send({
          userId: booking.userId,
          type: "BOOKING_REMINDER",
          title: `Leave now for ${booking.shop.name}`,
          body: `Your appointment starts in ~${minutesUntil} min. Head to ${booking.shop.address}.`,
          data: {
            bookingId: booking.id,
            shopId: booking.shopId,
            action: "OPEN_QUEUE_TRACKER",
            type: "LEAVE_NOW"
          }
        });

        getEventLogService().recordAsync({
          type: "LEAVE_NOW_SENT" as EventLogType,
          shopId: booking.shopId,
          bookingId: booking.id,
          userId: booking.userId,
          payload: { minutesUntil }
        });

        log.info({ bookingId: booking.id, minutesUntil }, "scheduled booking promoted to queue");
      } catch (err) {
        log.error({ err, bookingId: booking.id }, "failed to promote scheduled booking");
      }
    }
  }

  start(): () => void {
    this.sweep().catch((err) => log.error({ err }, "initial sweep failed"));
    this.timer = setInterval(() => {
      this.sweep().catch((err) => log.error({ err }, "sweep failed"));
    }, this.intervalMs);
    log.info({ intervalMs: this.intervalMs }, "scheduled booking promoter started");
    return () => this.stop();
  }

  stop(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
      log.info("scheduled booking promoter stopped");
    }
  }
}
