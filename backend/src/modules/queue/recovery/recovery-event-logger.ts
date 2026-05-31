import type { RecoveryEvent, RecoveryEventType, RecoveryStats } from "./recovery-types.js";

/**
 * Recovery event logger.
 * 
 * Logs recovery events for monitoring, alerting, and audit purposes.
 * Provides methods to query events by severity, type, shop, or time range.
 */
export class RecoveryEventLogger {
  private readonly events: RecoveryEvent[] = [];
  private readonly maxEvents: number;

  constructor(maxEvents: number = 10000) {
    this.maxEvents = maxEvents;
  }

  /**
   * Log a recovery event
   */
  logEvent(event: RecoveryEvent): void {
    // Add event to log
    this.events.push(event);

    // Trim if exceeds max events
    if (this.events.length > this.maxEvents) {
      this.events.shift();
    }
  }

  /**
   * Get all events
   */
  getAllEvents(): RecoveryEvent[] {
    return [...this.events];
  }

  /**
   * Get events by severity
   */
  getEventsBySeverity(severity: "INFO" | "WARNING" | "ERROR" | "CRITICAL"): RecoveryEvent[] {
    return this.events.filter(e => e.severity === severity);
  }

  /**
   * Get events by type
   */
  getEventsByType(type: RecoveryEventType): RecoveryEvent[] {
    return this.events.filter(e => e.type === type);
  }

  /**
   * Get events by shop
   */
  getEventsByShop(shopId: string): RecoveryEvent[] {
    return this.events.filter(e => e.shopId === shopId);
  }

  /**
   * Get events by time range
   */
  getEventsByTimeRange(start: Date, end: Date): RecoveryEvent[] {
    return this.events.filter(e => e.recoveredAt >= start && e.recoveredAt <= end);
  }

  /**
   * Get recent events
   */
  getRecentEvents(limit: number = 100): RecoveryEvent[] {
    return this.events.slice(-limit);
  }

  /**
   * Get event statistics
   */
  getStats(): {
    totalEvents: number;
    bySeverity: Record<string, number>;
    byType: Record<string, number>;
    byShop: Record<string, number>;
    criticalEvents: number;
    errorEvents: number;
    warningEvents: number;
    infoEvents: number;
  } {
    const bySeverity: Record<string, number> = {};
    const byType: Record<string, number> = {};
    const byShop: Record<string, number> = {};

    for (const event of this.events) {
      bySeverity[event.severity] = (bySeverity[event.severity] || 0) + 1;
      byType[event.type] = (byType[event.type] || 0) + 1;
      byShop[event.shopId] = (byShop[event.shopId] || 0) + 1;
    }

    return {
      totalEvents: this.events.length,
      bySeverity,
      byType,
      byShop,
      criticalEvents: bySeverity["CRITICAL"] || 0,
      errorEvents: bySeverity["ERROR"] || 0,
      warningEvents: bySeverity["WARNING"] || 0,
      infoEvents: bySeverity["INFO"] || 0
    };
  }

  /**
   * Clear all events
   */
  clearEvents(): void {
    this.events.length = 0;
  }

  /**
   * Clear events older than specified duration
   */
  clearOldEvents(olderThanMs: number): number {
    const cutoff = new Date(Date.now() - olderThanMs);
    const initialLength = this.events.length;

    for (let i = this.events.length - 1; i >= 0; i--) {
      const event = this.events[i];
      if (event && event.recoveredAt < cutoff) {
        this.events.splice(i, 1);
      }
    }

    return initialLength - this.events.length;
  }

  /**
   * Aggregate recovery stats from events
   */
  aggregateStatsFromEvents(recoveryStats: RecoveryStats): RecoveryStats {
    const stats = { ...recoveryStats };

    for (const event of this.events) {
      switch (event.type) {
        case "CHAIR_RECOVERED":
          stats.chairsRecovered++;
          break;
        case "SERVICE_FLAGGED":
          stats.servicesFlagged++;
          break;
        case "QUEUE_ENTRY_RECOVERED":
          stats.queueEntriesRecovered++;
          break;
        case "REDIS_REBUILT":
          stats.redisRebuilt++;
          break;
        case "POSITION_NORMALIZED":
          stats.positionsNormalized++;
          break;
        case "WAIT_TIME_RECALCULATED":
          stats.waitTimesRecalculated++;
          break;
      }

      stats.totalEvents++;

      switch (event.severity) {
        case "CRITICAL":
          stats.criticalEvents++;
          break;
        case "ERROR":
          stats.errorEvents++;
          break;
        case "WARNING":
          stats.warningEvents++;
          break;
        case "INFO":
          stats.infoEvents++;
          break;
      }
    }

    return stats;
  }

  /**
   * Export events to JSON
   */
  exportEventsToJson(): string {
    return JSON.stringify(this.events, null, 2);
  }

  /**
   * Import events from JSON
   */
  importEventsFromJson(json: string): void {
    try {
      const importedEvents = JSON.parse(json) as RecoveryEvent[];
      this.events.push(...importedEvents);

      // Trim if exceeds max events
      if (this.events.length > this.maxEvents) {
        this.events.splice(0, this.events.length - this.maxEvents);
      }
    } catch (error) {
      console.error("Failed to import events from JSON:", error);
    }
  }

  /**
   * Get events that need attention (ERROR or CRITICAL)
   */
  getEventsNeedingAttention(): RecoveryEvent[] {
    return this.events.filter(e => e.severity === "ERROR" || e.severity === "CRITICAL");
  }

  /**
   * Get events by booking ID
   */
  getEventsByBooking(bookingId: string): RecoveryEvent[] {
    return this.events.filter(e => e.bookingId === bookingId);
  }

  /**
   * Get events by chair ID
   */
  getEventsByChair(chairId: string): RecoveryEvent[] {
    return this.events.filter(e => e.chairId === chairId);
  }
}
