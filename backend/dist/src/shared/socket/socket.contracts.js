/**
 * Canonical realtime event names (wire contract).
 * All payloads are wrapped in {@link RealtimeEnvelope} on the wire.
 */
export const REALTIME_EVENTS = {
    QUEUE_UPDATED: "queue.updated",
    BOOKING_CREATED: "booking.created",
    BOOKING_CALLED: "booking.called",
    BOOKING_COMPLETED: "booking.completed",
    CHAIR_UPDATED: "chair.updated",
    WAIT_UPDATED: "wait.updated"
};
