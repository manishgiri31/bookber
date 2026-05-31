# Production-Grade Queue Recovery and Reconciliation Engine

## Architecture Overview

The recovery engine consists of specialized workers that detect and heal inconsistencies across the queue system. Each worker is designed to be:

- **Cron-safe**: Can run multiple times without side effects
- **Idempotent**: Multiple executions produce the same result
- **Transaction-safe**: Uses proper database transactions
- **Distributed-lock safe**: Uses Redis locks to prevent concurrent execution

## Workers

### 1. QueueReconcilerWorker
**Purpose**: Detect and recover dead queue entries

**Detection Rules**:
- Booking cancelled/completed but queue entry remains
- Chair released but queue entry is IN_SERVICE
- Stale queue positions (> threshold)
- Very old WAITING entries (> timeout)

**Recovery Actions**:
- Remove dead queue entries
- Normalize stale positions
- Log recovery events

**Redis Lock**: `shop:{shopId}:reconcile`

### 2. ChairRecoveryWorker
**Purpose**: Detect and recover orphaned chairs

**Detection Rules**:
- OCCUPIED chair without active booking > timeout
- OCCUPIED chair with completed/cancelled booking
- OCCUPIED chair without allocation record

**Recovery Actions**:
- Release orphaned chairs
- Update chair status to AVAILABLE
- Close allocation records
- Log recovery events

**Redis Lock**: `shop:{shopId}:chair-recovery`

### 3. WaitTimeRebuilderWorker
**Purpose**: Detect and rebuild wait time inconsistencies

**Detection Rules**:
- Redis wait time vs DB wait time mismatch > threshold
- Missing Redis snapshots
- Stale Redis cache

**Recovery Actions**:
- Recalculate wait times from DB
- Rebuild Redis snapshots
- Sync Redis with PostgreSQL
- Log recovery events

**Redis Lock**: `shop:{shopId}:wait-time-rebuild`

### 4. RedisRepairWorker
**Purpose**: Detect and repair Redis state inconsistencies

**Detection Rules**:
- Redis queue length vs DB queue length mismatch
- Missing Redis queue entries
- Orphaned Redis entries
- Position mismatches

**Recovery Actions**:
- Rebuild Redis queues from DB
- Remove orphaned Redis entries
- Sync Redis with PostgreSQL
- Log recovery events

**Redis Lock**: `shop:{shopId}:redis-repair`

### 5. DeadSocketCleanupWorker (NEW)
**Purpose**: Detect and disconnect stale socket connections

**Detection Rules**:
- Socket inactive > timeout
- Socket without active booking
- Socket with completed/cancelled booking
- Socket heartbeat timeout

**Recovery Actions**:
- Disconnect stale sockets
- Emit disconnect events
- Log cleanup events

**Redis Lock**: `socket:cleanup`

## Redis Locking Strategy

### Lock Keys
- `shop:{shopId}:reconcile` - Queue reconciliation
- `shop:{shopId}:chair-recovery` - Chair recovery
- `shop:{shopId}:wait-time-rebuild` - Wait time rebuilding
- `shop:{shopId}:redis-repair` - Redis repair
- `socket:cleanup` - Socket cleanup

### Lock Configuration
- **Timeout**: 30 seconds
- **Extension Interval**: 15 seconds
- **Retry Delay**: 5 seconds
- **Max Retries**: 3

### Lock Usage Pattern
```typescript
await lock.withLock(`shop:${shopId}:reconcile`, 30000, async () => {
  // Recovery logic here
});
```

## Recovery Rules

### OCCUPIED Chair Without Booking > Timeout → Recover
```typescript
if (chair.status === "OCCUPIED" && !activeAllocation) {
  if (timeSinceServiceStart > chairOrphanTimeout) {
    await releaseChair(chairId);
  }
}
```

### IN_SERVICE Booking Without Heartbeat → Flag
```typescript
if (booking.status === "IN_SERVICE" && timeSinceStart > serviceStaleTimeout) {
  await flagStaleService(bookingId, "NO_HEARTBEAT");
}
```

### Redis Mismatch → Rebuild from DB
```typescript
if (redisQueueLength !== dbQueueLength) {
  await rebuildRedisQueue(shopId, lane);
}
```

### Stale Queue Positions → Normalize
```typescript
if (maxPosition > positionStaleThreshold) {
  await normalizePositions(shopId, lane);
}
```

### Stale Sockets → Disconnect
```typescript
if (socket.lastHeartbeat < staleThreshold) {
  await disconnectSocket(socketId);
}
```

## Idempotency Guarantees

### Detection Idempotency
- Workers use consistent queries with filters
- Detection results are deterministic
- No side effects during detection phase

### Recovery Idempotency
- Recovery actions check current state before acting
- Use database constraints to prevent duplicate actions
- Log events with unique identifiers

### Transaction Safety
- All recovery actions use database transactions
- Transactions use FOR UPDATE locks
- Rollback on error

## Cron Safety

### Concurrent Execution Prevention
- Redis locks prevent concurrent execution
- Lock acquisition fails gracefully
- Workers retry with exponential backoff

### Idempotent Execution
- Multiple executions produce same result
- No duplicate recovery actions
- No duplicate event logging

### Error Handling
- Workers catch and log errors
- Continue processing other items
- Report statistics even on partial failure

## Recovery Flows

### Queue Reconciliation Flow
1. Acquire Redis lock for shop
2. Detect dead queue entries
3. For each dead entry:
   - Check current booking status
   - Remove queue entry if booking is terminal
   - Log recovery event
4. Detect stale positions
5. Normalize if needed
6. Release lock
7. Return statistics

### Chair Recovery Flow
1. Acquire Redis lock for shop
2. Detect orphaned chairs
3. For each orphaned chair:
   - Check allocation status
   - Release chair if orphaned
   - Close allocation record
   - Log recovery event
4. Release lock
5. Return statistics

### Wait Time Rebuilding Flow
1. Acquire Redis lock for shop
2. Detect wait time mismatches
3. For each mismatched lane:
   - Recalculate wait times from DB
   - Rebuild Redis snapshots
   - Sync with PostgreSQL
   - Log recovery event
4. Release lock
5. Return statistics

### Redis Repair Flow
1. Acquire Redis lock for shop
2. Detect Redis mismatches
3. For each mismatched lane:
   - Rebuild Redis queue from DB
   - Remove orphaned entries
   - Sync with PostgreSQL
   - Log recovery event
4. Release lock
5. Return statistics

### Socket Cleanup Flow
1. Acquire Redis lock for socket cleanup
2. Detect stale sockets
3. For each stale socket:
   - Check heartbeat status
   - Disconnect socket
   - Emit disconnect event
   - Log cleanup event
4. Release lock
5. Return statistics

## Monitoring and Statistics

### Worker Statistics
Each worker returns:
- Total items processed
- Items recovered
- Items flagged
- Events logged (by severity)
- Error count

### Health Metrics
- Worker execution time
- Lock acquisition time
- Detection count
- Recovery count
- Error rate

## Configuration

### Recovery Config
```typescript
interface RecoveryConfig {
  serviceStaleTimeoutMinutes: number;      // Default: 60
  chairOrphanTimeoutHours: number;          // Default: 2
  queueEntryStaleTimeoutHours: number;      // Default: 4
  positionStaleThreshold: number;            // Default: 100000
  waitTimeDiscrepancyThreshold: number;     // Default: 5
  redisRebuildThreshold: number;            // Default: 3
  socketStaleTimeoutMinutes: number;        // Default: 30
  enableAutoFlagging: boolean;              // Default: true
  enableAutoRecovery: boolean;             // Default: true
  enablePositionNormalization: boolean;    // Default: true
  enableWaitTimeRecalculation: boolean;     // Default: true
  enableRedisRebuild: boolean;             // Default: true
}
```

## Implementation Notes

### Distributed Locking
Use QueueLock for all recovery operations:
```typescript
await lock.withLock(`shop:${shopId}:reconcile`, 30000, async () => {
  // Recovery logic
});
```

### Transaction Management
Use RecoveryTransactionManager for all recovery operations:
```typescript
await transactionManager.executeRecovery(
  () => recoveryLogic(),
  "EVENT_TYPE",
  shopId,
  "Description"
);
```

### Event Logging
All recovery operations must log events:
```typescript
await transactionManager.createQueueEvent(tx, {
  shopId,
  bookingId,
  type: "RECOVERY_EVENT",
  payload: { details }
});
```

### Error Handling
Workers must handle errors gracefully:
```typescript
try {
  await recoveryLogic();
} catch (error) {
  console.error("Recovery failed:", error);
  // Continue processing other items
}
```
