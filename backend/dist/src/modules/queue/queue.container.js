import { QueueLock } from "./queue.lock.js";
import { PrismaQueueRepository } from "./infrastructure/queue.repository.js";
import { ChairAllocator } from "./application/chair-allocator.service.js";
import { QueueEngineService } from "./application/queue-engine.service.js";
import { QueueCoordinator } from "./application/queue-coordinator.service.js";
import { QueueRealtimeEmitter } from "./application/queue-realtime.emitter.js";
import { WaitTimeEngine } from "./application/wait-time.engine.js";
import { RecoveryOrchestrator } from "./recovery/recovery-orchestrator.js";
import { RecoveryEventLogger } from "./recovery/recovery-event-logger.js";
import { QueueReservationService } from "./application/services/queue-reservation.service.js";
import { QueuePositionService } from "./application/services/queue-position.service.js";
import { ChairAllocationService } from "./application/services/chair-allocation.service.js";
import { WaitTimeService } from "./application/services/wait-time.service.js";
import { QueueRealtimeService } from "./application/services/queue-realtime.service.js";
import { QueueRecoveryService } from "./application/services/queue-recovery.service.js";
import { WaitTimeRedisStore } from "./infrastructure/wait-time-redis.store.js";
export function buildQueueDependencies(app) {
    const repository = new PrismaQueueRepository();
    const lock = new QueueLock(app.redis);
    const chairAllocator = new ChairAllocator(repository);
    const realtime = new QueueRealtimeEmitter(() => app.socketPublisher);
    const waitTime = new WaitTimeEngine(app.redis);
    const redisStore = new WaitTimeRedisStore(app.redis);
    const engine = new QueueEngineService(repository, chairAllocator, lock, realtime, waitTime, app.redis);
    const coordinator = new QueueCoordinator(engine);
    // Refactored isolated services
    const queueReservationService = new QueueReservationService(repository, lock, redisStore);
    const queuePositionService = new QueuePositionService(repository, lock);
    const chairAllocationService = new ChairAllocationService(repository, chairAllocator, lock);
    const waitTimeService = new WaitTimeService(repository, waitTime);
    const queueRealtimeService = new QueueRealtimeService(realtime);
    // Recovery system integration
    const recoveryEventLogger = new RecoveryEventLogger();
    const recoveryOrchestrator = new RecoveryOrchestrator(lock, {}, app.redis, waitTime);
    const queueRecoveryService = new QueueRecoveryService(recoveryOrchestrator, recoveryEventLogger);
    return {
        repository,
        lock,
        chairAllocator,
        waitTime,
        engine,
        coordinator,
        queueReservationService,
        queuePositionService,
        chairAllocationService,
        waitTimeService,
        queueRealtimeService,
        recoveryOrchestrator,
        recoveryEventLogger,
        queueRecoveryService
    };
}
