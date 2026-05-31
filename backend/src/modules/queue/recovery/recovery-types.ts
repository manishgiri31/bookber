import type { QueueLane, QueueStatus, ChairStatus, BookingStatus } from "@prisma/client";

/**
 * Recovery event types for logging and monitoring
 */
export type RecoveryEventType =
  | "CHAIR_ORPHANED"
  | "CHAIR_RECOVERED"
  | "SERVICE_STALE"
  | "SERVICE_FLAGGED"
  | "QUEUE_ENTRY_DEAD"
  | "QUEUE_ENTRY_RECOVERED"
  | "REDIS_MISMATCH"
  | "REDIS_REBUILT"
  | "POSITION_STALE"
  | "POSITION_NORMALIZED"
  | "WAIT_TIME_MISMATCH"
  | "WAIT_TIME_RECALCULATED"
  | "SOCKET_STALE"
  | "SOCKET_DISCONNECTED";

/**
 * Recovery event for logging
 */
export type RecoveryEvent = {
  id: string;
  type: RecoveryEventType;
  shopId: string;
  bookingId?: string;
  chairId?: string;
  lane?: QueueLane;
  severity: "INFO" | "WARNING" | "ERROR" | "CRITICAL";
  message: string;
  metadata: Record<string, unknown>;
  recoveredAt: Date;
};

/**
 * Orphaned chair detection result
 */
export type OrphanedChair = {
  chairId: string;
  shopId: string;
  number: number;
  status: ChairStatus;
  lastBookingId: string | null;
  lastServiceStart: Date | null;
  hoursSinceService: number;
  reason: "NO_ACTIVE_BOOKING" | "BOOKING_COMPLETED" | "BOOKING_CANCELLED" | "TIMEOUT";
};

/**
 * Stale service detection result
 */
export type StaleService = {
  bookingId: string;
  shopId: string;
  userId: string;
  chairId: string | null;
  status: BookingStatus;
  activeServiceStart: Date;
  minutesSinceStart: number;
  timeoutMinutes: number;
  reason: "NO_HEARTBEAT" | "TIMEOUT" | "CHAIR_RELEASED";
};

/**
 * Dead queue entry detection result
 */
export type DeadQueueEntry = {
  queueEntryId: string;
  bookingId: string;
  shopId: string;
  lane: QueueLane;
  position: number;
  queueStatus: QueueStatus;
  bookingStatus: BookingStatus;
  reason: "BOOKING_CANCELLED" | "BOOKING_COMPLETED" | "CHAIR_RELEASED" | "STALE_POSITION";
};

/**
 * Redis mismatch detection result
 */
export type RedisMismatch = {
  shopId: string;
  lane: QueueLane;
  dbQueueLength: number;
  redisQueueLength: number;
  mismatchedBookings: Array<{
    bookingId: string;
    dbStatus: string; // Can be QueueStatus or "MISSING"
    redisStatus: string;
    dbPosition: number;
    redisPosition: number;
  }>;
};

/**
 * Wait time mismatch detection result
 */
export type WaitTimeMismatch = {
  shopId: string;
  lane: QueueLane;
  bookingId: string;
  dbWaitMinutes: number;
  redisWaitMinutes: number;
  discrepancy: number;
};

/**
 * Stale socket detection result
 */
export type StaleSocket = {
  socketId: string;
  userId: string;
  shopId?: string;
  bookingId?: string;
  lastHeartbeat: Date;
  minutesSinceHeartbeat: number;
  reason: "NO_HEARTBEAT" | "BOOKING_COMPLETED" | "BOOKING_CANCELLED" | "TIMEOUT";
};

/**
 * Recovery statistics
 */
export type RecoveryStats = {
  chairsRecovered: number;
  servicesFlagged: number;
  queueEntriesRecovered: number;
  redisRebuilt: number;
  positionsNormalized: number;
  waitTimesRecalculated: number;
  socketsDisconnected: number;
  totalEvents: number;
  criticalEvents: number;
  errorEvents: number;
  warningEvents: number;
  infoEvents: number;
};

/**
 * Recovery configuration
 */
export type RecoveryConfig = {
  chairOrphanTimeoutHours: number;
  serviceStaleTimeoutMinutes: number;
  queueEntryStaleTimeoutHours: number;
  redisRebuildThreshold: number;
  positionStaleThreshold: number;
  waitTimeDiscrepancyThreshold: number;
  socketStaleTimeoutMinutes: number;
  enableAutoRecovery: boolean;
  enableAutoFlagging: boolean;
  enableRedisRebuild: boolean;
  enablePositionNormalization: boolean;
  enableWaitTimeRecalculation: boolean;
  enableSocketCleanup: boolean;
};

/**
 * Default recovery configuration
 */
export const DEFAULT_RECOVERY_CONFIG: RecoveryConfig = {
  chairOrphanTimeoutHours: 2,
  serviceStaleTimeoutMinutes: 120,
  queueEntryStaleTimeoutHours: 24,
  redisRebuildThreshold: 5, // Rebuild if > 5 mismatches
  positionStaleThreshold: 1000,
  waitTimeDiscrepancyThreshold: 10, // minutes
  socketStaleTimeoutMinutes: 30,
  enableAutoRecovery: true,
  enableAutoFlagging: true,
  enableRedisRebuild: true,
  enablePositionNormalization: true,
  enableWaitTimeRecalculation: true,
  enableSocketCleanup: true
};
