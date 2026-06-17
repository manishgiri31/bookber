import { prisma } from "../../shared/prisma/client.js";
import { createModuleLogger } from "../logging/structured-logger.js";
import { EVENT_LOG_TYPES, getEventLogService } from "../events/event-log.service.js";

const log = createModuleLogger("no-show-appointment-worker");

export type NoShowWorkerConfig = {
  gracePeriodMinutes: number;
  intervalMs: number;
  batchSize: number;
};

const DEFAULT_CONFIG: NoShowWorkerConfig = {
  gracePeriodMinutes: 15,
  intervalMs: 2 * 60 * 1000,
  batchSize: 50,
};

/**
 * Detects bookings in QUEUED status whose arrival window has expired
 * without the customer checking in. Marks them NO_SHOW and advances
 * the queue for all affected shops.
 *
 * Distinct from StaleServiceDetectorWorker which handles bookings already
 * IN_SERVICE that ran too long.
 */
export class NoShowAppointmentWorker {
  private readonly config: NoShowWorkerConfig;
  private timer: ReturnType<typeof setInterval> | null = null;

  constructor(config: Partial<NoShowWorkerConfig> = {}) {
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  async run(): Promise<{ detected: number; errors: number }> {
    const cutoff = new Date(Date.now() - this.config.gracePeriodMinutes * 60_000);
    let detected = 0;
    let errors = 0;

    try {
      const expired = await prisma.booking.findMany({
        where: {
          status: "QUEUED",
          arrivalWindowEnd: { lt: cutoff },
          walkIn: false,
        },
        select: {
          id: true,
          shopId: true,
          userId: true,
          barberId: true,
          chairId: true,
          queueEntry: { select: { id: true, lane: true } },
        },
        take: this.config.batchSize,
      });

      if (expired.length === 0) return { detected: 0, errors: 0 };

      log.info({ count: expired.length, cutoff }, "no-show candidates found");

      for (const booking of expired) {
        try {
          await prisma.$transaction(async (tx) => {
            await tx.$executeRaw`SELECT id FROM "Booking" WHERE id = ${booking.id} FOR UPDATE NOWAIT`;

            const fresh = await tx.booking.findUnique({
              where: { id: booking.id },
              select: { status: true },
            });

            if (fresh?.status !== "QUEUED") return;

            await tx.booking.update({
              where: { id: booking.id },
              data: { status: "NO_SHOW", noShowAt: new Date() },
            });

            if (booking.queueEntry) {
              await tx.queueEntry.update({
                where: { id: booking.queueEntry.id },
                data: { queueStatus: "NO_SHOW", version: { increment: 1 } },
              });
            }

            if (booking.chairId) {
              await tx.chair.update({
                where: { id: booking.chairId },
                data: {
                  status: "AVAILABLE",
                  activeServiceStart: null,
                  activeServiceEnd: new Date(),
                },
              });
              await tx.chairAllocation.updateMany({
                where: { chairId: booking.chairId, bookingId: booking.id, releasedAt: null },
                data: { releasedAt: new Date() },
              });
            }

            await tx.queueEvent.create({
              data: {
                shopId: booking.shopId,
                bookingId: booking.id,
                type: "NO_SHOW",
                payload: { source: "no_show_appointment_worker", gracePeriodMinutes: this.config.gracePeriodMinutes },
              },
            });
          });

          getEventLogService().recordAsync({
            type: EVENT_LOG_TYPES.BOOKING_NO_SHOW,
            shopId: booking.shopId,
            bookingId: booking.id,
            userId: booking.userId,
            payload: { source: "no_show_appointment_worker" },
          });

          detected++;
          log.info({ bookingId: booking.id, shopId: booking.shopId }, "booking marked no-show");
        } catch (err) {
          if (err instanceof Error && err.message.includes("could not obtain lock")) {
            log.debug({ bookingId: booking.id }, "skip — locked by another worker");
          } else {
            errors++;
            log.error({ err, bookingId: booking.id }, "failed to mark no-show");
          }
        }
      }
    } catch (err) {
      errors++;
      log.error({ err }, "no-show appointment worker run failed");
    }

    if (detected > 0) {
      log.info({ detected, errors }, "no-show sweep complete");
    }

    return { detected, errors };
  }

  start(): () => void {
    this.run().catch((err) => log.error({ err }, "initial no-show sweep failed"));
    this.timer = setInterval(() => {
      this.run().catch((err) => log.error({ err }, "no-show sweep failed"));
    }, this.config.intervalMs);

    log.info(
      { intervalMs: this.config.intervalMs, gracePeriodMinutes: this.config.gracePeriodMinutes },
      "no-show appointment worker started"
    );

    return () => this.stop();
  }

  stop(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
      log.info("no-show appointment worker stopped");
    }
  }
}
