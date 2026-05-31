import type { Redis as RedisClient } from "ioredis";
import type { RecoveryConfig, RecoveryStats } from "./recovery-types.js";
import { DEFAULT_RECOVERY_CONFIG } from "./recovery-types.js";
import { StaleServiceDetectorWorker } from "./stale-service-detector.worker.js";
import { ChairRecoveryWorker } from "./chair-recovery.worker.js";
import { QueueReconcilerWorker } from "./queue-reconciler.worker.js";
import { WaitTimeReconcilerWorker } from "./wait-time-reconciler.worker.js";
import { RedisRepairService } from "./redis-repair.service.js";
import { DeadSocketCleanupWorker } from "./dead-socket-cleanup.worker.js";
import { QueueLock } from "../queue.lock.js";

/**
 * Recovery orchestrator.
 * 
 * Manages all recovery workers and coordinates their execution.
 * Provides unified interface for running all recovery operations
 * and collecting aggregate statistics.
 */
export class RecoveryOrchestrator {
  private readonly config: RecoveryConfig;
  private readonly lock: QueueLock;
  private readonly staleServiceDetector: StaleServiceDetectorWorker;
  private readonly chairRecoveryWorker: ChairRecoveryWorker;
  private readonly queueReconcilerWorker: QueueReconcilerWorker;
  private readonly waitTimeReconcilerWorker: WaitTimeReconcilerWorker;
  private readonly redisRepairService: RedisRepairService;
  private readonly deadSocketCleanupWorker: DeadSocketCleanupWorker;

  private readonly cleanupFunctions: Array<() => void> = [];
  private isRunning = false;

  constructor(
    lock: QueueLock,
    config: Partial<RecoveryConfig> = {},
    redis: RedisClient | null = null,
    waitTimeEngine: any = null
  ) {
    this.config = { ...DEFAULT_RECOVERY_CONFIG, ...config };
    this.lock = lock;

    // Initialize all workers with distributed locking
    this.staleServiceDetector = new StaleServiceDetectorWorker(this.config);
    this.chairRecoveryWorker = new ChairRecoveryWorker(lock, this.config);
    this.queueReconcilerWorker = new QueueReconcilerWorker(lock, this.config);
    this.waitTimeReconcilerWorker = new WaitTimeReconcilerWorker(lock, this.config);
    this.redisRepairService = new RedisRepairService(lock, this.config);
    this.deadSocketCleanupWorker = new DeadSocketCleanupWorker(lock, this.config);
  }

  /**
   * Start all recovery workers
   */
  start(redis: RedisClient | null = null, waitTimeEngine: any = null, socketManager: any = null): void {
    if (this.isRunning) {
      console.warn("Recovery orchestrator is already running");
      return;
    }

    this.isRunning = true;

    // Start stale service detector
    const stopStaleServiceDetector = this.staleServiceDetector.start();
    this.cleanupFunctions.push(stopStaleServiceDetector);

    // Start chair recovery worker
    const stopChairRecoveryWorker = this.chairRecoveryWorker.start();
    this.cleanupFunctions.push(stopChairRecoveryWorker);

    // Start queue reconciler worker
    const stopQueueReconcilerWorker = this.queueReconcilerWorker.start();
    this.cleanupFunctions.push(stopQueueReconcilerWorker);

    // Start wait-time reconciler worker (if Redis and waitTimeEngine available)
    if (redis && waitTimeEngine) {
      const stopWaitTimeReconcilerWorker = this.waitTimeReconcilerWorker.start(redis, waitTimeEngine);
      this.cleanupFunctions.push(stopWaitTimeReconcilerWorker);
    }

    // Start Redis repair service (if Redis available)
    if (redis) {
      const stopRedisRepairService = this.redisRepairService.start(redis);
      this.cleanupFunctions.push(stopRedisRepairService);
    }

    // Start socket cleanup worker (if socketManager available)
    if (socketManager) {
      const stopDeadSocketCleanupWorker = this.deadSocketCleanupWorker.start(socketManager);
      this.cleanupFunctions.push(stopDeadSocketCleanupWorker);
    }

    console.log("Recovery orchestrator started with", this.cleanupFunctions.length, "workers");
  }

  /**
   * Stop all recovery workers
   */
  stop(): void {
    if (!this.isRunning) {
      return;
    }

    this.isRunning = false;

    for (const cleanup of this.cleanupFunctions) {
      try {
        cleanup();
      } catch (error) {
        console.error("Error stopping recovery worker:", error);
      }
    }

    this.cleanupFunctions.length = 0;
    console.log("Recovery orchestrator stopped");
  }

  /**
   * Run all recovery operations once (manual trigger)
   */
  async runOnce(redis: RedisClient | null = null, waitTimeEngine: any = null, socketManager: any = null): Promise<RecoveryStats> {
    const aggregateStats: RecoveryStats = {
      chairsRecovered: 0,
      servicesFlagged: 0,
      queueEntriesRecovered: 0,
      redisRebuilt: 0,
      positionsNormalized: 0,
      waitTimesRecalculated: 0,
      socketsDisconnected: 0,
      totalEvents: 0,
      criticalEvents: 0,
      errorEvents: 0,
      warningEvents: 0,
      infoEvents: 0
    };

    try {
      // Run stale service detector
      const staleServiceStats = await this.staleServiceDetector.run();
      this.aggregateStats(aggregateStats, staleServiceStats);

      // Run chair recovery worker
      const chairRecoveryStats = await this.chairRecoveryWorker.run();
      this.aggregateStats(aggregateStats, chairRecoveryStats);

      // Run queue reconciler worker
      const queueReconcilerStats = await this.queueReconcilerWorker.run();
      this.aggregateStats(aggregateStats, queueReconcilerStats);

      // Run wait-time reconciler worker (if Redis and waitTimeEngine available)
      if (redis && waitTimeEngine) {
        const waitTimeReconcilerStats = await this.waitTimeReconcilerWorker.run(redis, waitTimeEngine);
        this.aggregateStats(aggregateStats, waitTimeReconcilerStats);
      }

      // Run Redis repair service (if Redis available)
      if (redis) {
        const redisRepairStats = await this.redisRepairService.run(redis);
        this.aggregateStats(aggregateStats, redisRepairStats);
      }

      // Run socket cleanup worker (if socketManager available)
      if (socketManager) {
        const socketCleanupStats = await this.deadSocketCleanupWorker.run(socketManager);
        this.aggregateStats(aggregateStats, socketCleanupStats);
      }
    } catch (error) {
      console.error("Error running recovery operations:", error);
    }

    return aggregateStats;
  }

  /**
   * Aggregate stats from individual workers
   */
  private aggregateStats(aggregate: RecoveryStats, individual: RecoveryStats): void {
    aggregate.chairsRecovered += individual.chairsRecovered;
    aggregate.servicesFlagged += individual.servicesFlagged;
    aggregate.queueEntriesRecovered += individual.queueEntriesRecovered;
    aggregate.redisRebuilt += individual.redisRebuilt;
    aggregate.positionsNormalized += individual.positionsNormalized;
    aggregate.waitTimesRecalculated += individual.waitTimesRecalculated;
    aggregate.socketsDisconnected += individual.socketsDisconnected;
    aggregate.totalEvents += individual.totalEvents;
    aggregate.criticalEvents += individual.criticalEvents;
    aggregate.errorEvents += individual.errorEvents;
    aggregate.warningEvents += individual.warningEvents;
    aggregate.infoEvents += individual.infoEvents;
  }

  /**
   * Get aggregate health statistics from all workers
   */
  async getHealthStats(redis: RedisClient | null = null, socketManager: any = null): Promise<{
    staleServices: Awaited<ReturnType<StaleServiceDetectorWorker["getStats"]>>;
    orphanedChairs: Awaited<ReturnType<ChairRecoveryWorker["getStats"]>>;
    deadQueueEntries: Awaited<ReturnType<QueueReconcilerWorker["getStats"]>>;
    waitTimeMismatches: Awaited<ReturnType<WaitTimeReconcilerWorker["getStats"]>>;
    redisMismatches: Awaited<ReturnType<RedisRepairService["getStats"]>>;
    staleSockets: Awaited<ReturnType<DeadSocketCleanupWorker["getStats"]>>;
  }> {
    const [staleServices, orphanedChairs, deadQueueEntries] = await Promise.all([
      this.staleServiceDetector.getStats(),
      this.chairRecoveryWorker.getStats(),
      this.queueReconcilerWorker.getStats()
    ]);

    let waitTimeMismatches: Awaited<ReturnType<WaitTimeReconcilerWorker["getStats"]>>;
    let redisMismatches: Awaited<ReturnType<RedisRepairService["getStats"]>>;
    let staleSockets: Awaited<ReturnType<DeadSocketCleanupWorker["getStats"]>>;

    if (redis) {
      [waitTimeMismatches, redisMismatches] = await Promise.all([
        this.waitTimeReconcilerWorker.getStats(redis),
        this.redisRepairService.getStats(redis)
      ]);
    } else {
      waitTimeMismatches = {
        totalActiveQueue: 0,
        mismatches: 0,
        byShop: {},
        byLane: {},
        averageDiscrepancy: 0,
        maxDiscrepancy: 0
      };
      redisMismatches = {
        totalShops: 0,
        mismatchedShops: 0,
        mismatchedLanes: 0,
        totalMismatches: 0,
        byShop: {},
        byLane: {}
      };
    }

    if (socketManager) {
      staleSockets = await this.deadSocketCleanupWorker.getStats(socketManager);
    } else {
      staleSockets = {
        totalSockets: 0,
        staleSockets: 0,
        byReason: {},
        byShop: {}
      };
    }

    return {
      staleServices,
      orphanedChairs,
      deadQueueEntries,
      waitTimeMismatches,
      redisMismatches,
      staleSockets
    };
  }

  /**
   * Manually recover a specific chair
   */
  async recoverChair(chairId: string): Promise<void> {
    return this.chairRecoveryWorker.recoverChair(chairId);
  }

  /**
   * Manually reconcile a specific shop
   */
  async reconcileShop(shopId: string): Promise<{
    deadEntriesRecovered: number;
    positionsNormalized: number;
  }> {
    return this.queueReconcilerWorker.reconcileShop(shopId);
  }

  /**
   * Manually recalculate wait times for a specific shop
   */
  async recalculateShopWaitTimes(shopId: string, waitTimeEngine: any): Promise<{
    lanesRecalculated: number;
  }> {
    return this.waitTimeReconcilerWorker.recalculateShopWaitTimes(shopId, waitTimeEngine);
  }

  /**
   * Manually rebuild Redis queue for a specific shop
   */
  async rebuildShopRedis(shopId: string, redis: RedisClient): Promise<void> {
    return this.redisRepairService.rebuildShopRedis(shopId, redis);
  }

  /**
   * Manually clear all Redis data for a specific shop (emergency recovery)
   */
  async clearShopRedis(shopId: string, redis: RedisClient): Promise<void> {
    return this.redisRepairService.clearShopRedis(shopId, redis);
  }

  /**
   * Manually disconnect a specific socket
   */
  async disconnectSocket(socketId: string, socketManager: any): Promise<void> {
    return this.deadSocketCleanupWorker.disconnectSocket(socketId, socketManager);
  }

  /**
   * Manually disconnect all sockets for a user
   */
  async disconnectUserSockets(userId: string, socketManager: any): Promise<number> {
    return this.deadSocketCleanupWorker.disconnectUserSockets(userId, socketManager);
  }

  /**
   * Manually disconnect all sockets for a shop
   */
  async disconnectShopSockets(shopId: string, socketManager: any): Promise<number> {
    return this.deadSocketCleanupWorker.disconnectShopSockets(shopId, socketManager);
  }

  /**
   * Check if orchestrator is running
   */
  isActive(): boolean {
    return this.isRunning;
  }

  /**
   * Get configuration
   */
  getConfig(): RecoveryConfig {
    return { ...this.config };
  }

  /**
   * Update configuration
   */
  updateConfig(config: Partial<RecoveryConfig>): void {
    Object.assign(this.config, config);
  }
}
