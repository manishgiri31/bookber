import type { Prisma, BookingStatus } from "@prisma/client";
import { prisma } from "../../../shared/prisma/client.js";
import type { StaleSocket, RecoveryConfig, RecoveryStats } from "./recovery-types.js";
import { DEFAULT_RECOVERY_CONFIG } from "./recovery-types.js";
import { RecoveryTransactionManager } from "./recovery-transaction-manager.js";
import { QueueLock } from "../queue.lock.js";

/**
 * Dead socket cleanup worker.
 * 
 * Detects and disconnects stale socket connections that are no longer active.
 * This can happen when:
 * - Client disconnects without proper cleanup
 * - Network issues prevent heartbeat
 * - Browser tab is closed
 * - Booking is completed/cancelled but socket remains connected
 */
export class DeadSocketCleanupWorker {
  private readonly config: RecoveryConfig;
  private readonly transactionManager: RecoveryTransactionManager;
  private readonly intervalMs: number;
  private readonly lock: QueueLock;

  constructor(
    lock: QueueLock,
    config: Partial<RecoveryConfig> = {},
    intervalMs: number = 5 * 60 * 1000 // Default: 5 minutes
  ) {
    this.config = { ...DEFAULT_RECOVERY_CONFIG, ...config };
    this.transactionManager = new RecoveryTransactionManager(this.config);
    this.intervalMs = intervalMs;
    this.lock = lock;
  }

  /**
   * Detect stale sockets across all active shops
   */
  async detectStaleSockets(socketManager: any): Promise<StaleSocket[]> {
    const staleSockets: StaleSocket[] = [];

    if (!socketManager || !socketManager.getAllSockets) {
      return staleSockets;
    }

    const allSockets = await socketManager.getAllSockets();
    const now = new Date();
    const staleThreshold = new Date(now.getTime() - this.config.socketStaleTimeoutMinutes * 60 * 1000);

    for (const socket of allSockets) {
      const userId = socket.userId;
      const lastHeartbeat = socket.lastHeartbeat || socket.connectedAt;

      if (!lastHeartbeat || lastHeartbeat < staleThreshold) {
        const minutesSinceHeartbeat = Math.floor((now.getTime() - lastHeartbeat.getTime()) / 60_000);
        let reason: "NO_HEARTBEAT" | "BOOKING_COMPLETED" | "BOOKING_CANCELLED" | "TIMEOUT" = "TIMEOUT";

        // Check if user has active booking
        if (userId) {
          const activeBooking = await prisma.booking.findFirst({
            where: {
              userId,
              status: { in: ["IN_SERVICE", "READY", "CALLED"] }
            },
            select: {
              id: true,
              shopId: true,
              status: true
            }
          });

          if (activeBooking) {
            if (activeBooking.status === "COMPLETED") {
              reason = "BOOKING_COMPLETED";
            } else if (activeBooking.status === "CANCELLED") {
              reason = "BOOKING_CANCELLED";
            }
          }
        }

        staleSockets.push({
          socketId: socket.id,
          userId: socket.userId || "unknown",
          shopId: socket.shopId,
          bookingId: socket.bookingId,
          lastHeartbeat,
          minutesSinceHeartbeat,
          reason
        });
      }
    }

    return staleSockets;
  }

  /**
   * Auto-disconnect stale sockets
   */
  async disconnectStaleSockets(staleSockets: StaleSocket[], socketManager: any): Promise<number> {
    if (!this.config.enableSocketCleanup || !socketManager) {
      return 0;
    }

    let disconnected = 0;

    for (const staleSocket of staleSockets) {
      try {
        // Disconnect the socket
        await socketManager.disconnectSocket(staleSocket.socketId);

        // Log the cleanup event
        await this.transactionManager.executeRecovery(
          () => this.logSocketCleanup(staleSocket),
          "SOCKET_DISCONNECTED",
          staleSocket.shopId || "global",
          "Disconnect stale socket"
        );

        disconnected++;
      } catch (error) {
        console.error(`Failed to disconnect socket ${staleSocket.socketId}:`, error);
      }
    }

    return disconnected;
  }

  /**
   * Log socket cleanup event
   */
  private async logSocketCleanup(staleSocket: StaleSocket): Promise<void> {
    await prisma.queueEvent.create({
      data: {
        shopId: staleSocket.shopId || "global",
        type: "POSITION_CHANGED", // Use existing event type for socket cleanup
        payload: {
          socketId: staleSocket.socketId,
          userId: staleSocket.userId,
          bookingId: staleSocket.bookingId,
          reason: staleSocket.reason,
          minutesSinceHeartbeat: staleSocket.minutesSinceHeartbeat,
          socketCleanup: true
        }
      }
    });
  }

  /**
   * Run the dead socket cleanup worker
   */
  async run(socketManager: any): Promise<RecoveryStats> {
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
      // Use withLock for distributed locking
      await this.lock.withLock("socket:cleanup", 30000, async () => {
        const staleSockets = await this.detectStaleSockets(socketManager);

        if (staleSockets.length > 0) {
          const disconnected = await this.disconnectStaleSockets(staleSockets, socketManager);
          stats.socketsDisconnected = disconnected;

          const events = this.transactionManager.getEvents();
          stats.totalEvents = events.length;
          stats.criticalEvents = events.filter(e => e.severity === "CRITICAL").length;
          stats.errorEvents = events.filter(e => e.severity === "ERROR").length;
          stats.warningEvents = events.filter(e => e.severity === "WARNING").length;
          stats.infoEvents = events.filter(e => e.severity === "INFO").length;
        }

        this.transactionManager.clearEvents();
      });
    } catch (error) {
      if (error instanceof Error && error.message === "QUEUE_LOCK_BUSY") {
        console.log("Socket cleanup lock already acquired, skipping this run");
      } else {
        console.error("Dead socket cleanup worker failed:", error);
      }
    }

    return stats;
  }

  /**
   * Start the periodic worker
   */
  start(socketManager: any): () => void {
    const interval = setInterval(() => {
      this.run(socketManager).catch((error) => {
        console.error("Dead socket cleanup worker failed:", error);
      });
    }, this.intervalMs);

    // Run immediately on start
    this.run(socketManager).catch((error) => {
      console.error("Dead socket cleanup worker failed:", error);
    });

    return () => clearInterval(interval);
  }

  /**
   * Get statistics for monitoring
   */
  async getStats(socketManager: any): Promise<{
    totalSockets: number;
    staleSockets: number;
    byReason: Record<string, number>;
    byShop: Record<string, number>;
  }> {
    if (!socketManager || !socketManager.getAllSockets) {
      return {
        totalSockets: 0,
        staleSockets: 0,
        byReason: {},
        byShop: {}
      };
    }

    const allSockets = await socketManager.getAllSockets();
    const staleSockets = await this.detectStaleSockets(socketManager);

    const byReason: Record<string, number> = {};
    const byShop: Record<string, number> = {};

    for (const socket of staleSockets) {
      byReason[socket.reason] = (byReason[socket.reason] || 0) + 1;
      if (socket.shopId) {
        byShop[socket.shopId] = (byShop[socket.shopId] || 0) + 1;
      }
    }

    return {
      totalSockets: allSockets.length,
      staleSockets: staleSockets.length,
      byReason,
      byShop
    };
  }

  /**
   * Manually disconnect a specific socket
   */
  async disconnectSocket(socketId: string, socketManager: any): Promise<void> {
    if (!socketManager) {
      throw new Error("Socket manager not available");
    }

    await socketManager.disconnectSocket(socketId);
  }

  /**
   * Manually disconnect all sockets for a user
   */
  async disconnectUserSockets(userId: string, socketManager: any): Promise<number> {
    if (!socketManager || !socketManager.getUserSockets) {
      return 0;
    }

    const userSockets = await socketManager.getUserSockets(userId);
    let disconnected = 0;

    for (const socket of userSockets) {
      try {
        await socketManager.disconnectSocket(socket.id);
        disconnected++;
      } catch (error) {
        console.error(`Failed to disconnect socket ${socket.id}:`, error);
      }
    }

    return disconnected;
  }

  /**
   * Manually disconnect all sockets for a shop
   */
  async disconnectShopSockets(shopId: string, socketManager: any): Promise<number> {
    if (!socketManager || !socketManager.getShopSockets) {
      return 0;
    }

    const shopSockets = await socketManager.getShopSockets(shopId);
    let disconnected = 0;

    for (const socket of shopSockets) {
      try {
        await socketManager.disconnectSocket(socket.id);
        disconnected++;
      } catch (error) {
        console.error(`Failed to disconnect socket ${socket.id}:`, error);
      }
    }

    return disconnected;
  }
}
