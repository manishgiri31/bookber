import { env } from "../../shared/config/env.js";
import { createModuleLogger } from "../logging/structured-logger.js";
const log = createModuleLogger("recovery-workers");
export function startRecoveryWorkers(app, redis) {
    if (!env.RECOVERY_WORKERS_ENABLED || env.NODE_ENV === "test") {
        return () => undefined;
    }
    const { queueRecoveryService, waitTime } = app.queueDeps;
    queueRecoveryService.startWorkers(redis ?? undefined, waitTime);
    log.info("queue recovery workers started (stale booking, orphaned chair, queue reconcile, redis rebuild)");
    return () => {
        queueRecoveryService.stopWorkers();
        log.info("queue recovery workers stopped");
    };
}
