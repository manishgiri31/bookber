# Queue Service Architecture

## Overview

The QueueEngineService has been refactored into isolated, focused services to improve maintainability, testability, and separation of concerns.

## Service Boundaries

### 1. QueueReservationService
**Responsibilities:**
- Queue reservation (enqueue)
- Check-in
- Service start
- Service completion
- No-show marking
- Booking cancellation

**Transaction Ownership:** Owns booking and active queue transactions
**Redis Ownership:** Delegates to other services
**Event Ownership:** Delegates to QueueRealtimeService

**Dependencies:**
- PrismaQueueRepository
- QueueLock

### 2. QueuePositionService
**Responsibilities:**
- Position allocation (sparse positioning)
- Queue compaction (sparse positioning)
- Lane normalization
- Lane rebalancing
- Snapshot building

**Transaction Ownership:** Owns position-related transactions
**Redis Ownership:** Delegates to other services
**Event Ownership:** Delegates to QueueRealtimeService

**Dependencies:**
- PrismaQueueRepository
- QueueLock

### 3. ChairAllocationService
**Responsibilities:**
- Find available chairs
- Allocate chairs to bookings
- Release chairs from bookings
- Try assign next booking to available chair
- Force release chair (emergency recovery)

**Transaction Ownership:** Owns chair allocation transactions
**Redis Ownership:** Delegates to other services
**Event Ownership:** Delegates to QueueRealtimeService

**Dependencies:**
- PrismaQueueRepository
- ChairAllocator
- QueueLock

### 4. WaitTimeService
**Responsibilities:**
- Recalculate lane wait times
- Sync booking snapshots to Redis
- Record service overruns
- Record service samples
- Apply wait time estimates to database

**Transaction Ownership:** Owns wait time transactions
**Redis Ownership:** Owns Redis wait time operations
**Event Ownership:** Delegates to QueueRealtimeService

**Dependencies:**
- PrismaQueueRepository
- WaitTimeEngine

### 5. QueueRealtimeService
**Responsibilities:**
- Emit queue updated events
- Emit position changed events
- Emit booking lifecycle events (created, called, in service, completed)
- Emit chair updated events
- Emit wait time updated events

**Transaction Ownership:** None (events only)
**Redis Ownership:** None (delegates to QueueRealtimeEmitter)
**Event Ownership:** Owns all event emission

**Dependencies:**
- QueueRealtimeEmitter

### 6. QueueRecoveryService
**Responsibilities:**
- Coordinate recovery workers
- Detect and recover inconsistent queue states
- Log recovery events
- Provide recovery statistics

**Transaction Ownership:** Owns recovery transactions
**Redis Ownership:** Owns Redis repair operations
**Event Ownership:** Owns recovery event logging

**Dependencies:**
- RecoveryOrchestrator
- RecoveryEventLogger

## Dependency Graph

```
QueueReservationService
├── PrismaQueueRepository
└── QueueLock

QueuePositionService
├── PrismaQueueRepository
└── QueueLock

ChairAllocationService
├── PrismaQueueRepository
├── ChairAllocator
└── QueueLock

WaitTimeService
├── PrismaQueueRepository
└── WaitTimeEngine

QueueRealtimeService
└── QueueRealtimeEmitter

QueueRecoveryService
├── RecoveryOrchestrator
│   ├── StaleServiceDetectorWorker
│   ├── ChairRecoveryWorker
│   ├── QueueReconcilerWorker
│   ├── WaitTimeReconcilerWorker
│   └── RedisRepairService
└── RecoveryEventLogger
```

## Transaction Ownership

Each service owns its specific transaction boundaries:

- **QueueReservationService**: Booking lifecycle transactions
- **QueuePositionService**: Position allocation and normalization transactions
- **ChairAllocationService**: Chair assignment and release transactions
- **WaitTimeService**: Wait time calculation transactions
- **QueueRealtimeService**: No transactions (events only)
- **QueueRecoveryService**: Recovery and reconciliation transactions

## Event Ownership

Events are emitted by the appropriate service:

- **QueueRealtimeService**: All realtime events (queue updates, position changes, booking lifecycle, chair updates, wait time updates)
- **QueueRecoveryService**: Recovery events (logged via RecoveryEventLogger)

## Redis Ownership

Redis operations are owned by the appropriate service:

- **WaitTimeService**: Wait time Redis operations
- **QueueRecoveryService**: Redis repair operations
- Other services delegate Redis operations to specialized services

## Migration Strategy

### Phase 1: Integration
1. New services created in `application/services/` directory
2. Queue container updated to wire up all services
3. Existing QueueEngineService remains functional

### Phase 2: Gradual Migration
1. Update QueueCoordinator to use new services
2. Update route handlers to use new services
3. Keep QueueEngineService as facade during transition

### Phase 3: Cleanup
1. Remove QueueEngineService once all consumers migrated
2. Remove unused dependencies
3. Update tests to use new services

## Service Communication

Services communicate through dependency injection, not direct calls:

```typescript
// Example: QueueCoordinator using multiple services
class QueueCoordinator {
  constructor(
    private readonly queueReservation: QueueReservationService,
    private readonly queuePosition: QueuePositionService,
    private readonly chairAllocation: ChairAllocationService,
    private readonly waitTime: WaitTimeService,
    private readonly realtime: QueueRealtimeService
  ) {}
}
```

## Benefits

1. **Separation of Concerns**: Each service has a single, well-defined responsibility
2. **Testability**: Services can be tested in isolation with mocked dependencies
3. **Maintainability**: Changes to one service don't affect others
4. **Scalability**: Services can be scaled independently if needed
5. **Dependency Injection**: Easy to swap implementations for testing
6. **Clear Boundaries**: Transaction, Redis, and event ownership is explicit

## File Structure

```
src/modules/queue/
├── application/
│   ├── services/
│   │   ├── queue-reservation.service.ts
│   │   ├── queue-position.service.ts
│   │   ├── chair-allocation.service.ts
│   │   ├── wait-time.service.ts
│   │   ├── queue-realtime.service.ts
│   │   └── queue-recovery.service.ts
│   ├── queue-engine.service.ts (legacy, to be removed)
│   ├── queue-coordinator.service.ts
│   └── ...
├── infrastructure/
│   └── queue.repository.ts
├── recovery/
│   └── ...
└── queue.container.ts
```

## Next Steps

1. Update QueueCoordinator to use new services
2. Update route handlers to use new services
3. Add integration tests for new services
4. Remove legacy QueueEngineService
5. Update documentation
