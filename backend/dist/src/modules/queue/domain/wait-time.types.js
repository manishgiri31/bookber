/** Triggers that must run a full lane recalculation */
export const WAIT_RECALC_TRIGGERS = {
    ENQUEUE: "enqueue",
    DEQUEUE: "dequeue",
    CHECK_IN: "check_in",
    START_SERVICE: "start_service",
    COMPLETE_SERVICE: "complete_service",
    CANCEL: "cancel",
    NO_SHOW: "no_show",
    BARBER_DELAY: "barber_delay",
    SERVICE_OVERRUN: "service_overrun",
    REBALANCE: "rebalance",
    CHAIR_AVAILABLE: "chair_available"
};
