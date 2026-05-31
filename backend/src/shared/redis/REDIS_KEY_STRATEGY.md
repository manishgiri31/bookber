# Redis Key Strategy

## Overview

This document describes the Redis key naming convention and strategy for the Bookber queue system, designed for production-grade reliability, scalability, and performance.

## Key Naming Convention

### Format
```
{namespace}:{entity}:{identifier}:{attribute}
```

### Namespaces
- `queue` - Queue operations
- `wait` - Wait time calculations
- `chair` - Chair state
- `socket` - Socket connections
- `lock` - Distributed locks
- `event` - Event journaling
- `cache` - General caching
- `metrics` - Performance metrics

## Key Categories

### 1. Queue Keys

#### Queue Sorted Sets
```
queue:shop:{shopId}:lane:{lane}
```
- **Type**: Sorted Set (ZSET)
- **Score**: Queue position (sparse positioning)
- **Member**: Booking ID
- **TTL**: None (persistent)
- **Purpose**: Queue ordering and position tracking
- **Example**: `queue:shop:abc123:lane:BOOKBER`

#### Booking Snapshots
```
queue:booking:{bookingId}
```
- **Type**: Hash
- **Fields**: shopId, lane, position, userId, serviceId, barberId, queueStatus, estimatedWaitMinutes, estimatedServiceStartIso
- **TTL**: 24 hours
- **Purpose**: Hot read path for booking data
- **Example**: `queue:booking:xyz789`

#### Queue Version
```
queue:shop:{shopId}:version
```
- **Type**: String (counter)
- **Value**: Integer, incremented on queue changes
- **TTL**: None (persistent)
- **Purpose**: Cache invalidation
- **Example**: `queue:shop:abc123:version`

### 2. Wait Time Keys

#### Wait Time Configuration
```
wait:shop:{shopId}:config
```
- **Type**: Hash
- **Fields**: activeReservedChairs, activeWalkInChairs, cleaningBufferMinutes, overrunBufferMinutes
- **TTL**: None (persistent)
- **Purpose**: Shop-specific wait time configuration
- **Example**: `wait:shop:abc123:config`

#### Shop Averages
```
wait:shop:{shopId}:avg:historical
wait:shop:{shopId}:avg:recent
```
- **Type**: Hash
- **Fields**: HAIRCUT, BEARD, COMBO (service categories)
- **TTL**: 7 days (historical), 1 day (recent)
- **Purpose**: Service duration averages
- **Example**: `wait:shop:abc123:avg:historical`

#### Barber Averages
```
wait:barber:{barberId}:avg:historical
wait:barber:{barberId}:avg:recent
```
- **Type**: Hash
- **Fields**: HAIRCUT, BEARD, COMBO (service categories)
- **TTL**: 7 days (historical), 1 day (recent)
- **Purpose**: Barber-specific service duration averages
- **Example**: `wait:barber:barber456:avg:historical`

#### Barber State
```
wait:barber:{barberId}:state
```
- **Type**: Hash
- **Fields**: delayMinutes, overrunMinutes, updatedAtMs
- **TTL**: 1 hour
- **Purpose**: Barber runtime compensation state
- **Example**: `wait:barber:barber456:state`

#### Wait Version
```
wait:shop:{shopId}:version
```
- **Type**: String (counter)
- **Value**: Integer, incremented on wait time recalculation
- **TTL**: None (persistent)
- **Purpose**: Cache invalidation for wait times
- **Example**: `wait:shop:abc123:version`

### 3. Chair Keys

#### Chair State
```
chair:{chairId}
```
- **Type**: Hash
- **Fields**: shopId, status, reservedForBookBer, bookingId, activeServiceStart, activeServiceEnd
- **TTL**: 1 hour
- **Purpose**: Chair state caching
- **Example**: `chair:chair123`

#### Chair Lock
```
lock:chair:{chairId}
```
- **Type**: String (lock)
- **Value**: UUID token
- **TTL**: 30 seconds (with extension)
- **Purpose**: Distributed lock for chair operations
- **Example**: `lock:chair:chair123`

### 4. Socket Keys

#### Socket State
```
socket:{socketId}
```
- **Type**: Hash
- **Fields**: userId, shopId, bookingId, connectedAt, lastHeartbeat
- **TTL**: 1 hour
- **Purpose**: Socket state tracking
- **Example**: `socket:socket456`

#### User Sockets
```
socket:user:{userId}:sockets
```
- **Type**: Set
- **Members**: Socket IDs
- **TTL**: 1 hour
- **Purpose**: Track user's active sockets
- **Example**: `socket:user:user789:sockets`

#### Shop Sockets
```
socket:shop:{shopId}:sockets
```
- **Type**: Set
- **Members**: Socket IDs
- **TTL**: 1 hour
- **Purpose**: Track shop's active sockets
- **Example**: `socket:shop:abc123:sockets`

#### Socket Lock
```
lock:socket:cleanup
```
- **Type**: String (lock)
- **Value**: UUID token
- **TTL**: 30 seconds
- **Purpose**: Distributed lock for socket cleanup
- **Example**: `lock:socket:cleanup`

### 5. Lock Keys

#### Queue Lock
```
lock:shop:{shopId}:queue
```
- **Type**: String (lock)
- **Value**: UUID token
- **TTL**: 30 seconds (with extension)
- **Purpose**: Distributed lock for queue operations
- **Example**: `lock:shop:abc123:queue`

#### Chair Recovery Lock
```
lock:shop:{shopId}:chair-recovery
```
- **Type**: String (lock)
- **Value**: UUID token
- **TTL**: 30 seconds
- **Purpose**: Distributed lock for chair recovery
- **Example**: `lock:shop:abc123:chair-recovery`

#### Wait Time Rebuild Lock
```
lock:shop:{shopId}:wait-time-rebuild
```
- **Type**: String (lock)
- **Value**: UUID token
- **TTL**: 30 seconds
- **Purpose**: Distributed lock for wait time rebuilding
- **Example**: `lock:shop:abc123:wait-time-rebuild`

#### Redis Repair Lock
```
lock:shop:{shopId}:redis-repair
```
- **Type**: String (lock)
- **Value**: UUID token
- **TTL**: 30 seconds
- **Purpose**: Distributed lock for Redis repair
- **Example**: `lock:shop:abc123:redis-repair`

### 6. Event Journal Keys

#### Event Stream
```
event:stream:queue
event:stream:chair
event:stream:socket
event:stream:system
```
- **Type**: Stream
- **Fields**: eventId, type, payload, timestamp
- **TTL**: 7 days
- **Purpose**: Event journaling for recovery and analytics
- **Example**: `event:stream:queue`

#### Event Consumer Group
```
event:group:{groupName}
```
- **Type**: Consumer Group
- **Consumers**: Background workers
- **Purpose**: Event processing with load balancing
- **Example**: `event:group:queue-processor`

### 7. Cache Keys

#### Shop Queue Cache
```
cache:shop:{shopId}:queue:{lane}
```
- **Type**: String (JSON)
- **Value**: Serialized queue data
- **TTL**: 5 minutes
- **Purpose**: Cache queue data for fast reads
- **Example**: `cache:shop:abc123:queue:BOOKBER`

#### Wait Time Cache
```
cache:shop:{shopId}:wait:{lane}
```
- **Type**: String (JSON)
- **Value**: Serialized wait time data
- **TTL**: 1 minute
- **Purpose**: Cache wait time calculations
- **Example**: `cache:shop:abc123:wait:BOOKBER`

#### Chair Cache
```
cache:chair:{chairId}
```
- **Type**: String (JSON)
- **Value**: Serialized chair data
- **TTL**: 5 minutes
- **Purpose**: Cache chair state
- **Example**: `cache:chair:chair123`

### 8. Metrics Keys

#### Operation Metrics
```
metrics:operations:{operation}
```
- **Type**: Hash
- **Fields**: count, success, failure, latency_avg, latency_p95, latency_p99
- **TTL**: 1 hour
- **Purpose**: Track operation metrics
- **Example**: `metrics:operations:enqueue`

#### Connection Metrics
```
metrics:connections
```
- **Type**: Hash
- **Fields**: active, idle, failed, created, destroyed
- **TTL**: 1 hour
- **Purpose**: Track connection pool metrics
- **Example**: `metrics:connections`

#### Cache Metrics
```
metrics:cache:{cacheType}
```
- **Type**: Hash
- **Fields**: hits, misses, hit_rate, miss_rate, size, evictions
- **TTL**: 1 hour
- **Purpose**: Track cache performance
- **Example**: `metrics:cache:queue`

## Key Distribution Strategy

### Hash Slot Distribution

For Redis Cluster, keys are distributed across nodes using hash slots. To ensure related keys are on the same node:

#### Hash Tags
Use hash tags `{...}` to force related keys to the same hash slot:
```
queue:shop:{shopId}:lane:{lane}
queue:booking:{bookingId}
wait:shop:{shopId}:config
```

All keys with the same `{shopId}` will be on the same node.

### Distribution Rules

1. **Shop-local data**: Hash by `{shopId}`
   - Queue data
   - Wait time data
   - Socket data
   - Chair data

2. **Global data**: Distribute across all nodes
   - Locks
   - Metrics
   - System events

3. **Time-series data**: Hash by timestamp
   - Event journal
   - Metrics history

## TTL Strategy

### No TTL (Persistent)
- Queue sorted sets
- Wait time configuration
- Queue version counters
- Wait version counters

### Short TTL (1 hour)
- Chair state
- Socket state
- Barber state
- Locks

### Medium TTL (1 day)
- Recent averages
- Cache data

### Long TTL (7 days)
- Historical averages
- Event journal
- Metrics

## Memory Optimization

### Data Structure Selection

1. **Sorted Sets (ZSET)**: Queue ordering
   - O(log n) for enqueue/dequeue
   - O(log n + k) for range queries
   - O(1) for length

2. **Hashes**: Related fields
   - O(1) for field access
   - Memory efficient for multiple fields
   - HGETALL for bulk reads

3. **Sets**: Unique collections
   - O(1) for add/remove
   - O(1) for membership test
   - Memory efficient for unique values

4. **Streams**: Event journaling
   - Persistent event storage
   - Consumer groups for processing
   - Automatic trimming

5. **Strings**: Simple values
   - O(1) for get/set
   - Memory efficient for small values
   - INCR for counters

### Memory Optimization Techniques

1. **Use Hashes**: Instead of multiple keys, use a single hash
2. **Set TTLs**: Prevent memory bloat
3. **Use Compression**: For large values
4. **Use Binary Protocol**: For efficiency
5. **Use Pipelines**: Reduce round trips
6. **Use Lua Scripts**: For complex operations

## Key Naming Best Practices

1. **Use consistent naming**: Follow the `{namespace}:{entity}:{identifier}:{attribute}` pattern
2. **Use hash tags**: For related keys in cluster
3. **Set appropriate TTLs**: Based on data freshness requirements
4. **Use descriptive names**: Make keys self-documenting
5. **Avoid special characters**: Use only alphanumeric, colons, and hyphens
6. **Keep keys short**: But maintain readability
7. **Use lowercase**: For consistency
8. **Use hyphens for multi-word**: e.g., `active-service-start`

## Key Cleanup Strategy

### Automatic Cleanup
- TTL-based expiration
- Event journal trimming
- Metrics aggregation and cleanup

### Manual Cleanup
- Cache invalidation on data changes
- Lock release on operation completion
- Socket cleanup on disconnect

### Scheduled Cleanup
- Daily cleanup of expired data
- Weekly cleanup of old metrics
- Monthly cleanup of historical data

## Key Migration Strategy

When changing key structure:

1. **Dual-write**: Write to both old and new keys
2. **Dual-read**: Read from new keys, fallback to old
3. **Data migration**: Migrate data from old to new
4. **Switch-over**: Switch to new keys only
5. **Cleanup**: Remove old keys

## Key Monitoring

### Metrics to Track
- Key count per namespace
- Memory usage per key type
- Eviction rate per key type
- Hit rate for cached keys
- Miss rate for cached keys

### Alerts
- High memory usage
- High eviction rate
- Low cache hit rate
- Key count anomalies
- TTL expiration rate
