import type { QueueLane } from "@prisma/client";
import { prisma } from "../../../shared/prisma/client.js";
import type { RecoveryEvent, RecoveryEventType, RecoveryConfig } from "./recovery-types.js";
import { DEFAULT_RECOVERY_CONFIG } from "./recovery-types.js";

/**
 * Recovery transaction manager for safe recovery operations.
 * 
 * This manager ensures that recovery operations are performed safely
 * with proper transaction boundaries, logging, and rollback capabilities.
 */
export class RecoveryTransactionManager {
  private readonly config: RecoveryConfig;
  private readonly events: RecoveryEvent[] = [];

  constructor(config: Partial<RecoveryConfig> = {}) {
    this.config = { ...DEFAULT_RECOVERY_CONFIG, ...config };
  }

  /**
   * Log a recovery event
   */
  private logEvent(
    type: RecoveryEventType,
    shopId: string,
    severity: "INFO" | "WARNING" | "ERROR" | "CRITICAL",
    message: string,
    metadata: Record<string, unknown> = {}
  ): void {
    const event: RecoveryEvent = {
      id: crypto.randomUUID(),
      type,
      shopId,
      severity,
      message,
      metadata,
      recoveredAt: new Date()
    };
    this.events.push(event);
  }

  /**
   * Get all logged events
   */
  getEvents(): RecoveryEvent[] {
    return [...this.events];
  }

  /**
   * Clear logged events
   */
  clearEvents(): void {
    this.events.length = 0;
  }

  /**
   * Recover an orphaned chair
   */
  async recoverOrphanedChair(
    chairId: string,
    shopId: string,
    reason: string
  ): Promise<void> {
    await prisma.$transaction(async (tx) => {
      const chair = await tx.chair.findUnique({
        where: { id: chairId },
        include: { shop: true }
      });

      if (!chair) {
        this.logEvent("CHAIR_RECOVERED", shopId, "ERROR", "Chair not found", { chairId });
        throw new Error("Chair not found");
      }

      if (chair.status !== "OCCUPIED") {
        this.logEvent("CHAIR_RECOVERED", shopId, "WARNING", "Chair not occupied", { chairId, status: chair.status });
        return;
      }

      // Release any active allocation
      await tx.chairAllocation.updateMany({
        where: { chairId, releasedAt: null },
        data: { releasedAt: new Date(), activeServiceEnd: new Date() }
      });

      // Reset chair to available
      await tx.chair.update({
        where: { id: chairId },
        data: {
          status: "AVAILABLE",
          activeServiceStart: null,
          activeServiceEnd: new Date()
        }
      });

      this.logEvent("CHAIR_RECOVERED", shopId, "INFO", "Orphaned chair recovered", {
        chairId,
        number: chair.number,
        reason
      });
    });
  }

  /**
   * Flag a stale service
   */
  async flagStaleService(
    bookingId: string,
    shopId: string,
    reason: string,
    timeoutMinutes: number
  ): Promise<void> {
    await prisma.$transaction(async (tx) => {
      const booking = await tx.booking.findUnique({
        where: { id: bookingId },
        include: { queueEntry: true, chair: true }
      });

      if (!booking) {
        this.logEvent("SERVICE_FLAGGED", shopId, "ERROR", "Booking not found", { bookingId });
        throw new Error("Booking not found");
      }

      if (booking.status !== "IN_SERVICE") {
        this.logEvent("SERVICE_FLAGGED", shopId, "WARNING", "Booking not in service", { bookingId, status: booking.status });
        return;
      }

      // Add flag to booking metadata or create a recovery record
      await tx.queueEvent.create({
        data: {
          shopId,
          bookingId,
          type: "ENQUEUED", // Use valid QueueEventType, store reason in payload
          payload: { reason, timeoutMinutes, flaggedAt: new Date().toISOString(), isRecoveryFlag: true }
        }
      });

      this.logEvent("SERVICE_FLAGGED", shopId, "WARNING", "Stale service flagged", {
        bookingId,
        userId: booking.userId,
        chairId: booking.chairId,
        reason,
        timeoutMinutes
      });
    });
  }

  /**
   * Recover a dead queue entry
   */
  async recoverDeadQueueEntry(
    queueEntryId: string,
    bookingId: string,
    shopId: string,
    lane: QueueLane,
    reason: string
  ): Promise<void> {
    await prisma.$transaction(async (tx) => {
      const queueEntry = await tx.queueEntry.findUnique({
        where: { id: queueEntryId },
        include: { booking: true }
      });

      if (!queueEntry) {
        this.logEvent("QUEUE_ENTRY_RECOVERED", shopId, "ERROR", "Queue entry not found", { queueEntryId });
        throw new Error("Queue entry not found");
      }

      // Remove dead queue entry
      await tx.queueEntry.delete({
        where: { id: queueEntryId }
      });

      // Update booking status if needed
      if (queueEntry.booking && queueEntry.booking.status === "IN_SERVICE") {
        await tx.booking.update({
          where: { id: bookingId },
          data: {
            status: "CANCELLED",
            cancellationReason: reason
          }
        });
      }

      this.logEvent("QUEUE_ENTRY_RECOVERED", shopId, "INFO", "Dead queue entry recovered", {
        queueEntryId,
        bookingId,
        lane,
        reason
      });
    });
  }

  /**
   * Normalize stale positions
   */
  async normalizeStalePositions(
    shopId: string,
    lane: QueueLane
  ): Promise<void> {
    await prisma.$transaction(async (tx) => {
      const queueEntries = await tx.queueEntry.findMany({
        where: {
          shopId,
          lane,
          queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
        },
        orderBy: { position: "asc" },
        select: { id: true, bookingId: true, position: true }
      });

      const POSITION_INCREMENT = 100;

      for (let i = 0; i < queueEntries.length; i++) {
        const newPosition = (i + 1) * POSITION_INCREMENT;
        const entry = queueEntries[i];

        if (!entry) continue;

        await tx.queueEntry.update({
          where: { id: entry.id },
          data: { position: newPosition, version: { increment: 1 } }
        });
      }

      this.logEvent("POSITION_NORMALIZED", shopId, "INFO", "Positions normalized", {
        lane,
        entriesUpdated: queueEntries.length
      });
    });
  }

  /**
   * Rebuild Redis queue from PostgreSQL
   */
  async rebuildRedisQueue(
    shopId: string,
    lane: QueueLane,
    redisStore: any
  ): Promise<void> {
    await prisma.$transaction(async (tx) => {
      const queueEntries = await tx.queueEntry.findMany({
        where: {
          shopId,
          lane,
          queueStatus: { in: ["WAITING", "READY", "CALLED", "IN_SERVICE"] }
        },
        orderBy: { position: "asc" },
        include: {
          booking: {
            include: { service: true, barber: true, user: true }
          }
        }
      });

      // Clear existing Redis queue
      await redisStore.clearQueue(shopId, lane);

      // Rebuild from PostgreSQL
      for (const entry of queueEntries) {
        await redisStore.enqueueMember(shopId, {
          bookingId: entry.bookingId,
          lane,
          position: entry.position,
          estimatedWaitMinutes: entry.estimatedWaitMinutes,
          queueStatus: entry.queueStatus,
          userId: entry.booking.userId,
          serviceId: entry.booking.serviceId,
          barberId: entry.booking.barberId ?? null
        });
      }

      this.logEvent("REDIS_REBUILT", shopId, "INFO", "Redis queue rebuilt from PostgreSQL", {
        lane,
        entriesRebuilt: queueEntries.length
      });
    });
  }

  /**
   * Recalculate wait times for a lane
   */
  async recalculateWaitTimes(
    shopId: string,
    lane: QueueLane,
    waitTimeEngine: any
  ): Promise<void> {
    await prisma.$transaction(async (tx) => {
      const recalc = await waitTimeEngine.recalculateLane(shopId, lane, "RECOVERY");

      const durationMap = new Map(
        recalc.estimates.map((e: any) => [e.bookingId, e.effectiveDurationMinutes])
      );

      await waitTimeEngine.persistence.applyEstimatesToDatabase(
        tx,
        shopId,
        recalc.estimates,
        durationMap
      );

      this.logEvent("WAIT_TIME_RECALCULATED", shopId, "INFO", "Wait times recalculated", {
        lane,
        estimatesUpdated: recalc.estimates.length
      });
    });
  }

  /**
   * Execute a recovery operation with error handling
   */
  async executeRecovery<T>(
    operation: () => Promise<T>,
    eventType: RecoveryEventType,
    shopId: string,
    operationName: string
  ): Promise<T | null> {
    try {
      return await operation();
    } catch (error) {
      this.logEvent(
        eventType,
        shopId,
        "ERROR",
        `Recovery operation failed: ${operationName}`,
        { error: error instanceof Error ? error.message : String(error) }
      );
      return null;
    }
  }
}
