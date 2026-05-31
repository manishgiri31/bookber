# BookBer Flow Diagrams

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Client Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │   Web App    │  │  Mobile App  │  │  Admin Panel │           │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘           │
│         │                  │                  │                   │
└─────────┼──────────────────┼──────────────────┼───────────────────┘
          │                  │                  │
          └──────────────────┴──────────────────┘
                            │ HTTP/WebSocket
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API Gateway (Fastify)                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │   Routes     │  │ Middleware   │  │ Validation  │           │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘           │
└─────────┼──────────────────┼──────────────────┼───────────────────┘
          │                  │                  │
          └──────────────────┴──────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Application Services                            │
│  ┌──────────────────┐  ┌──────────────────┐                     │
│  │ QueueReservation │  │  QueuePosition   │                     │
│  │     Service      │  │     Service      │                     │
│  └────────┬─────────┘  └────────┬─────────┘                     │
│           │                     │                                 │
│  ┌────────▼─────────┐  ┌───────▼──────────┐                     │
│  │ ChairAllocation  │  │   WaitTime       │                     │
│  │    Service       │  │    Service       │                     │
│  └────────┬─────────┘  └────────┬─────────┘                     │
│           │                     │                                 │
│  ┌────────▼─────────────────────▼──────────┐                    │
│  │         QueueRealtime Service            │                    │
│  └──────────────────┬──────────────────────┘                    │
│                     │                                             │
│  ┌──────────────────▼──────────────────────┐                    │
│  │         QueueRecovery Service             │                    │
│  │  ┌────────┬────────┬────────┬────────┐   │                    │
│  │  │ Stale  │ Chair  │ Queue  │ Wait  │   │                    │
│  │  │ Detect│Recovery│Reconciler│Time │   │                    │
│  │  └────────┴────────┴────────┴────────┘   │                    │
│  └──────────────────────────────────────────┘                    │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Infrastructure Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ PostgreSQL    │  │    Redis     │  │  Socket.IO   │           │
│  │   (Primary)   │  │  (Single)    │  │   Server     │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

## Queue Reservation Flow

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │ POST /api/queue/reserve
       │ { shopId, serviceId, userId, walkIn }
       ▼
┌─────────────────────────────────────┐
│ QueueReservationService.reserveQueue │
└──────┬──────────────────────────────┘
       │
       │ 1. Validate user permissions
       ▼
┌─────────────────────────────────────┐
│ Check: walkIn && CLIENT && userId != │
│ input.userId → Forbidden            │
└──────┬──────────────────────────────┘
       │
       │ 2. Acquire distributed lock
       ▼
┌─────────────────────────────────────┐
│ QueueLock.withLock(                 │
│   `shop:{shopId}:reserve`, 8000ms   │
│ )                                   │
│ ├─ Generate UUID token              │
│ ├─ SET key token PX 10000ms NX      │
│ └─ Set up lock extension timer      │
└──────┬──────────────────────────────┘
       │
       │ 3. Begin database transaction
       ▼
┌─────────────────────────────────────┐
│ prisma.$transaction(                │
│   Serializable,                     │
│   maxWait: 8000ms,                 │
│   timeout: 15000ms                 │
│ )                                   │
└──────┬──────────────────────────────┘
       │
       │ 4. Lock shop row
       ▼
┌─────────────────────────────────────┐
│ repository.lockShop(tx, shopId)    │
│ SELECT id FROM "Shop"               │
│ WHERE id = shopId FOR UPDATE        │
└──────┬──────────────────────────────┘
       │
       │ 5. Validate shop status
       ▼
┌─────────────────────────────────────┐
│ repository.findShopById(tx, shopId)│
│ ├─ Check: isActive = true          │
│ ├─ Check: isAcceptingBookings = true│
│ └─ Check: walkIn → isAcceptingWalkIns│
└──────┬──────────────────────────────┘
       │
       │ 6. Validate service
       ▼
┌─────────────────────────────────────┐
│ repository.findService(tx, serviceId)│
│ ├─ Check: service exists            │
│ ├─ Check: service.shopId = shopId   │
│ └─ Check: service.isActive = true   │
└──────┬──────────────────────────────┘
       │
       │ 7. Validate barber (if specified)
       ▼
┌─────────────────────────────────────┐
│ shop.barbers.find(b => b.id = barberId)│
└──────┬──────────────────────────────┘
       │
       │ 8. Allocate position
       ▼
┌─────────────────────────────────────┐
│ repository.nextQueuePosition(       │
│   tx, shopId, lane                  │
│ )                                   │
│ ├─ SparsePositionAllocator          │
│ ├─ Calculate sparse position        │
│ └─ Return: position, needsRebalance,│
│           needsNormalization         │
└──────┬──────────────────────────────┘
       │
       │ 9. Create booking
       ▼
┌─────────────────────────────────────┐
│ tx.booking.create({                 │
│   userId, shopId, barberId,         │
│   serviceId, status: "QUEUED",       │
│   queueStatus: "WAITING",           │
│   queueLane: lane,                  │
│   queuePosition: position,          │
│   estimatedWaitMinutes: 0,          │
│   arrivalWindowStart,               │
│   arrivalWindowEnd,                 │
│   estimatedServiceStart,            │
│   estimatedServiceEnd,              │
│   walkIn                            │
│ })                                  │
└──────┬──────────────────────────────┘
       │
       │ 10. Create active queue entry
       ▼
┌─────────────────────────────────────┐
│ tx.activeQueue.create({             │
│   shopId, bookingId, barberId,      │
│   lane, position,                   │
│   queueStatus: "WAITING",          │
│   estimatedWaitMinutes: 0,          │
│   estimatedServiceStart             │
│ })                                  │
└──────┬──────────────────────────────┘
       │
       │ 11. Create queue event
       ▼
┌─────────────────────────────────────┐
│ repository.createQueueEvent(tx, {   │
│   shopId, bookingId,                │
│   type: "ENQUEUED",                 │
│   payload: { lane, position }       │
│ })                                  │
└──────┬──────────────────────────────┘
       │
       │ 12. Refresh booking
       ▼
┌─────────────────────────────────────┐
│ tx.booking.findUnique({             │
│   where: { id: booking.id }        │
│ })                                  │
└──────┬──────────────────────────────┘
       │
       │ 13. Commit transaction
       ▼
┌─────────────────────────────────────┐
│ Transaction committed               │
└──────┬──────────────────────────────┘
       │
       │ 14. Release lock
       ▼
┌─────────────────────────────────────┐
│ QueueLock release                   │
│ ├─ Clear extension timer             │
│ ├─ GET key                          │
│ ├─ Check: value == token            │
│ └─ DEL key                          │
└──────┬──────────────────────────────┘
       │
       │ 15. Emit realtime event
       ▼
┌─────────────────────────────────────┐
│ QueueRealtimeService                │
│   .emitBookingCreated(booking)     │
│ └─ SocketEventPublisher            │
│     └─ emit to shop/user/barber rooms│
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────┐
│   Client    │
│ (Response)  │
└─────────────┘
```

## Chair Assignment Flow (with Race Condition)

```
┌─────────────┐
│ Service     │
│ Completion   │
└──────┬──────┘
       │
       │ 1. Trigger chair assignment
       ▼
┌─────────────────────────────────────┐
│ ChairAllocationService.tryAssignNext│
│ (shopId, lane)                      │
└──────┬──────────────────────────────┘
       │
       │ 2. Acquire distributed lock
       ▼
┌─────────────────────────────────────┐
│ QueueLock.withLock(                 │
│   `shop:{shopId}:assign`, 5000ms    │
│ )                                   │
└──────┬──────────────────────────────┘
       │
       │ 3. Begin database transaction
       ▼
┌─────────────────────────────────────┐
│ prisma.$transaction(                │
│   Serializable,                     │
│   maxWait: 5000ms,                 │
│   timeout: 10000ms                 │
│ )                                   │
└──────┬──────────────────────────────┘
       │
       │ 4. Lock shop row
       ▼
┌─────────────────────────────────────┐
│ repository.lockShop(tx, shopId)    │
│ SELECT id FROM "Shop"               │
│ WHERE id = shopId FOR UPDATE        │
└──────┬──────────────────────────────┘
       │
       │ 5. Find available chair
       ▼
┌─────────────────────────────────────┐
│ chairAllocator.findAvailableChair(  │
│   tx, shopId, lane                 │
│ )                                   │
│ SELECT * FROM "Chair"              │
│ WHERE shopId = shopId              │
│   AND status = 'AVAILABLE'         │
│   AND reservedForBookBer = lane    │
│ ORDER BY number ASC                 │
│ LIMIT 1                            │
└──────┬──────────────────────────────┘
       │
       │ 6. Check if chair found
       ▼
┌─────────────────────────────────────┐
│ if (!chair) return;                │
└──────┬──────────────────────────────┘
       │
       │ 7. Find next booking
       ▼
┌─────────────────────────────────────┐
│ tx.activeQueue.findFirst({         │
│   where: {                         │
│     shopId, lane,                  │
│     queueStatus: { in: ["WAITING", │
│       "READY"] },                  │
│     booking: { status: { in:       │
│       ["QUEUED", "READY"] } }      │
│   },                               │
│   include: { booking: true },       │
│   orderBy: { position: "asc" }     │
│ })                                  │
└──────┬──────────────────────────────┘
       │
       │ 8. Check if booking found
       ▼
┌─────────────────────────────────────┐
│ if (!next) return;                 │
└──────┬──────────────────────────────┘
       │
       │ 9. Check arrival window
       ▼
┌─────────────────────────────────────┐
│ if (next.booking.queueStatus ===   │
│     "WAITING" &&                   │
│     now > next.booking.            │
│     arrivalWindowEnd) return;      │
└──────┬──────────────────────────────┘
       │
       │ 10. ⚠️ RACE CONDITION ⚠️
       │     Chair not locked before allocation
       ▼
┌─────────────────────────────────────┐
│ chairAllocator.allocateToBooking(  │
│   tx, { shopId, chair, bookingId,  │
│         lane, startNow: true }     │
│ )                                   │
│ ├─ Create ChairAllocation          │
│ ├─ Update Chair status = OCCUPIED  │
│ └─ Update Chair activeServiceStart │
└──────┬──────────────────────────────┘
       │
       │ ⚠️ ISSUE: Another transaction could
       │     have assigned this chair to a
       │     different booking between step 5
       │     and step 10
       │
       │ 11. Update booking
       ▼
┌─────────────────────────────────────┐
│ tx.booking.update({                 │
│   where: { id: next.bookingId },   │
│   data: {                          │
│     chairId: chair.id,             │
│     status: "CALLED",              │
│     queueStatus: "CALLED",         │
│     activeServiceStart: now         │
│   }                                │
│ })                                  │
└──────┬──────────────────────────────┘
       │
       │ 12. Update active queue
       ▼
┌─────────────────────────────────────┐
│ tx.activeQueue.update({             │
│   where: { id: next.id },          │
│   data: {                          │
│     queueStatus: "CALLED",         │
│     version: { increment: 1 }      │
│   }                                │
│ })                                  │
└──────┬──────────────────────────────┘
       │
       │ 13. Create queue event
       ▼
┌─────────────────────────────────────┐
│ repository.createQueueEvent(tx, {   │
│   shopId,                          │
│   bookingId: next.bookingId,       │
│   type: "CHAIR_ASSIGNED",          │
│   payload: { chairId: chair.id }    │
│ })                                  │
└──────┬──────────────────────────────┘
       │
       │ 14. Commit transaction
       ▼
┌─────────────────────────────────────┐
│ Transaction committed               │
└──────┬──────────────────────────────┘
       │
       │ 15. Release lock
       ▼
┌─────────────────────────────────────┐
│ QueueLock release                   │
└──────┬──────────────────────────────┘
       │
       │ 16. Emit realtime event
       ▼
┌─────────────────────────────────────┐
│ QueueRealtimeService                │
│   .emitBookingCalled(...)          │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────┐
│   Client    │
└─────────────┘
```

## Recovery Orchestrator Flow

```
┌─────────────────────────────────────┐
│ RecoveryOrchestrator.runOnce()      │
└──────┬──────────────────────────────┘
       │
       │ 1. Initialize aggregate stats
       ▼
┌─────────────────────────────────────┐
│ aggregateStats = {                  │
│   chairsRecovered: 0,              │
│   servicesFlagged: 0,              │
│   queueEntriesRecovered: 0,        │
│   redisRebuilt: 0,                 │
│   positionsNormalized: 0,          │
│   waitTimesRecalculated: 0,         │
│   socketsDisconnected: 0,           │
│   totalEvents: 0,                   │
│   criticalEvents: 0,                │
│   errorEvents: 0,                  │
│   warningEvents: 0,                │
│   infoEvents: 0                    │
│ }                                   │
└──────┬──────────────────────────────┘
       │
       │ 2. Run StaleServiceDetectorWorker
       ▼
┌─────────────────────────────────────┐
│ staleServiceDetectorWorker.run()    │
│ ├─ Detect stale services            │
│ │  ├─ Find IN_SERVICE bookings      │
│ │  │  where activeServiceStart <    │
│ │  │        timeoutThreshold        │
│ │  ├─ Check chair status            │
│ │  └─ Categorize reason             │
│ ├─ Flag stale services              │
│ │  └─ Update booking status         │
│ ├─ Recover stale services           │
│ │  └─ Complete booking if chair     │
│ │       released                    │
│ └─ Aggregate stats                  │
└──────┬──────────────────────────────┘
       │
       │ 3. Run ChairRecoveryWorker
       ▼
┌─────────────────────────────────────┐
│ chairRecoveryWorker.run()           │
│ ├─ Detect orphaned chairs           │
│ │  ├─ Find chairs OCCUPIED          │
│ │  │  where no active allocation    │
│ │  └─ Find chairs with stale        │
│ │       allocations                 │
│ ├─ Release orphaned chairs         │
│ │  └─ Set chair status AVAILABLE    │
│ └─ Aggregate stats                  │
└──────┬──────────────────────────────┘
       │
       │ 4. Run QueueReconcilerWorker
       ▼
┌─────────────────────────────────────┐
│ queueReconcilerWorker.run()         │
│ ├─ Detect dead queue entries        │
│ │  ├─ Find ActiveQueue entries       │
│ │  │  where Booking status !=       │
│ │  │        ActiveQueue status      │
│ │  └─ Find orphaned ActiveQueue     │
│ │       entries                     │
│ ├─ Remove dead entries             │
│ │  └─ Delete ActiveQueue entries    │
│ ├─ Normalize positions             │
│ │  └─ Call normalizeLane()          │
│ └─ Aggregate stats                  │
└──────┬──────────────────────────────┘
       │
       │ 5. Run WaitTimeReconcilerWorker
       ▼
┌─────────────────────────────────────┐
│ waitTimeReconcilerWorker.run(       │
│   redis, waitTimeEngine             │
│ )                                   │
│ ├─ Detect wait time mismatches      │
│ │  ├─ Compare DB wait times         │
│ │  │  with Redis wait times         │
│ │  └─ Calculate discrepancies       │
│ ├─ Recalculate wait times          │
│ │  └─ Call waitTime.recalculateLane()│
│ └─ Aggregate stats                  │
└──────┬──────────────────────────────┘
       │
       │ 6. Run RedisRepairService
       ▼
┌─────────────────────────────────────┐
│ redisRepairService.run(redis)       │
│ ├─ Detect Redis mismatches          │
│ │  ├─ Compare DB queues             │
│ │  │  with Redis queues             │
│ │  └─ Identify missing/extra        │
│ │       entries                     │
│ ├─ Rebuild Redis queues            │
│ │  └─ Sync DB state to Redis       │
│ └─ Aggregate stats                  │
└──────┬──────────────────────────────┘
       │
       │ 7. Run DeadSocketCleanupWorker
       ▼
┌─────────────────────────────────────┐
│ deadSocketCleanupWorker.run(        │
│   socketManager                     │
│ )                                   │
│ ├─ Detect stale sockets            │
│ │  ├─ Find sockets inactive         │
│ │  │  for timeout period            │
│ │  └─ Categorize disconnection      │
│ │       reason                      │
│ ├─ Disconnect stale sockets        │
│ │  └─ Call socket.disconnect()      │
│ └─ Aggregate stats                  │
└──────┬──────────────────────────────┘
       │
       │ 8. Return aggregate stats
       ▼
┌─────────────────────────────────────┐
│ Return aggregateStats              │
└─────────────────────────────────────┘
```

## Sparse Position Allocation Flow

```
┌─────────────────────────────────────┐
│ SparsePositionAllocator             │
│ .allocatePosition(                  │
│   db, shopId, lane,                 │
│   insertAfterPosition               │
│ )                                   │
└──────┬──────────────────────────────┘
       │
       │ 1. Fetch active queue entries
       ▼
┌─────────────────────────────────────┐
│ db.activeQueue.findMany({           │
│   where: {                         │
│     shopId, lane,                  │
│     queueStatus: { in:             │
│       ["WAITING", "READY",          │
│        "CALLED", "IN_SERVICE"]      │
│     }                              │
│   },                               │
│   orderBy: { position: "asc" },    │
│   select: { position: true }       │
│ })                                  │
└──────┬──────────────────────────────┘
       │
       │ 2. Check if queue is empty
       ▼
┌─────────────────────────────────────┐
│ if (activeQueue.length === 0) {    │
│   return {                          │
│     position: 100,                 │
│     needsRebalance: false,          │
│     needsNormalization: false       │
│   };                               │
│ }                                   │
└──────┬──────────────────────────────┘
       │
       │ 3. Check if inserting at end
       ▼
┌─────────────────────────────────────┐
│ if (insertAfterPosition === null) {│
│   const maxPosition =               │
│     activeQueue[activeQueue.length  │
│       - 1].position;                │
│   const newPosition =               │
│     maxPosition + 100;             │
│   return {                          │
│     position: newPosition,         │
│     needsRebalance: false,         │
│     needsNormalization:             │
│       newPosition > 1000           │
│   };                               │
│ }                                   │
└──────┬──────────────────────────────┘
       │
       │ 4. Find insert position index
       ▼
┌─────────────────────────────────────┐
│ const insertIndex =                 │
│   activeQueue.findIndex(            │
│     entry => entry.position ===      │
│       insertAfterPosition           │
│   );                                │
└──────┬──────────────────────────────┘
       │
       │ 5. Check if inserting after last
       ▼
┌─────────────────────────────────────┐
│ if (insertIndex ===                 │
│     activeQueue.length - 1) {      │
│   const maxPosition =               │
│     activeQueue[activeQueue.length  │
│       - 1].position;                │
│   const newPosition =               │
│     maxPosition + 100;             │
│   return {                          │
│     position: newPosition,         │
│     needsRebalance: false,         │
│     needsNormalization:             │
│       newPosition > 1000           │
│   };                               │
│ }                                   │
└──────┬──────────────────────────────┘
       │
       │ 6. ⚠️ POTENTIAL RACE CONDITION ⚠️
       │     Calculate position between two
       │     existing positions
       ▼
┌─────────────────────────────────────┐
│ const prevPosition =                │
│   activeQueue[insertIndex].position;│
│ const nextPosition =                │
│   activeQueue[insertIndex + 1]      │
│     .position;                      │
│ const gap = nextPosition -          │
│   prevPosition;                    │
│ const newPosition = prevPosition +  │
│   Math.floor(gap / 2);              │
│                                     │
│ ⚠️ ISSUE: If two concurrent         │
│ insertions happen between the       │
│ same positions, they could          │
│ calculate the same newPosition      │
└──────┬──────────────────────────────┘
       │
       │ 7. Check if gap too small
       ▼
┌─────────────────────────────────────┐
│ const needsRebalance =              │
│   gap < 10;                         │
│ const needsNormalization =           │
│   newPosition > 1000;              │
└──────┬──────────────────────────────┘
       │
       │ 8. Return result
       ▼
┌─────────────────────────────────────┐
│ return {                            │
│   position: newPosition,           │
│   needsRebalance,                  │
│   needsNormalization               │
│ };                                 │
└─────────────────────────────────────┘
```

## Realtime Event Publishing Flow

```
┌─────────────────────────────────────┐
│ QueueRealtimeService               │
│ .emitBookingCreated(booking)       │
└──────┬──────────────────────────────┘
       │
       │ 1. Get publisher
       ▼
┌─────────────────────────────────────┐
│ QueueRealtimeEmitter                │
│ .emitBookingCreated(booking)       │
│ └─ publisher = getPublisher()      │
└──────┬──────────────────────────────┘
       │
       │ 2. Check if publisher available
       ▼
┌─────────────────────────────────────┐
│ if (!publisher) return;            │
└──────┬──────────────────────────────┘
       │
       │ 3. Publish event
       ▼
┌─────────────────────────────────────┐
│ SocketEventPublisher.publish(       │
│   BOOKING_CREATED, payload,         │
│   { userId, barberId }              │
│ )                                   │
└──────┬──────────────────────────────┘
       │
       │ 4. Get shop sequence number
       ▼
┌─────────────────────────────────────┐
│ seq = journal.nextShopSeq(shopId)   │
│ ⚠️ ISSUE: No guarantee of monotonic  │
│ sequence across failures           │
└──────┬──────────────────────────────┘
       │
       │ 5. Create envelope
       ▼
┌─────────────────────────────────────┐
│ envelope = {                        │
│   seq,                              │
│   eventId: `${shopId}:${seq}`,      │
│   event: BOOKING_CREATED,           │
│   payload,                          │
│   shopId,                           │
│   emittedAt: now                    │
│ }                                   │
└──────┬──────────────────────────────┘
       │
       │ 6. Append to journal
       ▼
┌─────────────────────────────────────┐
│ journal.appendShopEvent(shopId,     │
│   envelope)                         │
└──────┬──────────────────────────────┘
       │
       │ 7. Emit to shop room
       ▼
┌─────────────────────────────────────┐
│ io.of(REALTIME_NAMESPACE)           │
│   .to(socketRooms.shop(shopId))     │
│   .emit(BOOKING_CREATED, envelope)  │
└──────┬──────────────────────────────┘
       │
       │ 8. Emit to barber room (if applicable)
       ▼
┌─────────────────────────────────────┐
│ if (barberId) {                     │
│   io.of(REALTIME_NAMESPACE)         │
│     .to(socketRooms.barber(        │
│       barberId))                    │
│     .emit(BOOKING_CREATED,         │
│       envelope)                     │
│ }                                   │
└──────┬──────────────────────────────┘
       │
       │ 9. Get user sequence number
       ▼
┌─────────────────────────────────────┐
│ userSeq = journal.nextUserSeq(userId)│
└──────┬──────────────────────────────┘
       │
       │ 10. Create user envelope
       ▼
┌─────────────────────────────────────┐
│ userEnvelope = {                    │
│   ...envelope,                      │
│   seq: userSeq,                    │
│   eventId: `${userId}:${userSeq}`   │
│ }                                   │
└──────┬──────────────────────────────┘
       │
       │ 11. Append user event to journal
       ▼
┌─────────────────────────────────────┐
│ journal.appendUserEvent(userId,      │
│   userEnvelope)                     │
└──────┬──────────────────────────────┘
       │
       │ 12. Emit to user room
       ▼
┌─────────────────────────────────────┐
│ io.of(REALTIME_NAMESPACE)           │
│   .to(socketRooms.user(userId))     │
│   .emit(BOOKING_CREATED,            │
│     userEnvelope)                   │
└──────┬──────────────────────────────┘
       │
       │ 13. Return envelope
       ▼
┌─────────────────────────────────────┐
│ return envelope;                    │
└─────────────────────────────────────┘
```

## Transaction Flow with Locking

```
┌─────────────────────────────────────┐
│ Service Method                      │
│ (e.g., reserveQueue)               │
└──────┬──────────────────────────────┘
       │
       │ 1. Acquire distributed lock
       ▼
┌─────────────────────────────────────┐
│ QueueLock.withLock(key, ttl, fn)   │
│ ├─ Generate UUID token              │
│ ├─ SET key token PX ttl NX         │
│ ├─ If not locked → throw error     │
│ ├─ Set up lock extension timer     │
│ │  (if ttl > lockTimeout)          │
│ └─ Execute fn()                    │
└──────┬──────────────────────────────┘
       │
       │ 2. Begin database transaction
       ▼
┌─────────────────────────────────────┐
│ prisma.$transaction(               │
│   async (tx) => {                  │
│     // Transaction body            │
│   },                                │
│   {                                │
│     isolationLevel: Serializable,   │
│     maxWait: 8000ms,               │
│     timeout: 15000ms               │
│   }                                │
│ )                                   │
└──────┬──────────────────────────────┘
       │
       │ 3. Acquire row locks
       ▼
┌─────────────────────────────────────┐
│ repository.lockShop(tx, shopId)    │
│ SELECT id FROM "Shop"               │
│ WHERE id = shopId FOR UPDATE        │
│                                     │
│ ⚠️ ISSUE: Lock granularity too     │
│ coarse (entire shop)               │
└──────┬──────────────────────────────┘
       │
       │ 4. Perform business logic
       ▼
┌─────────────────────────────────────┐
│ // Validation, data creation, etc.  │
│                                     │
│ ⚠️ ISSUE: Serializable isolation    │
│ too strict for most operations     │
└──────┬──────────────────────────────┘
       │
       │ 5. Commit transaction
       ▼
┌─────────────────────────────────────┐
│ Transaction committed               │
│                                     │
│ ⚠️ ISSUE: No deadlock handling      │
└──────┬──────────────────────────────┘
       │
       │ 6. Release distributed lock
       ▼
┌─────────────────────────────────────┐
│ QueueLock release                   │
│ ├─ Clear extension timer             │
│ ├─ GET key                          │
│ ├─ Check: value == token            │
│ └─ DEL key                          │
└──────┬──────────────────────────────┘
       │
       │ 7. Return result
       ▼
┌─────────────────────────────────────┐
│ Return result to caller             │
└─────────────────────────────────────┘
```

## Redis-DB Synchronization Flow (Current - Stale)

```
┌─────────────────────────────────────┐
│ Queue Operation (e.g., enqueue)     │
└──────┬──────────────────────────────┘
       │
       │ 1. Update database
       ▼
┌─────────────────────────────────────┐
│ PostgreSQL                          │
│ ├─ Create booking                  │
│ ├─ Create activeQueue               │
│ └─ Create queueEvent               │
└──────┬──────────────────────────────┘
       │
       │ ⚠️ ISSUE: Redis not updated
       │     immediately
       │
       │ 2. Emit realtime event
       ▼
┌─────────────────────────────────────┐
│ SocketEventPublisher                │
│ └─ Emit to clients                 │
└──────┬──────────────────────────────┘
       │
       │ 3. Wait for sync trigger
       │     (asynchronous, scheduled)
       ▼
┌─────────────────────────────────────┐
│ WaitTimeService                     │
│ .recalculateLane()                  │
└──────┬──────────────────────────────┘
       │
       │ 4. Sync to Redis
       ▼
┌─────────────────────────────────────┐
│ WaitTimeEngine                      │
│ .syncBookingSnapshot()             │
│ └─ Update Redis queue              │
└──────┬──────────────────────────────┘
       │
       │ ⚠️ ISSUE: Gap between DB update
       │     and Redis sync causes
       │     stale state
       │
       │ 5. Clients read stale data
       ▼
┌─────────────────────────────────────┐
│ Client reads from Redis             │
│ └─ Gets stale queue state          │
└─────────────────────────────────────┘
```

## Redis-DB Synchronization Flow (Recommended - Write-Through)

```
┌─────────────────────────────────────┐
│ Queue Operation (e.g., enqueue)     │
└──────┬──────────────────────────────┘
       │
       │ 1. Begin transaction
       ▼
┌─────────────────────────────────────┐
│ prisma.$transaction(async (tx) => { │
└──────┬──────────────────────────────┘
       │
       │ 2. Update database
       ▼
┌─────────────────────────────────────┐
│ PostgreSQL                          │
│ ├─ Create booking                  │
│ ├─ Create activeQueue               │
│ └─ Create queueEvent               │
└──────┬──────────────────────────────┘
       │
       │ 3. Update Redis (write-through)
       ▼
┌─────────────────────────────────────┐
│ Redis                               │
│ ├─ Update queue sorted set          │
│ ├─ Update booking hash              │
│ └─ Increment version               │
└──────┬──────────────────────────────┘
       │
       │ 4. Commit transaction
       ▼
┌─────────────────────────────────────┐
│ Transaction committed               │
└──────┬──────────────────────────────┘
       │
       │ 5. Emit realtime event
       ▼
┌─────────────────────────────────────┐
│ SocketEventPublisher                │
│ └─ Emit to clients                 │
└──────┬──────────────────────────────┘
       │
       │ 6. Clients read fresh data
       ▼
┌─────────────────────────────────────┐
│ Client reads from Redis             │
│ └─ Gets fresh queue state          │
└─────────────────────────────────────┘
```
