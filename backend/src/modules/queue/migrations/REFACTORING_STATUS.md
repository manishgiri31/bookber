# Queue State Architecture Refactoring - Current Status

## Completed Tasks

1. ✅ Analyzed current Prisma schema for Booking and ActiveQueue models
2. ✅ Designed new QueueEntry model structure
3. ✅ Updated Prisma schema with new QueueEntry model
4. ✅ Created migration strategy for existing data
5. ✅ Created migration script (migrate-to-queue-entry.ts)
6. 🔄 Update repository to use QueueEntry instead of ActiveQueue (IN PROGRESS)

## Schema Changes

### Booking Model (Historical Entity)
**Removed fields:**
- `queuePosition` → moved to QueueEntry
- `estimatedWaitMinutes` → moved to QueueEntry
- `queueStatus` → moved to QueueEntry
- `queueLane` → moved to QueueEntry
- `estimatedServiceStart` → moved to QueueEntry
- `estimatedServiceEnd` → moved to QueueEntry
- `activeServiceStart` → moved to QueueEntry
- `activeServiceEnd` → moved to QueueEntry

**Kept fields:**
- `chairId` (historical record of chair used)
- `status` (booking lifecycle status)
- `cancellationReason`, `cancelledAt`, `noShowAt` (booking lifecycle)
- `walkIn`, `notes` (booking metadata)
- All relations (user, shop, barber, service, chair, payment, queueEntry, queueEvents, chairAllocations)

### QueueEntry Model (Realtime Operational State)
**Renamed from:** `ActiveQueue` → `QueueEntry`

**Fields:**
- `id`, `shopId`, `bookingId`, `barberId`
- `chairId` (current chair assignment - NEW)
- `lane`, `position`, `queueStatus`
- `estimatedWaitMinutes`, `estimatedServiceStart`
- `version` (optimistic locking)
- `createdAt`, `updatedAt`

**Relations:**
- `shop` (Shop)
- `booking` (Booking)
- `barber` (Barber)
- `chair` (Chair - NEW)

## Repository Changes

### Updated Methods
- ✅ `lockActiveQueue` → `lockQueueEntry`
- ✅ `findBooking` - changed `activeQueue` include to `queueEntry`
- ✅ `listActiveQueueEntries` → `listQueueEntries` (with legacy wrapper)
- ✅ Added legacy method for backward compatibility

### Pending Repository Updates
- Update all callers of `listActiveQueueEntries` to use `listQueueEntries`
- Update all callers of `lockActiveQueue` to use `lockQueueEntry`

## Service Changes

### Services to Update
- QueueReservationService
- QueuePositionService
- ChairAllocationService
- WaitTimeService
- QueueRealtimeService
- QueueRecoveryService

### Expected Changes
- Replace `activeQueue` references with `queueEntry`
- Update queue state queries to use QueueEntry
- Update Redis operations to use QueueEntry
- Update socket emissions to use QueueEntry

## Redis Changes

### Stores to Update
- QueueRedisStore
- WaitTimeRedisStore

### Expected Changes
- Update sorted set keys to use QueueEntry data
- Update snapshot structures to use QueueEntry
- Update wait time calculations to use QueueEntry

## Socket Changes

### Emitters to Update
- QueueRealtimeEmitter

### Expected Changes
- Update event payloads to use QueueEntry
- Update snapshot structures to use QueueEntry

## Migration Steps

### Step 1: Apply Prisma Migration
```bash
npx prisma migrate dev --name refactor_queue_state
```

This will:
- Create QueueEntry table
- Remove queue-related fields from Booking
- Drop ActiveQueue table
- Regenerate Prisma client with new types

### Step 2: Run Data Migration
```bash
npx ts-node src/modules/queue/migrations/migrate-to-queue-entry.ts migrate
```

This will:
- Migrate data from ActiveQueue to QueueEntry
- Verify data integrity

### Step 3: Update Services
- Update all services to use QueueEntry instead of ActiveQueue
- Update Redis stores
- Update socket emitters

### Step 4: Verify Migration
```bash
npx ts-node src/modules/queue/migrations/migrate-to-queue-entry.ts verify
```

This will:
- Verify QueueEntry table exists
- Verify ActiveQueue table was dropped
- Verify Booking queue fields were removed

### Step 5: Cleanup
- Remove legacy method `listActiveQueueEntries` from repository
- Remove legacy method `lockActiveQueue` from repository
- Update all callers to use new methods

## Current Lint Errors

The lint errors are expected because:
1. Prisma schema changes haven't been applied yet
2. Prisma client hasn't been regenerated with new types
3. Services are still using old Booking structure

These errors will be resolved after:
1. Prisma migration is applied
2. Prisma client is regenerated
3. Services are updated to use QueueEntry

## Next Steps

1. Apply Prisma migration to regenerate types
2. Update remaining service code to use QueueEntry
3. Update Redis stores
4. Update socket emitters
5. Test migration
6. Cleanup legacy code
