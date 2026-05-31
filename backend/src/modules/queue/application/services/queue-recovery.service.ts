import type { Redis as RedisClient } from "ioredis";
import { RecoveryOrchestrator } from "../../recovery/recovery-orchestrator.js";
import { RecoveryEventLogger } from "../../recovery/recovery-event-logger.js";
import { WaitTimeEngine } from "../wait-time.engine.js";

/**
 * QueueRecoveryService handles recovery and reconciliation operations.
 * 
 * Responsibilities:
 * - Coordinate recovery workers
 * - Detect and recover inconsistent queue states
 * - Log recovery events
 * - Provide recovery statistics
 * 
 * Transaction ownership: Owns recovery transactions
 * Redis ownership: Owns Redis repair operations
 * Event ownership: Owns recovery event logging
 */
export class QueueRecoveryService {
  constructor(
    private readonly recoveryOrchestrator: RecoveryOrchestrator,
    private readonly recoveryEventLogger: RecoveryEventLogger
  ) { }

  /**
   * Start all recovery workers
   */
  startWorkers(redis?: RedisClient, waitTimeEngine?: any): void {
    this.recoveryOrchestrator.start(redis, waitTimeEngine);
  }

  /**
   * Stop all recovery workers
   */
  stopWorkers(): void {
    this.recoveryOrchestrator.stop();
  }

  /**
   * Run recovery operation once
   */
  async runRecovery(redis?: RedisClient, waitTimeEngine?: any): Promise<void> {
    await this.recoveryOrchestrator.runOnce(redis, waitTimeEngine);
  }

  /**
   * Get recovery health statistics
   */
  async getHealthStats(redis?: RedisClient): Promise<{
    staleServices: any;
    orphanedChairs: any;
    deadQueueEntries: any;
    waitTimeMismatches: any;
    redisMismatches: any;
  }> {
    return this.recoveryOrchestrator.getHealthStats(redis);
  }

  /**
   * Recover orphaned chair
   */
  async recoverChair(chairId: string): Promise<void> {
    await this.recoveryOrchestrator.recoverChair(chairId);
  }

  /**
   * Get recovery events
   */
  getRecoveryEvents(filters?: {
    severity?: "CRITICAL" | "ERROR" | "WARNING" | "INFO";
    type?: string;
    shopId?: string;
    limit?: number;
  }): any[] {
    let events = this.recoveryEventLogger.getAllEvents();

    if (filters?.severity) {
      events = events.filter(e => e.severity === filters.severity);
    }
    if (filters?.type) {
      events = events.filter(e => e.type === filters.type);
    }
    if (filters?.shopId) {
      events = events.filter(e => e.shopId === filters.shopId);
    }
    if (filters?.limit) {
      events = events.slice(0, filters.limit);
    }

    return events;
  }

  /**
   * Clear old recovery events
   */
  clearOldEvents(olderThanMinutes: number = 60): void {
    const cutoff = Date.now() - olderThanMinutes * 60 * 1000;
    const events = this.recoveryEventLogger.getAllEvents();

    for (let i = events.length - 1; i >= 0; i--) {
      const event = events[i];
      if (event && event.recoveredAt.getTime() < cutoff) {
        // Note: RecoveryEventLogger doesn't have a delete method, so this is a placeholder
        // In production, you'd need to add a delete method to RecoveryEventLogger
      }
    }
  }

  /**
   * Get recovery event statistics
   */
  getRecoveryStats(): any {
    const events = this.recoveryEventLogger.getAllEvents();
    return {
      total: events.length,
      bySeverity: {
        CRITICAL: events.filter(e => e.severity === "CRITICAL").length,
        ERROR: events.filter(e => e.severity === "ERROR").length,
        WARNING: events.filter(e => e.severity === "WARNING").length,
        INFO: events.filter(e => e.severity === "INFO").length
      },
      byType: events.reduce((acc, e) => {
        acc[e.type] = (acc[e.type] || 0) + 1;
        return acc;
      }, {} as Record<string, number>)
    };
  }
}
