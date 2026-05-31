import { prisma } from "../../../shared/prisma/client.js";
import type { StaleService, RecoveryConfig, RecoveryStats } from "./recovery-types.js";
import { DEFAULT_RECOVERY_CONFIG } from "./recovery-types.js";
import { RecoveryTransactionManager } from "./recovery-transaction-manager.js";

/**
 * Stale service detector worker.
 * 
 * Detects services that have been running for too long without completion.
 * This can happen when:
 * - Barber forgets to complete service
 * - System crash during service
 * - Network issues prevent completion
 * - Chair is released but booking remains IN_SERVICE
 */
export class StaleServiceDetectorWorker {
  private readonly config: RecoveryConfig;
  private readonly transactionManager: RecoveryTransactionManager;
  private readonly intervalMs: number;

  constructor(
    config: Partial<RecoveryConfig> = {},
    intervalMs: number = 5 * 60 * 1000 // Default: 5 minutes
  ) {
    this.config = { ...DEFAULT_RECOVERY_CONFIG, ...config };
    this.transactionManager = new RecoveryTransactionManager(this.config);
    this.intervalMs = intervalMs;
  }

  /**
   * Detect stale services across all active shops
   */
  async detectStaleServices(): Promise<StaleService[]> {
    const staleServices: StaleService[] = [];

    const shops = await prisma.shop.findMany({
      where: { isActive: true },
      select: { id: true }
    });

    for (const shop of shops) {
      const shopStaleServices = await this.detectStaleServicesForShop(shop.id);
      staleServices.push(...shopStaleServices);
    }

    return staleServices;
  }

  /**
   * Detect stale services for a specific shop
   */
  async detectStaleServicesForShop(shopId: string): Promise<StaleService[]> {
    const staleServices: StaleService[] = [];
    const now = new Date();
    const timeoutThreshold = new Date(now.getTime() - this.config.serviceStaleTimeoutMinutes * 60 * 1000);

    const inServiceBookings = await prisma.booking.findMany({
      where: {
        shopId,
        status: "IN_SERVICE",
        chair: { activeServiceStart: { lt: timeoutThreshold } }
      },
      include: {
        chair: true,
        queueEntry: true
      }
    });

    for (const booking of inServiceBookings) {
      const serviceStart = booking.chair?.activeServiceStart;
      if (!serviceStart) continue;
      const minutesSinceStart = Math.floor((now.getTime() - serviceStart.getTime()) / 60_000);
      let reason: "NO_HEARTBEAT" | "TIMEOUT" | "CHAIR_RELEASED" = "TIMEOUT";

      // Check if chair is still occupied
      if (booking.chair && booking.chair.status !== "OCCUPIED") {
        reason = "CHAIR_RELEASED";
      }

      staleServices.push({
        bookingId: booking.id,
        shopId: booking.shopId,
        userId: booking.userId,
        chairId: booking.chairId,
        status: booking.status,
        activeServiceStart: serviceStart,
        minutesSinceStart,
        timeoutMinutes: this.config.serviceStaleTimeoutMinutes,
        reason
      });
    }

    return staleServices;
  }

  /**
   * Auto-flag stale services
   */
  async flagStaleServices(staleServices: StaleService[]): Promise<number> {
    if (!this.config.enableAutoFlagging) {
      return 0;
    }

    let flagged = 0;

    for (const staleService of staleServices) {
      await this.transactionManager.executeRecovery(
        () => this.transactionManager.flagStaleService(
          staleService.bookingId,
          staleService.shopId,
          staleService.reason,
          staleService.timeoutMinutes
        ),
        "SERVICE_FLAGGED",
        staleService.shopId,
        "Flag stale service"
      );

      if (this.transactionManager.getEvents().length > 0) {
        flagged++;
      }
    }

    return flagged;
  }

  /**
   * Auto-recover stale services (complete them)
   */
  async recoverStaleServices(staleServices: StaleService[]): Promise<number> {
    if (!this.config.enableAutoRecovery) {
      return 0;
    }

    let recovered = 0;

    for (const staleService of staleServices) {
      // Only auto-recover if chair is released
      if (staleService.reason === "CHAIR_RELEASED") {
        await this.transactionManager.executeRecovery(
          () => this.recoverStaleService(staleService),
          "SERVICE_STALE",
          staleService.shopId,
          "Recover stale service"
        );

        if (this.transactionManager.getEvents().length > 0) {
          recovered++;
        }
      }
    }

    return recovered;
  }

  /**
   * Recover a single stale service
   */
  private async recoverStaleService(staleService: StaleService): Promise<void> {
    await prisma.$transaction(async (tx) => {
      // Update booking to completed
      await tx.booking.update({
        where: { id: staleService.bookingId },
        data: {
          status: "COMPLETED"
        }
      });

      // Update queue entry and release service resources.
      if (staleService.chairId) {
        await tx.queueEntry.updateMany({
          where: { bookingId: staleService.bookingId },
          data: { queueStatus: "COMPLETED" }
        });

        // Release chair
        await tx.chair.update({
          where: { id: staleService.chairId },
          data: {
            status: "AVAILABLE",
            activeServiceStart: null,
            activeServiceEnd: new Date()
          }
        });

        // Update allocation
        await tx.chairAllocation.updateMany({
          where: { chairId: staleService.chairId, releasedAt: null },
          data: { releasedAt: new Date(), activeServiceEnd: new Date() }
        });
      }

      // Log recovery event
      await tx.queueEvent.create({
        data: {
          shopId: staleService.shopId,
          bookingId: staleService.bookingId,
          type: "IN_SERVICE",
          payload: {
            autoRecovered: true,
            reason: staleService.reason,
            minutesSinceStart: staleService.minutesSinceStart
          }
        }
      });
    });
  }

  /**
   * Run the stale service detector
   */
  async run(): Promise<RecoveryStats> {
    const stats: RecoveryStats = {
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
      const staleServices = await this.detectStaleServices();
      
      if (staleServices.length > 0) {
        const flagged = await this.flagStaleServices(staleServices);
        const recovered = await this.recoverStaleServices(staleServices);

        stats.servicesFlagged = flagged;
        stats.chairsRecovered = recovered;

        const events = this.transactionManager.getEvents();
        stats.totalEvents = events.length;
        stats.criticalEvents = events.filter(e => e.severity === "CRITICAL").length;
        stats.errorEvents = events.filter(e => e.severity === "ERROR").length;
        stats.warningEvents = events.filter(e => e.severity === "WARNING").length;
        stats.infoEvents = events.filter(e => e.severity === "INFO").length;
      }

      this.transactionManager.clearEvents();
    } catch (error) {
      console.error("Stale service detector failed:", error);
    }

    return stats;
  }

  /**
   * Start the periodic worker
   */
  start(): () => void {
    const interval = setInterval(() => {
      this.run().catch((error) => {
        console.error("Stale service detector worker failed:", error);
      });
    }, this.intervalMs);

    // Run immediately on start
    this.run().catch((error) => {
      console.error("Stale service detector worker failed:", error);
    });

    return () => clearInterval(interval);
  }

  /**
   * Get statistics for monitoring
   */
  async getStats(): Promise<{
    totalInService: number;
    staleServices: number;
    byReason: Record<string, number>;
    byShop: Record<string, number>;
  }> {
    const now = new Date();
    const timeoutThreshold = new Date(now.getTime() - this.config.serviceStaleTimeoutMinutes * 60 * 1000);

    const inServiceBookings = await prisma.booking.findMany({
      where: {
        status: "IN_SERVICE"
      },
      include: { chair: true }
    });

    const staleServices = inServiceBookings.filter(
      (b) => b.chair?.activeServiceStart && b.chair.activeServiceStart < timeoutThreshold
    );

    const byReason: Record<string, number> = {};
    const byShop: Record<string, number> = {};

    for (const booking of staleServices) {
      let reason = "TIMEOUT";
      if (booking.chair && booking.chair.status !== "OCCUPIED") {
        reason = "CHAIR_RELEASED";
      }

      byReason[reason] = (byReason[reason] || 0) + 1;
      byShop[booking.shopId] = (byShop[booking.shopId] || 0) + 1;
    }

    return {
      totalInService: inServiceBookings.length,
      staleServices: staleServices.length,
      byReason,
      byShop
    };
  }
}
