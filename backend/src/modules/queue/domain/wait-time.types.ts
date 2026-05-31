import type { QueueLane, ServiceCategory } from "@prisma/client";

export type WaitShopConfig = {
  activeReservedChairs: number;
  activeWalkInChairs: number;
  cleaningBufferMinutes: number;
  overrunBufferMinutes: number;
};

export type BarberRuntimeState = {
  delayMinutes: number;
  overrunMinutes: number;
  updatedAtMs: number;
};

export type CategoryAverages = Partial<Record<ServiceCategory, number>>;

export type BookingWaitSnapshot = {
  bookingId: string;
  shopId: string;
  lane: QueueLane;
  position: number;
  serviceId: string;
  serviceCategory: ServiceCategory;
  barberId: string | null;
  catalogDurationMinutes: number;
  queueStatus: string;
  estimatedWaitMinutes: number;
  estimatedServiceStartIso: string;
  /** Remaining minutes if IN_SERVICE */
  inServiceRemainingMinutes: number;
};

export type WaitEstimateResult = {
  bookingId: string;
  position: number;
  estimatedWaitMinutes: number;
  estimatedServiceStart: Date;
  effectiveDurationMinutes: number;
  cleaningBufferMinutes: number;
  delayCompensationMinutes: number;
  overrunCompensationMinutes: number;
};

export type LaneRecalculationResult = {
  shopId: string;
  lane: QueueLane;
  version: number;
  activeChairs: number;
  estimates: WaitEstimateResult[];
  computedAt: Date;
};

export type WaitEstimatesResponse = {
  shopId: string;
  version: number;
  bookBer: WaitEstimateResult[];
  walkIn: WaitEstimateResult[];
  computedAt: string;
};

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
} as const;

export type WaitRecalcTrigger = (typeof WAIT_RECALC_TRIGGERS)[keyof typeof WAIT_RECALC_TRIGGERS];
