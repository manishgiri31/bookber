# Production-Grade Redis Architecture

## Overview

This document describes the production-grade Redis architecture for the Bookber queue system, designed for high availability, scalability, and reliability.

## Architecture Components

### 1. Redis Cluster Support

**Configuration**:
- Redis Cluster mode with automatic sharding
- Minimum 3 master nodes for high availability
- 1 replica per master for failover
- Hash slot distribution for data partitioning

**Key Distribution Strategy**:
- Queue data: Hashed by `shopId` for locality
- Wait time data: Hashed by `shopId` for locality
- Socket data: Hashed by `shopId` for locality
- Lock data: Distributed across all nodes
- Event journal: Hashed by timestamp for time-series access

### 2. Connection Pooling

**Pool Configuration**:
- Min connections: 5 per node
- Max connections: 50 per node
- Connection timeout: 5 seconds
- Idle timeout: 30 seconds
- Max lifetime: 1 hour

**Pool Manager**:
- Automatic connection health checks
- Connection recycling on failure
- Load balancing across connections
- Connection backpressure handling

### 3. Retry Strategies

**Exponential Backoff**:
- Initial delay: 100ms
- Max delay: 5 seconds
- Backoff multiplier: 2
- Max retries: 5
- Jitter: ±25%

**Retry Conditions**:
- Connection timeout
- Network errors
- Cluster node unavailable
- Command timeout
- MOVED/ASK redirection

**Non-Retryable Errors**:
- Authentication failures
- Permission errors
- Invalid command syntax
- Out of memory (OOM)

### 4. Backpressure Handling

**Queue-Based Backpressure**:
- Operation queue with max size: 1000
- Queue timeout: 10 seconds
- Rejection threshold: 90% capacity
- Priority queue for critical operations

**Rate Limiting**:
- Max operations per second: 1000
- Per-shop rate limit: 100 ops/sec
- Per-connection rate limit: 50 ops/sec
- Token bucket algorithm

### 5. Health Checks

**Health Check Types**:
- Connection health: Ping every 5 seconds
- Node health: Check cluster state every 10 seconds
- Memory health: Check memory usage every 30 seconds
- Latency health: Check command latency every 5 seconds
- Replication health: Check replication lag every 10 seconds

**Health Metrics**:
- Connection count
- Active connections
- Idle connections
- Failed connections
- Average latency
- P95 latency
- P99 latency
- Memory usage
- Eviction count

**Health Actions**:
- Auto-reconnect on connection loss
- Connection recycling on high latency
- Alert on high memory usage
- Alert on replication lag
- Circuit breaker on repeated failures

### 6. Failover Handling

**Failover Detection**:
- Node unresponsive for 10 seconds
- Replication lag > 30 seconds
- Master unreachable
- Cluster state inconsistent

**Failover Actions**:
- Automatic promotion of replica
- Connection pool refresh
- Operation retry with new master
- Cache invalidation
- Event journal replay

**Failover Recovery**:
- Reconnect to new master
- Rebuild connection pool
- Replay missed events
- Validate cache consistency
- Resume normal operations

### 7. Cache Rebuild Strategies

**Rebuild Triggers**:
- Cache miss rate > 10%
- Cache hit rate < 80%
- Memory pressure > 80%
- Manual rebuild request
- Failover completion

**Rebuild Strategies**:
- **Incremental**: Rebuild only missing keys
- **Full**: Rebuild all keys from database
- **Priority**: Rebuild hot keys first
- **Lazy**: Rebuild on demand

**Rebuild Process**:
1. Mark cache as rebuilding
2. Fetch data from database
3. Write to Redis in batches
4. Validate consistency
5. Mark cache as ready
6. Handle rebuild failures

### 8. Memory Optimization

**Memory Optimization Techniques**:
- Use Redis hashes for related data
- Compress large values
- Set appropriate TTLs
- Use Redis Streams for event journaling
- Use Redis Sorted Sets for queues
- Use Redis HyperLogLog for counting
- Use Redis Bitmaps for flags

**Memory Monitoring**:
- Track memory usage per key type
- Track memory usage per shop
- Track eviction rate
- Track fragmentation ratio
- Alert on memory pressure

**Memory Actions**:
- Auto-evict old data
- Compress large values
- Split large hashes
- Use memory-efficient data structures

### 9. Queue Operations Optimization

**Queue Data Structures**:
- Sorted sets for queue ordering (O(log n) operations)
- Hashes for booking snapshots (O(1) access)
- Lists for pub/sub channels
- Streams for event journaling

**Queue Operations**:
- Enqueue: ZADD (O(log n))
- Dequeue: ZREM (O(log n))
- Position update: ZADD (O(log n))
- Range query: ZRANGE (O(log n + k))
- Length: ZCARD (O(1))

**Pipeline Optimization**:
- Batch operations in pipelines
- Reduce round trips
- Parallel independent operations
- Use MULTI/EXEC for transactions

### 10. Socket Pub/Sub Optimization

**Pub/Sub Architecture**:
- Redis Pub/Sub for real-time events
- Redis Streams for event persistence
- Fan-out pattern for multiple subscribers
- Channel sharding for scalability

**Optimization Techniques**:
- Use Redis Streams for reliable delivery
- Use consumer groups for load balancing
- Use message batching
- Use compression for large payloads
- Use binary protocol for efficiency

**Channel Strategy**:
- Shop-specific channels: `shop:{shopId}:events`
- User-specific channels: `user:{userId}:events`
- Global channels: `global:events`
- System channels: `system:events`

### 11. Wait-Time Reads Optimization

**Caching Strategy**:
- Multi-level caching (L1: memory, L2: Redis, L3: database)
- Cache warming on startup
- Cache invalidation on changes
- Prefetching for hot shops

**Read Optimization**:
- Use Redis for hot data
- Use database for cold data
- Use read replicas for scaling
- Use connection pooling for performance

**Calculation Optimization**:
- Cache calculation results
- Use incremental updates
- Batch calculations
- Use background workers

### 12. Distributed Locks

**Lock Implementation**:
- Redlock algorithm for cluster
- Lock extension for long operations
- Lock ownership verification
- Lock timeout handling
- Lock release on failure

**Lock Keys**:
- `lock:shop:{shopId}:queue` - Queue operations
- `lock:shop:{shopId}:chair` - Chair operations
- `lock:socket:cleanup` - Socket cleanup
- `lock:recovery:{type}` - Recovery operations

**Lock Configuration**:
- Lock timeout: 30 seconds
- Lock extension interval: 15 seconds
- Max lock lifetime: 5 minutes
- Retry delay: 1 second
- Max retries: 3

### 13. Event Journaling

**Event Journal Architecture**:
- Redis Streams for event persistence
- Consumer groups for event processing
- Event replay for recovery
- Event retention policy

**Event Types**:
- Queue events: enqueue, dequeue, position change
- Chair events: assign, release, status change
- Socket events: connect, disconnect, message
- System events: failover, rebuild, alert

**Event Processing**:
- Background workers consume events
- Event deduplication
- Event aggregation
- Event analytics

## Implementation Components

### Redis Connection Pool Manager

```typescript
class RedisConnectionPool {
  private connections: RedisClient[];
  private available: RedisClient[];
  private inUse: Set<RedisClient>;
  
  async acquire(): Promise<RedisClient>;
  async release(connection: RedisClient): Promise<void>;
  async healthCheck(): Promise<void>;
  async close(): Promise<void>;
}
```

### Retry Strategy

```typescript
class RetryStrategy {
  async execute<T>(fn: () => Promise<T>): Promise<T>;
  private shouldRetry(error: Error): boolean;
  private getDelay(attempt: number): number;
}
```

### Backpressure Handler

```typescript
class BackpressureHandler {
  private operationQueue: OperationQueue;
  
  async execute<T>(fn: () => Promise<T>): Promise<T>;
  private checkCapacity(): boolean;
  private rejectIfOverloaded(): void;
}
```

### Health Check Service

```typescript
class RedisHealthCheck {
  async checkConnection(): Promise<HealthStatus>;
  async checkMemory(): Promise<HealthStatus>;
  async checkLatency(): Promise<HealthStatus>;
  async checkReplication(): Promise<HealthStatus>;
  async runAllChecks(): Promise<AggregateHealthStatus>;
}
```

### Failover Handler

```typescript
class FailoverHandler {
  async detectFailover(): Promise<boolean>;
  async handleFailover(): Promise<void>;
  async recoverFromFailover(): Promise<void>;
  private promoteReplica(): Promise<void>;
  private refreshConnections(): Promise<void>;
}
```

### Cache Rebuild Service

```typescript
class CacheRebuildService {
  async rebuildCache(shopId: string): Promise<void>;
  async rebuildAll(): Promise<void>;
  async incrementalRebuild(): Promise<void>;
  private validateConsistency(): Promise<void>;
}
```

## Configuration

### Redis Cluster Configuration

```typescript
interface RedisClusterConfig {
  nodes: Array<{
    host: string;
    port: number;
    password?: string;
  }>;
  options: {
    enableReadyCheck: true;
    maxRetriesPerRequest: 3;
    lazyConnect: true;
    retryStrategy: (times: number) => number;
    redisOptions: {
      password: string;
      tls: TLSOptions;
    };
  };
}
```

### Connection Pool Configuration

```typescript
interface ConnectionPoolConfig {
  minConnections: number;
  maxConnections: number;
  connectionTimeout: number;
  idleTimeout: number;
  maxLifetime: number;
  healthCheckInterval: number;
}
```

### Retry Configuration

```typescript
interface RetryConfig {
  maxRetries: number;
  initialDelay: number;
  maxDelay: number;
  backoffMultiplier: number;
  jitter: number;
}
```

### Backpressure Configuration

```typescript
interface BackpressureConfig {
  maxQueueSize: number;
  queueTimeout: number;
  rejectionThreshold: number;
  maxOperationsPerSecond: number;
  perShopRateLimit: number;
}
```

## Monitoring and Observability

### Metrics

- Connection pool metrics
- Operation latency metrics
- Error rate metrics
- Memory usage metrics
- Cache hit/miss metrics
- Queue length metrics
- Lock contention metrics

### Logging

- Connection events
- Operation events
- Error events
- Failover events
- Rebuild events
- Health check events

### Alerts

- Connection failures
- High latency
- Memory pressure
- Replication lag
- Cache miss rate
- Lock contention

## Best Practices

1. **Always use connection pooling** for production
2. **Implement retry logic** for all Redis operations
3. **Monitor health metrics** continuously
4. **Set appropriate TTLs** for cached data
5. **Use pipelines** for batch operations
6. **Use transactions** for atomic operations
7. **Handle failover gracefully**
8. **Optimize memory usage** proactively
9. **Test failover scenarios** regularly
10. **Document cache strategies** clearly
