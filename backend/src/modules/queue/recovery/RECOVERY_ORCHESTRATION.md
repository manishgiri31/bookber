# Queue Recovery Orchestration Guide

## Overview

The queue recovery system consists of specialized workers that detect and heal inconsistencies across the queue system. This guide explains how to orchestrate these workers for production use.

## Workers

### 1. StaleServiceDetectorWorker
**Purpose**: Detects services that have been running for too long without completion.

**Detection Rules**:
- IN_SERVICE booking with `activeServiceStart` > timeout
- Chair released but booking remains IN_SERVICE
- No heartbeat detected

**Recovery Actions**:
- Flag stale services for manual review
- Auto-recover if chair is released

**Redis Lock**: `shop:{shopId}:reconcile`

**Interval**: 5 minutes

### 2. ChairRecoveryWorker
**Purpose**: Detects and recovers orphaned chairs stuck in OCCUPIED state.

**Detection Rules**:
- OCCUPIED chair without active booking > timeout
- OCCUPIED chair with completed/cancelled booking
- OCCUPIED chair without allocation record

**Recovery Actions**:
- Release orphaned chairs
- Update chair status to AVAILABLE
- Close allocation records

**Redis Lock**: `shop:{shopId}:chair-recovery`

**Interval**: 10 minutes

### 3. QueueReconcilerWorker
**Purpose**: Detects and recovers dead queue entries inconsistent with booking state.

**Detection Rules**:
- Booking cancelled/completed but queue entry remains
- Chair released but queue entry is IN_SERVICE
- Stale queue positions (> threshold)
- Very old WAITING entries (> timeout)

**Recovery Actions**:
- Remove dead queue entries
- Normalize stale positions

**Redis Lock**: `shop:{shopId}:reconcile`

**Interval**: 15 minutes

### 4. WaitTimeRebuilderWorker
**Purpose**: Detects and rebuilds wait time inconsistencies between Redis and PostgreSQL.

**Detection Rules**:
- Redis wait time vs DB wait time mismatch > threshold
- Missing Redis snapshots
- Stale Redis cache

**Recovery Actions**:
- Recalculate wait times from DB
- Rebuild Redis snapshots
- Sync Redis with PostgreSQL

**Redis Lock**: `shop:{shopId}:wait-time-rebuild`

**Interval**: 20 minutes

### 5. RedisRepairWorker
**Purpose**: Detects and repairs Redis state inconsistencies with PostgreSQL.

**Detection Rules**:
- Redis queue length vs DB queue length mismatch
- Missing Redis queue entries
- Orphaned Redis entries
- Position mismatches

**Recovery Actions**:
- Rebuild Redis queues from DB
- Remove orphaned Redis entries
- Sync Redis with PostgreSQL

**Redis Lock**: `shop:{shopId}:redis-repair`

**Interval**: 30 minutes

### 6. DeadSocketCleanupWorker (NEW)
**Purpose**: Detects and disconnects stale socket connections.

**Detection Rules**:
- Socket inactive > timeout
- Socket without active booking
- Socket with completed/cancelled booking
- Socket heartbeat timeout

**Recovery Actions**:
- Disconnect stale sockets
- Emit disconnect events

**Redis Lock**: `socket:cleanup`

**Interval**: 5 minutes

## Orchestration Pattern

### RecoveryOrchestrator

The `RecoveryOrchestrator` coordinates all recovery workers and provides a unified interface for running recovery operations.

```typescript
import { RecoveryOrchestrator } from "./recovery/recovery-orchestrator.js";
import { QueueLock } from "./queue.lock.js";

const lock = new QueueLock(app.redis);
const orchestrator = new RecoveryOrchestrator(
  { enableAutoRecovery: true },
  app.redis,
  waitTimeEngine
);

// Start all workers
orchestrator.start();

// Run once for manual recovery
await orchestrator.runOnce();

// Get health stats
const stats = await orchestrator.getHealthStats();

// Stop all workers
orchestrator.stop();
```

## Worker Execution Order

Workers are executed in the following order to ensure proper dependency resolution:

1. **StaleServiceDetectorWorker** - First, detect stale services
2. **ChairRecoveryWorker** - Second, recover orphaned chairs
3. **QueueReconcilerWorker** - Third, reconcile queue entries
4. **WaitTimeRebuilderWorker** - Fourth, rebuild wait times
5. **RedisRepairWorker** - Fifth, repair Redis state
6. **DeadSocketCleanupWorker** - Last, clean up sockets

This order ensures:
- Chairs are recovered before queue reconciliation
- Queue state is consistent before wait time calculation
- Redis is repaired after DB is consistent
- Sockets are cleaned up after all state is consistent

## Distributed Locking

All workers use distributed locking to prevent concurrent execution:

```typescript
await lock.withLock(`shop:${shopId}:reconcile`, 30000, async () => {
  // Recovery logic here
});
```

**Lock Keys**:
- `shop:{shopId}:reconcile` - Queue reconciliation
- `shop:{shopId}:chair-recovery` - Chair recovery
- `shop:{shopId}:wait-time-rebuild` - Wait time rebuilding
- `shop:{shopId}:redis-repair` - Redis repair
- `socket:cleanup` - Socket cleanup

**Lock Timeout**: 30 seconds
**Lock Extension**: 15 seconds (for long-running operations)

## Idempotency

All workers are designed to be idempotent:
- Multiple executions produce the same result
- Detection queries are deterministic
- Recovery actions check current state before acting
- Database constraints prevent duplicate actions

## Cron Safety

Workers are cron-safe:
- Distributed locks prevent concurrent execution
- Lock acquisition fails gracefully
- Workers retry with exponential backoff
- No side effects from multiple executions

## Error Handling

Workers handle errors gracefully:
- Errors are logged but don't stop execution
- Continue processing other items
- Report statistics even on partial failure
- Lock is released even on error

## Monitoring

### Health Metrics

Each worker provides health metrics:
- Total items processed
- Items recovered
- Items flagged
- Events logged (by severity)
- Error rate

### Recovery Events

All recovery operations log events:
```typescript
{
  type: "CHAIR_RECOVERED" | "QUEUE_ENTRY_RECOVERED" | "REDIS_REBUILT" | ...,
  shopId: string,
  bookingId?: string,
  chairId?: string,
  severity: "INFO" | "WARNING" | "ERROR" | "CRITICAL",
  message: string,
  metadata: Record<string, unknown>,
  recoveredAt: Date
}
```

## Configuration

### Recovery Config

```typescript
{
  chairOrphanTimeoutHours: 2,
  serviceStaleTimeoutMinutes: 120,
  queueEntryStaleTimeoutHours: 24,
  redisRebuildThreshold: 5,
  positionStaleThreshold: 1000,
  waitTimeDiscrepancyThreshold: 10,
  socketStaleTimeoutMinutes: 30,
  enableAutoRecovery: true,
  enableAutoFlagging: true,
  enableRedisRebuild: true,
  enablePositionNormalization: true,
  enableWaitTimeRecalulation: true,
  enableSocketCleanup: true
}
```

## Manual Recovery

### Manual Shop Recovery

```typescript
// Reconcile a specific shop
await queueReconcilerWorker.reconcileShop(shopId);

// Recover chairs for a specific shop
await chairRecoveryWorker.recoverChair(chairId);

// Rebuild Redis for a specific shop
await redisRepairWorker.rebuildShopRedis(shopId, redis);

// Recalculate wait times for a specific shop
await waitTimeReconcilerWorker.recalculateShopWaitTimes(shopId, waitTimeEngine);
```

### Manual Socket Cleanup

```typescript
// Disconnect a specific socket
await deadSocketCleanupWorker.disconnectSocket(socketId, socketManager);

// Disconnect all sockets for a user
await deadSocketCleanupWorker.disconnectUserSockets(userId, socketManager);

// Disconnect all sockets for a shop
await deadSocketCleanupWorker.disconnectShopSockets(shopId, socketManager);
```

## Best Practices

### Production Deployment

1. **Stagger Worker Intervals**: Run workers at different intervals to prevent resource contention
2. **Monitor Lock Contention**: Track lock acquisition failures to identify bottlenecks
3. **Set Appropriate Timeouts**: Adjust timeouts based on your workload
4. **Enable Auto-Recovery**: Only enable auto-recovery after thorough testing
5. **Monitor Recovery Events**: Set up alerts for CRITICAL and ERROR events

### Testing

1. **Test Idempotency**: Run workers multiple times to ensure idempotency
2. **Test Lock Contention**: Simulate concurrent executions
3. **Test Error Handling**: Inject errors to test error handling
4. **Test Recovery Rules**: Verify all recovery rules work correctly
5. **Test Manual Recovery**: Verify manual recovery operations work

### Troubleshooting

1. **High Lock Contention**: Increase lock timeout or stagger worker intervals
2. **Many Recovery Events**: Investigate root cause of inconsistencies
3. **Slow Recovery**: Optimize queries or increase worker intervals
4. **Redis Rebuild Failures**: Check Redis connectivity and capacity
5. **Socket Cleanup Issues**: Verify socket manager integration

## Integration with Queue Container

Update the queue container to include the new worker:

```typescript
import { DeadSocketCleanupWorker } from "./recovery/dead-socket-cleanup.worker.js";

const deadSocketCleanupWorker = new DeadSocketCleanupWorker(
  lock,
  { enableSocketCleanup: true },
  5 * 60 * 1000
);

return {
  // ... existing services
  deadSocketCleanupWorker
};
```
