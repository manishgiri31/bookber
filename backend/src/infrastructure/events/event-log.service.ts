import type { EventLogType, Prisma } from "@prisma/client";
import { prisma } from "../../shared/prisma/prisma.js";
import { getRequestContext } from "../logging/request-context.js";
import { createModuleLogger } from "../logging/structured-logger.js";

const log = createModuleLogger("event-log");

export const EVENT_LOG_TYPES = {
  BOOKING_CREATED: "BOOKING_CREATED",
  BOOKING_CANCELLED: "BOOKING_CANCELLED",
  QUEUE_JOINED: "QUEUE_JOINED",
  QUEUE_LEFT: "QUEUE_LEFT",
  CHAIR_ASSIGNED: "CHAIR_ASSIGNED",
  CHAIR_RELEASED: "CHAIR_RELEASED"
} as const satisfies Record<string, EventLogType>;

export type EventLogInput = {
  type: EventLogType;
  shopId?: string | null;
  bookingId?: string | null;
  userId?: string | null;
  chairId?: string | null;
  payload?: Prisma.InputJsonValue;
  correlationId?: string | null;
};

export class EventLogService {
  async record(input: EventLogInput): Promise<void> {
    const correlationId = input.correlationId ?? getRequestContext()?.correlationId ?? null;
    try {
      await prisma.eventLog.create({
        data: {
          type: input.type,
          shopId: input.shopId ?? null,
          bookingId: input.bookingId ?? null,
          userId: input.userId ?? null,
          chairId: input.chairId ?? null,
          correlationId,
          payload: input.payload ?? {}
        }
      });
    } catch (error: unknown) {
      log.error({ err: error, type: input.type }, "failed to persist event log");
    }
  }

  /** Fire-and-forget helper for hot paths */
  recordAsync(input: EventLogInput): void {
    void this.record(input);
  }
}

let service: EventLogService | null = null;

export function getEventLogService(): EventLogService {
  if (!service) service = new EventLogService();
  return service;
}

/** Human-readable event names for external consumers */
export function eventLogTypeLabel(type: EventLogType): string {
  switch (type) {
    case "BOOKING_CREATED":
      return "booking.created";
    case "BOOKING_CANCELLED":
      return "booking.cancelled";
    case "QUEUE_JOINED":
      return "queue.joined";
    case "QUEUE_LEFT":
      return "queue.left";
    case "CHAIR_ASSIGNED":
      return "chair.assigned";
    case "CHAIR_RELEASED":
      return "chair.released";
    default:
      return type;
  }
}
