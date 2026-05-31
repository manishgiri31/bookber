/**
 * Default recovery configuration
 */
export const DEFAULT_RECOVERY_CONFIG = {
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
