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
    realtime;
    constructor(realtime) {
        this.realtime = realtime;
    }
    /**
     * Emit queue updated event
     */
    emitQueueUpdated(snapshot) {
        this.realtime.emitQueueUpdated(snapshot);
    }
    /**
     * Emit position changed event
     */
    emitPositionChanged(data) {
        this.realtime.emitPositionChanged(data);
    }
    /**
     * Emit booking created event
     */
    emitBookingCreated(booking) {
        this.realtime.emitBookingCreated(booking);
    }
    /**
     * Emit booking completed event
     */
    emitBookingCompleted(data) {
        this.realtime.emitBookingCompleted(data);
    }
    /**
     * Emit booking called event
     */
    emitBookingCalled(data) {
        this.realtime.emitBookingCalled(data);
    }
    /**
     * Emit booking in service event
     */
    emitBookingInService(data) {
        this.realtime.emitBookingInService(data);
    }
    /**
     * Emit chair updated event
     */
    emitChairUpdated(data) {
        this.realtime.emitChairUpdated(data);
    }
    /**
     * Emit wait time updated event
     */
    emitWaitUpdated(data) {
        this.realtime.emitWaitUpdated(data);
    }
}
