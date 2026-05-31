import { Prisma, type Booking, type QueueLane } from "@prisma/client";
import type { Redis as RedisClient } from "ioredis";
import { Errors } from "../../../shared/http/app-error.js";
import { prisma } from "../../../shared/prisma/client.js";
import { QueueRedisStore } from "../../../shared/redis/queue-redis.store.js";
import type { AuthUser } from "../../auth/domain/auth.types.js";
import type { PrismaQueueRepository } from "../infrastructure/queue.repository.js";
import type { QueueSnapshot, QueueSnapshotEntry } from "../domain/queue.types.js";
import { ChairAllocator } from "./chair-allocator.service.js";
import { QueueRealtimeEmitter } from "./queue-realtime.emitter.js";
import { QueueLock } from "../queue.lock.js";
import { WaitTimeEngine } from "./wait-time.engine.js";
import { WAIT_RECALC_TRIGGERS } from "../domain/wait-time.types.js";
import type { BookingWaitSnapshot } from "../domain/wait-time.types.js";
import { EVENT_LOG_TYPES, getEventLogService } from "../../../infrastructure/events/event-log.service.js";
import { getMetrics } from "../../../infrastructure/metrics/prometheus.js";
import { withSpan } from "../../../infrastructure/tracing/otel.js";

function addMinutes(date: Date, minutes: number): Date {
  return new Date(date.getTime() + minutes * 60_000);
}

type LoadedBooking = NonNullable<Awaited<ReturnType<PrismaQueueRepository["findBooking"]>>>;

function queueLaneOf(booking: LoadedBooking): QueueLane {
  return booking.queueEntry?.lane ?? (booking.walkIn ? "WALKIN" : "BOOKBER");
}

export type ReserveQueueInput = {
  shopId: string;
  serviceId: string;
  userId: string;
  barberId?: string | undefined;
  walkIn: boolean;
};

export class QueueEngineService {
  private readonly redisStore: QueueRedisStore;

  constructor(
    private readonly repository: PrismaQueueRepository,
    private readonly chairAllocator: ChairAllocator,
    private readonly lock: QueueLock,
    private readonly realtime: QueueRealtimeEmitter,
    private readonly waitTime: WaitTimeEngine,
    redis: RedisClient | null = null
  ) {
    this.redisStore = new QueueRedisStore(redis);
  }

  private laneForWalkIn(walkIn: boolean): QueueLane {
    return walkIn ? "WALKIN" : "BOOKBER";
  }

  async reserveQueue(user: AuthUser, input: ReserveQueueInput): Promise<Booking> {
    if (input.walkIn && user.role === "CLIENT" && user.id !== input.userId) {
      throw Errors.forbidden();
    }

    const reserveStarted = process.hrtime.bigint();

    try {
      return await withSpan(
        "queue.reserve",
        { shopId: input.shopId, walkIn: input.walkIn },
        () =>
          this.lock.withLock(`shop:${input.shopId}:reserve`, 8000, () =>
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

            const waitSnapshot: BookingWaitSnapshot = {
              bookingId: booking.id,
              shopId: input.shopId,
              lane,
              position,
              serviceId: input.serviceId,
              serviceCategory: service.category,
              barberId: input.barberId ?? null,
              catalogDurationMinutes: service.durationMinutes,
              queueStatus: "WAITING",
              estimatedWaitMinutes: 0,
              estimatedServiceStartIso: now.toISOString(),
              inServiceRemainingMinutes: 0
            };

            await this.waitTime.syncBookingSnapshot(waitSnapshot);

            await this.repository.createQueueEvent(tx, {
              shopId: input.shopId,
              bookingId: booking.id,
              type: "ENQUEUED",
              payload: { lane, position }
            });

            await this.redisStore.enqueueMember(input.shopId, {
              bookingId: booking.id,
              lane,
              position,
              estimatedWaitMinutes: 0,
              queueStatus: "WAITING",
              userId: input.userId,
              serviceId: input.serviceId,
              barberId: input.barberId ?? null
            });

            const recalc = await this.waitTime.recalculateLane(
              input.shopId,
              lane,
              WAIT_RECALC_TRIGGERS.ENQUEUE
            );
            const selfEstimate = recalc.estimates.find((e) => e.bookingId === booking.id);
            const durationMap = new Map(
              recalc.estimates.map((e) => [e.bookingId, e.effectiveDurationMinutes])
            );
            await this.waitTime.persistence.applyEstimatesToDatabase(
              tx,
              input.shopId,
              recalc.estimates,
              durationMap
            );

            const version = await this.redisStore.bumpShopQueueVersion(input.shopId);
            const snapshot = await this.buildSnapshot(tx, input.shopId, version);

            this.realtime.emitQueueUpdated(snapshot);
            if (selfEstimate) {
              this.realtime.emitPositionChanged({
                shopId: input.shopId,
                bookingId: booking.id,
                userId: input.userId,
                barberId: input.barberId ?? null,
                position: selfEstimate.position,
                estimatedWaitMinutes: selfEstimate.estimatedWaitMinutes
              });
            }

            const refreshed = await tx.booking.findUnique({
              where: { id: booking.id },
              include: { queueEntry: true }
            });
            const result = refreshed ?? booking;
            const queueEntry = refreshed?.queueEntry;
            if (queueEntry) {
              this.realtime.emitBookingCreated({
                id: result.id,
                shopId: result.shopId,
                userId: result.userId,
                barberId: result.barberId,
                serviceId: result.serviceId,
                status: result.status,
                queueLane: queueEntry.lane,
                queuePosition: queueEntry.position,
                estimatedWaitMinutes: queueEntry.estimatedWaitMinutes,
                arrivalWindowStart: result.arrivalWindowStart,
                arrivalWindowEnd: result.arrivalWindowEnd,
                estimatedServiceStart: queueEntry.estimatedServiceStart,
                estimatedServiceEnd: queueEntry.estimatedServiceStart
                  ? addMinutes(queueEntry.estimatedServiceStart, service.durationMinutes)
                  : null
              });

              const durationSec = Number(process.hrtime.bigint() - reserveStarted) / 1e9;
              getMetrics().bookingCreationDuration.observe(
                { shop_id: input.shopId, lane: queueEntry.lane },
                durationSec
              );

              const events = getEventLogService();
              events.recordAsync({
                type: EVENT_LOG_TYPES.BOOKING_CREATED,
                shopId: input.shopId,
                bookingId: result.id,
                userId: input.userId,
                payload: { lane: queueEntry.lane, position: queueEntry.position }
              });
              events.recordAsync({
                type: EVENT_LOG_TYPES.QUEUE_JOINED,
                shopId: input.shopId,
                bookingId: result.id,
                userId: input.userId,
                payload: { lane: queueEntry.lane, position: queueEntry.position }
              });
            }
            return result;
          },
          { isolationLevel: Prisma.TransactionIsolationLevel.Serializable, maxWait: 8000, timeout: 15000 }
        )
          )
      );
    } catch (error) {
      if (error instanceof Error && error.message === "QUEUE_LOCK_BUSY") {
        throw Errors.conflict("Queue is busy, retry shortly");
      }
      throw error;
    }
  }

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

      const lane = queueLaneOf(booking);
      await this.tryAssignNext(tx, booking.shopId, lane);
      await this.rebalanceLane(tx, booking.shopId, lane, WAIT_RECALC_TRIGGERS.CHECK_IN);
      return updated;
    }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable, maxWait: 5000, timeout: 10000 });
  }

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
            const chair = await tx.chair.findUnique({ where: { id: booking.chairId } });
            if (chair) {
              await this.redisStore.setChairCache({
                chairId: chair.id,
                shopId: chair.shopId,
                status: "AVAILABLE",
                reservedForBookBer: chair.reservedForBookBer,
                bookingId: null,
                activeServiceStart: null,
                activeServiceEnd: endAt.toISOString()
              });
              this.realtime.emitChairUpdated({
                id: chair.id,
                shopId: chair.shopId,
                number: chair.number,
                status: "AVAILABLE",
                reservedForBookBer: chair.reservedForBookBer,
                bookingId: null,
                activeServiceStart: null,
                activeServiceEnd: endAt
              });
            }
          }

          const serviceStart =
            booking.chair?.activeServiceStart ?? booking.queueEntry?.estimatedServiceStart;
          const actualMinutes =
            serviceStart != null
              ? Math.round((endAt.getTime() - serviceStart.getTime()) / 60_000)
              : booking.service.durationMinutes;

          if (booking.barberId) {
            const overrun = actualMinutes - booking.service.durationMinutes;
            if (overrun > 0) {
              await this.waitTime.recordServiceOverrun(booking.shopId, booking.barberId, overrun);
            }
            await this.waitTime.persistence.recordServiceSample({
              shopId: booking.shopId,
              barberId: booking.barberId,
              category: booking.service.category,
              actualMinutes
            });
          }

          await this.repository.createQueueEvent(tx, {
            shopId: booking.shopId,
            bookingId,
            type: "COMPLETED",
            payload: { actualMinutes }
          });

          const lane = queueLaneOf(booking);
          await this.redisStore.removeMember(booking.shopId, lane, bookingId);
          await this.compactQueue(tx, booking.shopId, lane);
          await this.rebalanceLane(tx, booking.shopId, lane, WAIT_RECALC_TRIGGERS.COMPLETE_SERVICE);
          await this.tryAssignNext(tx, booking.shopId, lane);

          const version = await this.redisStore.bumpShopQueueVersion(booking.shopId);
          const snapshot = await this.buildSnapshot(tx, booking.shopId, version);
          this.realtime.emitBookingCompleted({
            shopId: booking.shopId,
            bookingId,
            userId: booking.userId,
            barberId: booking.barberId
          });
          this.realtime.emitQueueUpdated(snapshot);

          const events = getEventLogService();
          events.recordAsync({
            type: EVENT_LOG_TYPES.QUEUE_LEFT,
            shopId: booking.shopId,
            bookingId,
            userId: booking.userId,
            payload: { reason: "completed" }
          });
          if (booking.chairId) {
            events.recordAsync({
              type: EVENT_LOG_TYPES.CHAIR_RELEASED,
              shopId: booking.shopId,
              bookingId,
              chairId: booking.chairId,
              payload: { reason: "service_completed" }
            });
          }

          return updated;
        }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable, maxWait: 8000, timeout: 15000 })
      );
    } catch (error) {
      if (error instanceof Error && error.message === "QUEUE_LOCK_BUSY") {
        throw Errors.conflict("Queue is busy, retry shortly");
      }
      throw error;
    }
  }

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

      const lane = queueLaneOf(booking);
      await this.redisStore.removeMember(booking.shopId, lane, bookingId);
      await this.compactQueue(tx, booking.shopId, lane);
      await this.rebalanceLane(tx, booking.shopId, lane, WAIT_RECALC_TRIGGERS.NO_SHOW);

      return updated;
    }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable, maxWait: 5000, timeout: 10000 });
  }

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

      const lane = queueLaneOf(booking);
      await this.redisStore.removeMember(booking.shopId, lane, bookingId);
      await this.compactQueue(tx, booking.shopId, lane);
      await this.rebalanceLane(tx, booking.shopId, lane, WAIT_RECALC_TRIGGERS.CANCEL);
      await this.tryAssignNext(tx, booking.shopId, lane);

      const events = getEventLogService();
      events.recordAsync({
        type: EVENT_LOG_TYPES.BOOKING_CANCELLED,
        shopId: booking.shopId,
        bookingId,
        userId: booking.userId,
        payload: { reason: reason ?? null }
      });
      events.recordAsync({
        type: EVENT_LOG_TYPES.QUEUE_LEFT,
        shopId: booking.shopId,
        bookingId,
        userId: booking.userId,
        payload: { reason: "cancelled" }
      });

      return updated;
    }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable, maxWait: 5000, timeout: 10000 });
  }

  async rebalanceShop(shopId: string): Promise<QueueSnapshot> {
    return this.lock.withLock(`shop:${shopId}:rebalance`, 8000, async () =>
      prisma.$transaction(async (tx) => {
        await this.repository.lockShop(tx, shopId);
        const shop = await this.repository.findShopById(tx, shopId);
        if (!shop) throw Errors.notFound("Shop not found");

        await this.rebalanceLane(tx, shopId, "BOOKBER", WAIT_RECALC_TRIGGERS.REBALANCE);
        await this.rebalanceLane(tx, shopId, "WALKIN", WAIT_RECALC_TRIGGERS.REBALANCE);

        const version = await this.redisStore.bumpShopQueueVersion(shopId);
        const snapshot = await this.buildSnapshot(tx, shopId, version);
        this.realtime.emitQueueUpdated(snapshot);
        return snapshot;
      }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable, maxWait: 8000, timeout: 15000 })
    );
  }

  async getShopSnapshot(shopId: string): Promise<QueueSnapshot> {
    const version = await this.redisStore.getShopQueueVersion(shopId);
    return this.buildSnapshot(prisma, shopId, version);
  }

  private async tryAssignNext(
    tx: Prisma.TransactionClient,
    shopId: string,
    lane: QueueLane
  ): Promise<void> {
    const assignStarted = process.hrtime.bigint();
    const chair = await this.chairAllocator.findAvailableChair(tx, shopId, lane);
    if (!chair) return;

    const next = await tx.queueEntry.findFirst({
      where: {
        shopId,
        lane,
        queueStatus: { in: ["WAITING", "READY"] },
        booking: { status: { in: ["QUEUED", "READY"] } }
      },
      include: { booking: true },
      orderBy: { position: "asc" }
    });

    if (!next) return;

    const now = new Date();
    if (next.queueStatus === "WAITING" && now > next.booking.arrivalWindowEnd) {
      return;
    }

    await this.chairAllocator.allocateToBooking(tx, {
      shopId,
      chair,
      bookingId: next.bookingId,
      lane,
      startNow: true
    });

    await tx.booking.update({
      where: { id: next.bookingId },
      data: {
        chairId: chair.id,
        status: "CALLED"
      }
    });

    await tx.queueEntry.update({
      where: { id: next.id },
      data: { queueStatus: "CALLED", version: { increment: 1 } }
    });

    await this.repository.createQueueEvent(tx, {
      shopId,
      bookingId: next.bookingId,
      type: "CHAIR_ASSIGNED",
      payload: { chairId: chair.id }
    });

    await this.redisStore.setChairCache({
      chairId: chair.id,
      shopId,
      status: "OCCUPIED",
      reservedForBookBer: chair.reservedForBookBer,
      bookingId: next.bookingId,
      activeServiceStart: now.toISOString(),
      activeServiceEnd: null
    });

    this.realtime.emitChairUpdated({
      id: chair.id,
      shopId,
      number: chair.number,
      status: "OCCUPIED",
      reservedForBookBer: chair.reservedForBookBer,
      bookingId: next.bookingId,
      activeServiceStart: now,
      activeServiceEnd: null
    });

    this.realtime.emitBookingCalled({
      shopId,
      bookingId: next.bookingId,
      userId: next.booking.userId,
      barberId: next.barberId,
      chairId: chair.id,
      position: next.position
    });

    getMetrics().queueAssignmentDuration.observe(
      { shop_id: shopId, lane },
      Number(process.hrtime.bigint() - assignStarted) / 1e9
    );
    getEventLogService().recordAsync({
      type: EVENT_LOG_TYPES.CHAIR_ASSIGNED,
      shopId,
      bookingId: next.bookingId,
      userId: next.booking.userId,
      chairId: chair.id,
      payload: { lane, position: next.position }
    });
  }

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

      this.realtime.emitBookingInService({
        shopId: booking.shopId,
        bookingId,
        userId: booking.userId,
        barberId: booking.barberId,
        chairId: booking.chairId
      });

      return updated;
    }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable, maxWait: 5000, timeout: 10000 });
  }

  private async compactQueue(tx: Prisma.TransactionClient, shopId: string, lane: QueueLane): Promise<void> {
    // With sparse positioning, we don't need O(n) reindexing on every deletion.
    // Only normalize when positions get too large or gaps get too small.
    const needsRebalancing = await this.repository.needsRebalancing(tx, shopId, lane);
    const needsNormalization = await this.repository.needsNormalization(tx, shopId, lane);

    if (needsRebalancing || needsNormalization) {
      await this.repository.normalizeLane(tx, shopId, lane);

      // Update Redis with new positions
      const entries = await this.repository.listActiveQueueEntries(tx, shopId, lane);
      for (const entry of entries) {
        await this.redisStore.updatePosition(
          shopId,
          lane,
          entry.bookingId,
          entry.position,
          entry.estimatedWaitMinutes
        );
      }
    }
  }

  private async rebalanceLane(
    tx: Prisma.TransactionClient,
    shopId: string,
    lane: QueueLane,
    trigger: (typeof WAIT_RECALC_TRIGGERS)[keyof typeof WAIT_RECALC_TRIGGERS]
  ): Promise<void> {
    const recalc = await this.waitTime.recalculateLane(shopId, lane, trigger);
    const durationMap = new Map(
      recalc.estimates.map((e) => [e.bookingId, e.effectiveDurationMinutes])
    );
    await this.waitTime.persistence.applyEstimatesToDatabase(
      tx,
      shopId,
      recalc.estimates,
      durationMap
    );

    const entries = await this.repository.listActiveQueueEntries(tx, shopId, lane);
    for (const estimate of recalc.estimates) {
      const entry = entries.find((e) => e.bookingId === estimate.bookingId);
      if (!entry) continue;

      await this.repository.createQueueEvent(tx, {
        shopId,
        bookingId: entry.bookingId,
        type: "WAIT_RECALCULATED",
        payload: {
          position: estimate.position,
          estimatedWaitMinutes: estimate.estimatedWaitMinutes,
          cleaningBufferMinutes: estimate.cleaningBufferMinutes,
          delayCompensationMinutes: estimate.delayCompensationMinutes,
          overrunCompensationMinutes: estimate.overrunCompensationMinutes
        }
      });

      this.realtime.emitPositionChanged({
        shopId,
        bookingId: entry.bookingId,
        userId: entry.booking.userId,
        barberId: entry.barberId,
        position: estimate.position,
        estimatedWaitMinutes: estimate.estimatedWaitMinutes,
        estimatedServiceStart: estimate.estimatedServiceStart
      });
    }

    this.realtime.emitWaitUpdated({
      shopId,
      version: Date.now(),
      bookBer:
        lane === "BOOKBER"
          ? recalc.estimates.map((e) => ({
            bookingId: e.bookingId,
            position: e.position,
            estimatedWaitMinutes: e.estimatedWaitMinutes,
            estimatedServiceStart: e.estimatedServiceStart
          }))
          : [],
      walkIn:
        lane === "WALKIN"
          ? recalc.estimates.map((e) => ({
            bookingId: e.bookingId,
            position: e.position,
            estimatedWaitMinutes: e.estimatedWaitMinutes,
            estimatedServiceStart: e.estimatedServiceStart
          }))
          : []
    });
  }

  private async buildSnapshot(db: Prisma.TransactionClient | typeof prisma, shopId: string, version: number): Promise<QueueSnapshot> {
    const mapEntry = async (lane: QueueLane): Promise<QueueSnapshotEntry[]> => {
      const rows = await this.repository.listActiveQueueEntries(db, shopId, lane);
      return rows.map((row) => ({
        activeQueueId: row.id,
        bookingId: row.bookingId,
        shopId: row.shopId,
        barberId: row.barberId,
        userId: row.booking.userId,
        serviceId: row.booking.serviceId,
        lane: row.lane,
        position: row.position,
        queueStatus: row.queueStatus,
        bookingStatus: row.booking.status,
        estimatedWaitMinutes: row.estimatedWaitMinutes,
        estimatedServiceStart: row.estimatedServiceStart,
        arrivalWindowStart: row.booking.arrivalWindowStart,
        arrivalWindowEnd: row.booking.arrivalWindowEnd,
        chairId: row.booking.chairId,
        walkIn: row.booking.walkIn
      }));
    };

    return {
      shopId,
      version,
      bookBer: await mapEntry("BOOKBER"),
      walkIn: await mapEntry("WALKIN")
    };
  }
}
