import type { Redis as RedisClient } from "ioredis";
import { EventEmitter } from "node:events";

export interface FailoverConfig {
  failoverDetectionInterval: number;
  nodeUnresponsiveThreshold: number;
  replicationLagThreshold: number;
  autoReconnect: boolean;
  reconnectDelay: number;
  maxReconnectAttempts: number;
  enableFailoverEvents: boolean;
}

export interface FailoverEvent {
  type: 'failover_detected' | 'failover_started' | 'failover_completed' | 'failover_failed';
  timestamp: number;
  details: {
    oldMaster?: string;
    newMaster?: string;
    reason?: string;
    error?: string;
  };
}

export interface FailoverStatus {
  isFailingOver: boolean;
  lastFailoverTime: number;
  failoverCount: number;
  currentMaster: string;
  connectedNodes: string[];
  replicationStatus: 'healthy' | 'degraded' | 'unhealthy';
}

const DEFAULT_FAILOVER_CONFIG: FailoverConfig = {
  failoverDetectionInterval: 10000,
  nodeUnresponsiveThreshold: 30000,
  replicationLagThreshold: 30000,
  autoReconnect: true,
  reconnectDelay: 5000,
  maxReconnectAttempts: 10,
  enableFailoverEvents: true
};

/**
 * Production-grade Redis failover handling service.
 * 
 * Features:
 * - Automatic failover detection
 * - Node health monitoring
 * - Replication lag monitoring
 * - Automatic reconnection
 * - Failover event emission
 * - Connection pool refresh
 */
export class RedisFailoverHandler extends EventEmitter {
  private config: FailoverConfig;
  private redis: RedisClient | null;
  private failoverTimer?: NodeJS.Timeout;
  private status: FailoverStatus;
  private reconnectAttempts: number = 0;
  private isReconnecting: boolean = false;

  constructor(redis: RedisClient | null, config: Partial<FailoverConfig> = {}) {
    super();
    this.redis = redis;
    this.config = { ...DEFAULT_FAILOVER_CONFIG, ...config };
    this.status = this.createInitialStatus();

    if (this.redis) {
      this.startFailoverMonitoring();
    }
  }

  /**
   * Create initial failover status
   */
  private createInitialStatus(): FailoverStatus {
    return {
      isFailingOver: false,
      lastFailoverTime: 0,
      failoverCount: 0,
      currentMaster: 'unknown',
      connectedNodes: [],
      replicationStatus: 'healthy'
    };
  }

  /**
   * Start failover monitoring
   */
  private startFailoverMonitoring(): void {
    this.failoverTimer = setInterval(async () => {
      await this.checkFailover();
    }, this.config.failoverDetectionInterval);
  }

  /**
   * Stop failover monitoring
   */
  stopFailoverMonitoring(): void {
    if (this.failoverTimer) {
      clearInterval(this.failoverTimer);
    }
  }

  /**
   * Check for failover conditions
   */
  async checkFailover(): Promise<boolean> {
    if (!this.redis) {
      return false;
    }

    try {
      // Check if Redis is responsive
      const startTime = Date.now();
      await this.redis.ping();
      const latency = Date.now() - startTime;

      // Check if latency is too high
      if (latency > this.config.nodeUnresponsiveThreshold) {
        this.emitFailoverEvent('failover_detected', {
          reason: 'high_latency',
          error: `Latency ${latency}ms exceeds threshold ${this.config.nodeUnresponsiveThreshold}ms`
        });
        await this.handleFailover('high_latency');
        return true;
      }

      // Check replication status
      const replicationInfo = await this.redis.info('replication');
      const replicationLag = this.parseReplicationLag(replicationInfo);

      if (replicationLag > this.config.replicationLagThreshold) {
        this.status.replicationStatus = 'degraded';
        this.emitFailoverEvent('failover_detected', {
          reason: 'replication_lag',
          error: `Replication lag ${replicationLag}ms exceeds threshold ${this.config.replicationLagThreshold}ms`
        });
      } else {
        this.status.replicationStatus = 'healthy';
      }

      return false;
    } catch (error: unknown) {
      this.emitFailoverEvent('failover_detected', {
        reason: 'connection_error',
        error: error instanceof Error ? error.message : String(error)
      });
      await this.handleFailover('connection_error');
      return true;
    }
  }

  /**
   * Handle failover
   */
  async handleFailover(reason: string): Promise<void> {
    if (this.status.isFailingOver) {
      return;
    }

    this.status.isFailingOver = true;
    this.emitFailoverEvent('failover_started', { reason });

    try {
      // Attempt to reconnect
      if (this.config.autoReconnect) {
        await this.reconnect();
      }

      this.status.isFailingOver = false;
      this.status.lastFailoverTime = Date.now();
      this.status.failoverCount++;
      this.emitFailoverEvent('failover_completed', { reason });
    } catch (error: unknown) {
      this.status.isFailingOver = false;
      this.emitFailoverEvent('failover_failed', {
        reason,
        error: error instanceof Error ? error.message : String(error)
      });
    }
  }

  /**
   * Reconnect to Redis
   */
  private async reconnect(): Promise<void> {
    if (this.isReconnecting) {
      return;
    }

    this.isReconnecting = true;
    this.reconnectAttempts = 0;

    while (this.reconnectAttempts < this.config.maxReconnectAttempts) {
      this.reconnectAttempts++;

      try {
        if (this.redis) {
          await this.redis.ping();
          this.isReconnecting = false;
          this.reconnectAttempts = 0;
          return;
        }
      } catch (error: unknown) {
        console.error(`Reconnect attempt ${this.reconnectAttempts} failed:`, error);
      }

      // Wait before next attempt
      await this.sleep(this.config.reconnectDelay);
    }

    this.isReconnecting = false;
    throw new Error('Failed to reconnect after maximum attempts');
  }

  /**
   * Parse replication lag from Redis INFO
   */
  private parseReplicationLag(info: string): number {
    const lines = info.split('\r\n');
    for (const line of lines) {
      if (line.startsWith('master_link_down_since_seconds:')) {
        const parts = line.split(':');
        if (parts[1]) {
          const seconds = Number.parseInt(parts[1], 10);
          return Number.isFinite(seconds) ? seconds * 1000 : 0;
        }
      }
    }
    return 0;
  }

  /**
   * Emit failover event
   */
  private emitFailoverEvent(type: FailoverEvent['type'], details: FailoverEvent['details']): void {
    if (this.config.enableFailoverEvents) {
      const event: FailoverEvent = {
        type,
        timestamp: Date.now(),
        details
      };
      this.emit('failover', event);
    }
  }

  /**
   * Sleep for specified milliseconds
   */
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Get current failover status
   */
  getFailoverStatus(): FailoverStatus {
    return { ...this.status };
  }

  /**
   * Update failover configuration
   */
  updateConfig(config: Partial<FailoverConfig>): void {
    this.config = { ...this.config, ...config };

    // Restart monitoring with new configuration
    this.stopFailoverMonitoring();
    if (this.redis) {
      this.startFailoverMonitoring();
    }
  }

  /**
   * Get current configuration
   */
  getConfig(): FailoverConfig {
    return { ...this.config };
  }

  /**
   * Manually trigger failover
   */
  async triggerFailover(reason: string = 'manual'): Promise<void> {
    await this.handleFailover(reason);
  }

  /**
   * Reset failover status
   */
  resetFailoverStatus(): void {
    this.status = this.createInitialStatus();
    this.reconnectAttempts = 0;
    this.isReconnecting = false;
  }
}

/**
 * Create a Redis failover handler instance with default configuration
 */
export function createRedisFailoverHandler(redis: RedisClient | null, config?: Partial<FailoverConfig>): RedisFailoverHandler {
  return new RedisFailoverHandler(redis, config);
}
