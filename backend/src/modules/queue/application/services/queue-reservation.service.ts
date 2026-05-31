import { Prisma, type Booking, type QueueLane } from "@prisma/client";
import type { AuthUser } from "../../../auth/domain/auth.types.js";
import type { PrismaQueueRepository } from "../../infrastructure/queue.repository.js";
import { QueueLock } from "../../queue.lock.js";
import { Errors } from "../../../../shared/http/app-error.js";
import { prisma } from "../../../../shared/prisma/client.js";
import { WaitTimeRedisStore } from "../../infrastructure/wait-time-redis.store.js";

function addMinutes(date: Date, minutes: number): Date {
  return new Date(date.getTime() + minutes * 60_000);
}

export type ReserveQueueInput = {
  shopId: string;
  serviceId: string;
  userId: string;
  barberId?: string | undefined;
  walkIn: boolean;
};

/**
 * QueueReservationService handles booking lifecycle operations.
 * 
 * Responsibilities:
 * - Queue reservation (enqueue)
 * - Check-in
 * - Service start
 * - Service completion
 * - No-show marking
 * - Booking cancellation
 * 
 * Transaction ownership: Owns booking and active queue transactions
 * Redis ownership: Delegates to other services
 * Event ownership: Delegates to QueueRealtimeService
 */
export class QueueReservationService {
  constructor(
    private readonly repository: PrismaQueueRepository,
    private readonly lock: QueueLock,
    private readonly redisStore: WaitTimeRedisStore
  ) { }

  private laneForWalkIn(walkIn: boolean): QueueLane {
    return walkIn ? "WALKIN" : "BOOKBER";
  }

  /**
   * Reserve a queue position for a booking
   */
  async reserveQueue(user: AuthUser, input: ReserveQueueInput): Promise<Booking> {
    // Input validation
    if (!input.shopId || typeof input.shopId !== 'string' || input.shopId.length === 0) {
      throw Errors.validation('Invalid shop ID');
    }
    if (!input.serviceId || typeof input.serviceId !== 'string' || input.serviceId.length === 0) {
      throw Errors.validation('Invalid service ID');
    }
    if (!input.userId || typeof input.userId !== 'string' || input.userId.length === 0) {
      throw Errors.validation('Invalid user ID');
    }
    if (input.barberId && (typeof input.barberId !== 'string' || input.barberId.length === 0)) {
      throw Errors.validation('Invalid barber ID');
    }
    if (typeof input.walkIn !== 'boolean') {
      throw Errors.validation('Invalid walkIn flag');
    }

    if (input.walkIn && user.role === "CLIENT" && user.id !== input.userId) {
      throw Errors.forbidden();
    }

    try {
      const result = await this.lock.withLock(`shop:${input.shopId}:reserve`, 8000, () =>
        prisma.$transaction(
          async (tx) => {
            await this.repository.lockShop(tx, input.shopId);

            const shop = await this.repository.findShopById(tx, input.shopId);
            if (!shop) throw Errors.notFound("Shop not found");
            if (!shop.isActive || !shop.isAcceptingBookings) {
              throw Errors.conflict("Shop is not accepting queue reservations");
            }
            if (input.walkIn && !shop.isAcceptingWalkIns) {
              throw Errors.conflict("Shop is not accepting walk-ins");
            }

            const service = await this.repository.findService(tx, input.serviceId);
            if (!service || service.shopId !== input.shopId || !service.isActive) {
              throw Errors.notFound("Service not found");
            }

            if (input.barberId) {
              const barber = shop.barbers.find((b) => b.id === input.barberId);
              if (!barber) throw Errors.notFound("Barber not found in shop");
            }

            const lane = this.laneForWalkIn(input.walkIn);
            const positionResult = await this.repository.nextQueuePosition(tx, input.shopId, lane);
            const position = positionResult.position;
            const now = new Date();

            const booking = await tx.booking.create({
              data: {
                userId: input.userId,
                shopId: input.shopId,
                ...(input.barberId ? { barberId: input.barberId } : {}),
                serviceId: input.serviceId,
                status: "QUEUED",
                arrivalWindowStart: now,
                arrivalWindowEnd: addMinutes(now, 30),
                walkIn: input.walkIn
              }
            });

            await tx.queueEntry.create({
              data: {
                shopId: input.shopId,
                bookingId: booking.id,
                ...(input.barberId ? { barberId: input.barberId } : {}),
                lane,
                position,
                queueStatus: "WAITING",
                estimatedWaitMinutes: 0,
                estimatedServiceStart: now
              }
            });

            await this.repository.createQueueEvent(tx, {
              shopId: input.shopId,
              bookingId: booking.id,
              type: "ENQUEUED",
              payload: { lane, position }
            });

            const refreshed = await tx.booking.findUnique({ where: { id: booking.id } });
            return { booking: refreshed ?? booking, lane, position, service };
          },
          { isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted, maxWait: 8000, timeout: 15000 }
        )
      );

      // Write-through to Redis after transaction commits
      if (this.redisStore.isAvailable()) {
        try {
          await this.redisStore.enqueue(result.booking.id, input.shopId, result.lane, result.position);
          await this.redisStore.setBookingSnapshot({
            bookingId: result.booking.id,
            shopId: input.shopId,
            lane: result.lane,
            position: result.position,
            serviceId: input.serviceId,
            serviceCategory: "HAIRCUT",
            barberId: input.barberId ?? null,
            catalogDurationMinutes: result.service.durationMinutes,
            queueStatus: "WAITING",
            estimatedWaitMinutes: 0,
            estimatedServiceStartIso: new Date().toISOString(),
            inServiceRemainingMinutes: result.service.durationMinutes
          });
        } catch (error) {
          // Log but don't fail - Redis is cache, not source of truth
          console.error("Redis write-through failed for enqueue:", error);
        }
      }

      return result.booking;
    } catch (error) {
      if (error instanceof Error && error.message === "QUEUE_LOCK_BUSY") {
        throw Errors.conflict("Queue is busy, retry shortly");
      }
      throw error;
    }
  }

  /**
   * Check in a booking
   */
  async checkIn(user: AuthUser, bookingId: string): Promise<Booking> {
    return prisma.$transaction(async (tx) => {
      await this.repository.lockBooking(tx, bookingId);
      const booking = await this.repository.findBooking(tx, bookingId);
      if (!booking) throw Errors.notFound("Booking not found");
      if (user.role !== "ADMIN" && booking.userId !== user.id) throw Errors.forbidden();
      if (!["QUEUED", "READY"].includes(booking.status)) {
        throw Errors.conflict("Booking cannot check in");
      }

      const now = new Date();
      if (now < booking.arrivalWindowStart) {
        throw Errors.conflict("Arrival window has not started");
      }
      if (now > booking.arrivalWindowEnd) {
        throw Errors.conflict("Arrival window has expired");
      }

      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: { status: "READY" }
      });

      await tx.queueEntry.update({
        where: { bookingId },
        data: { queueStatus: "READY", version: { increment: 1 } }
      });

      await this.repository.createQueueEvent(tx, {
        shopId: booking.shopId,
        bookingId,
        type: "DELAYED",
        payload: { action: "CHECK_IN" }
      });

      return updated;
    }, { isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted, maxWait: 5000, timeout: 10000 });
  }

  /**
   * Start service for a booking
   */
  async startService(user: AuthUser, bookingId: string): Promise<Booking> {
    return prisma.$transaction(async (tx) => {
      await this.repository.lockBooking(tx, bookingId);
      const booking = await this.repository.findBooking(tx, bookingId);
      if (!booking) throw Errors.notFound("Booking not found");
      if (user.role === "BARBER") {
        const barber = await tx.barber.findFirst({
          where: { userId: user.id, shopId: booking.shopId }
        });
        if (!barber) throw Errors.forbidden();
      } else if (user.role !== "ADMIN") {
        throw Errors.forbidden();
      }
      if (!["CALLED", "READY"].includes(booking.status)) {
        throw Errors.conflict("Booking cannot start service");
      }
      if (!booking.chairId) throw Errors.conflict("No chair assigned");

      const start = new Date();
      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: { status: "IN_SERVICE" }
      });

      await tx.queueEntry.update({
        where: { bookingId },
        data: { queueStatus: "IN_SERVICE", version: { increment: 1 } }
      });

      await tx.chair.update({
        where: { id: booking.chairId },
        data: { status: "OCCUPIED", activeServiceStart: start }
      });

      await this.repository.createQueueEvent(tx, {
        shopId: booking.shopId,
        bookingId,
        type: "IN_SERVICE",
        payload: {}
      });

      return updated;
    }, { isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted, maxWait: 5000, timeout: 10000 });
  }

  /**
   * Complete service for a booking
   */
  async completeService(user: AuthUser, bookingId: string): Promise<Booking> {
    try {
      return await this.lock.withLock(`booking:${bookingId}:complete`, 8000, () =>
        prisma.$transaction(async (tx) => {
          await this.repository.lockBooking(tx, bookingId);
          const booking = await this.repository.findBooking(tx, bookingId);
          if (!booking) throw Errors.notFound("Booking not found");
          if (user.role === "BARBER") {
            const barber = await tx.barber.findFirst({
              where: { userId: user.id, shopId: booking.shopId }
            });
            if (!barber) throw Errors.forbidden();
          } else if (user.role !== "ADMIN") {
            throw Errors.forbidden();
          }
          if (booking.status !== "IN_SERVICE") {
            throw Errors.conflict("Booking is not in service");
          }

          const endAt = new Date();
          const updated = await tx.booking.update({
            where: { id: bookingId },
            data: { status: "COMPLETED" }
          });

          await tx.queueEntry.update({
            where: { bookingId },
            data: { queueStatus: "COMPLETED", version: { increment: 1 } }
          });

          if (booking.chairId) {
            await this.repository.releaseChair(tx, booking.chairId, bookingId, endAt);
          }

          const serviceStart =
            booking.chair?.activeServiceStart ?? booking.queueEntry?.estimatedServiceStart;
          const actualMinutes =
            serviceStart != null
              ? Math.round((endAt.getTime() - serviceStart.getTime()) / 60_000)
              : booking.service.durationMinutes;

          await this.repository.createQueueEvent(tx, {
            shopId: booking.shopId,
            bookingId,
            type: "COMPLETED",
            payload: { actualMinutes }
          });

          return updated;
        }, { isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted, maxWait: 8000, timeout: 15000 })
      );
    } catch (error) {
      if (error instanceof Error && error.message === "QUEUE_LOCK_BUSY") {
        throw Errors.conflict("Queue is busy, retry shortly");
      }
      throw error;
    }
  }

  /**
   * Mark booking as no-show
   */
  async markNoShow(user: AuthUser, bookingId: string): Promise<Booking> {
    return prisma.$transaction(async (tx) => {
      await this.repository.lockBooking(tx, bookingId);
      const booking = await this.repository.findBooking(tx, bookingId);
      if (!booking) throw Errors.notFound("Booking not found");
      if (user.role !== "ADMIN" && user.role !== "BARBER") throw Errors.forbidden();

      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: {
          status: "NO_SHOW",
          noShowAt: new Date()
        }
      });

      await tx.queueEntry.update({
        where: { bookingId },
        data: { queueStatus: "NO_SHOW", version: { increment: 1 } }
      });

      await this.repository.createQueueEvent(tx, {
        shopId: booking.shopId,
        bookingId,
        type: "NO_SHOW",
        payload: {}
      });

      return updated;
    }, { isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted, maxWait: 5000, timeout: 10000 });
  }

  /**
   * Cancel a booking
   */
  async cancelBooking(user: AuthUser, bookingId: string, reason?: string): Promise<Booking> {
    return prisma.$transaction(async (tx) => {
      await this.repository.lockBooking(tx, bookingId);
      const booking = await this.repository.findBooking(tx, bookingId);
      if (!booking) throw Errors.notFound("Booking not found");
      if (user.role !== "ADMIN" && booking.userId !== user.id) throw Errors.forbidden();
      if (["COMPLETED", "CANCELLED", "NO_SHOW"].includes(booking.status)) {
        throw Errors.conflict("Booking cannot be cancelled");
      }

      if (booking.chairId && booking.status === "IN_SERVICE") {
        await this.repository.releaseChair(tx, booking.chairId, bookingId);
      }

      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: {
          status: "CANCELLED",
          ...(reason ? { cancellationReason: reason } : {}),
          cancelledAt: new Date()
        }
      });

      if (booking.queueEntry) {
        await tx.queueEntry.update({
          where: { bookingId },
          data: { queueStatus: "CANCELLED", version: { increment: 1 } }
        });
      }

      await this.repository.createQueueEvent(tx, {
        shopId: booking.shopId,
        bookingId,
        type: "CANCELLED",
        payload: { reason }
      });

      return updated;
    }, { isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted, maxWait: 5000, timeout: 10000 });
  }
}
