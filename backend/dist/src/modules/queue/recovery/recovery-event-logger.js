/**
 * Recovery event logger.
 *
 * Logs recovery events for monitoring, alerting, and audit purposes.
 * Provides methods to query events by severity, type, shop, or time range.
 */
export class RecoveryEventLogger {
    events = [];
    maxEvents;
    constructor(maxEvents = 10000) {
        this.maxEvents = maxEvents;
    }
    /**
     * Log a recovery event
     */
    logEvent(event) {
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
    getAllEvents() {
        return [...this.events];
    }
    /**
     * Get events by severity
     */
    getEventsBySeverity(severity) {
        return this.events.filter(e => e.severity === severity);
    }
    /**
     * Get events by type
     */
    getEventsByType(type) {
        return this.events.filter(e => e.type === type);
    }
    /**
     * Get events by shop
     */
    getEventsByShop(shopId) {
        return this.events.filter(e => e.shopId === shopId);
    }
    /**
     * Get events by time range
     */
    getEventsByTimeRange(start, end) {
        return this.events.filter(e => e.recoveredAt >= start && e.recoveredAt <= end);
    }
    /**
     * Get recent events
     */
    getRecentEvents(limit = 100) {
        return this.events.slice(-limit);
    }
    /**
     * Get event statistics
     */
    getStats() {
        const bySeverity = {};
        const byType = {};
        const byShop = {};
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
    clearEvents() {
        this.events.length = 0;
    }
    /**
     * Clear events older than specified duration
     */
    clearOldEvents(olderThanMs) {
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
    aggregateStatsFromEvents(recoveryStats) {
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
    exportEventsToJson() {
        return JSON.stringify(this.events, null, 2);
    }
    /**
     * Import events from JSON
     */
    importEventsFromJson(json) {
        try {
            const importedEvents = JSON.parse(json);
            this.events.push(...importedEvents);
            // Trim if exceeds max events
            if (this.events.length > this.maxEvents) {
                this.events.splice(0, this.events.length - this.maxEvents);
            }
        }
        catch (error) {
            console.error("Failed to import events from JSON:", error);
        }
    }
    /**
     * Get events that need attention (ERROR or CRITICAL)
     */
    getEventsNeedingAttention() {
        return this.events.filter(e => e.severity === "ERROR" || e.severity === "CRITICAL");
    }
    /**
     * Get events by booking ID
     */
    getEventsByBooking(bookingId) {
        return this.events.filter(e => e.bookingId === bookingId);
    }
    /**
     * Get events by chair ID
     */
    getEventsByChair(chairId) {
        return this.events.filter(e => e.chairId === chairId);
    }
}
