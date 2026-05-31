# Queue State Architecture Refactoring

## Current Issue

Queue state is duplicated between:
- **Booking**: Contains queue position, wait time, queue status, lane, timing data
- **ActiveQueue**: Contains position, wait time, queue status, lane, timing data

This creates inconsistency risk and violates single source of truth principle.

## New Architecture

### Booking (Historical Entity)
**Purpose**: Store booking history, service data, payment data, audit data

**Fields to Keep**:
- `userId`, `shopId`, `barberId`, `serviceId`, `chairId` (historical record)
- `status`, `cancellationReason`, `cancelledAt`, `noShowAt` (booking lifecycle)
- `walkIn`, `notes` (booking metadata)
- `createdAt`, `updatedAt` (audit timestamps)
- `payment` relation (payment data)

**Fields to Remove**:
- `queuePosition`, `estimatedWaitMinutes`, `queueStatus`, `queueLane` (move to QueueEntry)
- `estimatedServiceStart`, `estimatedServiceEnd`, `activeServiceStart`, `activeServiceEnd` (move to QueueEntry)

### QueueEntry (Realtime Operational State)
**Purpose**: Single source of truth for queue state

**Fields**:
- `id`, `shopId`, `bookingId`, `barberId`
- `lane`, `position`, `queueStatus`
- `estimatedWaitMinutes`, `estimatedServiceStart`
- `chairId` (current chair assignment)
- `version` (optimistic locking)
- `createdAt`, `updatedAt`

**Renamed from**: `ActiveQueue` → `QueueEntry`

## Migration Strategy

### Phase 1: Schema Changes
1. Create new `QueueEntry` model
2. Add migration to create table
3. Keep `ActiveQueue` for now (will be renamed later)

### Phase 2: Data Migration
1. Migrate data from `ActiveQueue` to `QueueEntry`
2. Remove queue fields from `Booking` (keep historical data in separate columns if needed)
3. Update all foreign key references

### Phase 3: Code Updates
1. Update repository to use `QueueEntry` instead of `ActiveQueue`
2. Update services to use `QueueEntry`
3. Update Redis stores
4. Update socket emission
5. Update type definitions

### Phase 4: Cleanup
1. Drop `ActiveQueue` table
2. Drop queue-related columns from `Booking`
3. Update indexes

## Transactional Consistency

All operations must use transactions to ensure consistency:
- When creating booking: Create Booking + QueueEntry in same transaction
- When updating queue state: Update QueueEntry only
- When completing booking: Update Booking status + delete QueueEntry in same transaction

## Redis Operational Caching

Redis will cache QueueEntry data for fast access:
- Queue sorted sets use QueueEntry.position
- Wait time calculations use QueueEntry.estimatedWaitMinutes
- Chair assignments use QueueEntry.chairId

## Minimal Duplication

Only historical data is duplicated:
- Booking.chairId = historical record of which chair was used
- QueueEntry.chairId = current chair assignment
- This is acceptable for audit purposes

## Migration Script

The migration script will:
1. Create QueueEntry table
2. Copy data from ActiveQueue to QueueEntry
3. Update Booking to remove queue fields (keep in separate columns for rollback)
4. Verify data integrity
5. Provide rollback option
