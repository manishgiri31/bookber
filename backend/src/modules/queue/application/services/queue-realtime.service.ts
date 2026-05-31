import type { QueueSnapshot } from "../../domain/queue.types.js";
import type { ChairStatus } from "@prisma/client";
import { QueueRealtimeEmitter } from "../queue-realtime.emitter.js";

/**
 * QueueRealtimeService handles all realtime event emission.
 * 
 * Responsibilities:
 * - Emit queue updated events
 * - Emit position changed events
 * - Emit booking lifecycle events (created, called, in service, completed)
 * - Emit chair updated events
 * - Emit wait time updated events
 * 
 * Transaction ownership: None (events only)
 * Redis ownership: None (delegates to QueueRealtimeEmitter)
 * Event ownership: Owns all event emission
 */
export class QueueRealtimeService {
  constructor(private readonly realtime: QueueRealtimeEmitter) { }

  /**
   * Emit queue updated event
   */
  emitQueueUpdated(snapshot: QueueSnapshot): void {
    this.realtime.emitQueueUpdated(snapshot);
  }

  /**
   * Emit position changed event
   */
  emitPositionChanged(data: {
    shopId: string;
    bookingId: string;
    userId: string;
    barberId: string | null;
    position: number;
    estimatedWaitMinutes: number;
    estimatedServiceStart?: Date;
  }): void {
    this.realtime.emitPositionChanged(data);
  }

  /**
   * Emit booking created event
   */
  emitBookingCreated(booking: any): void {
    this.realtime.emitBookingCreated(booking);
  }

  /**
   * Emit booking completed event
   */
  emitBookingCompleted(data: {
    shopId: string;
    bookingId: string;
    userId: string;
    barberId: string | null;
  }): void {
    this.realtime.emitBookingCompleted(data);
  }

  /**
   * Emit booking called event
   */
  emitBookingCalled(data: {
    shopId: string;
    bookingId: string;
    userId: string;
    barberId: string | null;
    chairId: string;
    position: number;
  }): void {
    this.realtime.emitBookingCalled(data);
  }

  /**
   * Emit booking in service event
   */
  emitBookingInService(data: {
    shopId: string;
    bookingId: string;
    userId: string;
    barberId: string | null;
    chairId: string;
  }): void {
    this.realtime.emitBookingInService(data);
  }

  /**
   * Emit chair updated event
   */
  emitChairUpdated(data: {
    id: string;
    shopId: string;
    number: number;
    status: ChairStatus;
    reservedForBookBer: boolean;
    bookingId: string | null;
    activeServiceStart: Date | null;
    activeServiceEnd: Date | null;
  }): void {
    this.realtime.emitChairUpdated(data);
  }

  /**
   * Emit wait time updated event
   */
  emitWaitUpdated(data: {
    shopId: string;
    version: number;
    bookBer: Array<{
      bookingId: string;
      position: number;
      estimatedWaitMinutes: number;
      estimatedServiceStart: Date;
    }>;
    walkIn: Array<{
      bookingId: string;
      position: number;
      estimatedWaitMinutes: number;
      estimatedServiceStart: Date;
    }>;
  }): void {
    this.realtime.emitWaitUpdated(data);
  }
}
