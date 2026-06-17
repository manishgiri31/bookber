import type { FastifyInstance } from "fastify";
import type { Redis } from "ioredis";
import { env } from "../../shared/config/env.js";
import { createModuleLogger } from "../logging/structured-logger.js";
import { NoShowAppointmentWorker } from "./no-show-appointment.worker.js";
import { SmartNotificationWorker } from "./smart-notification.worker.js";
import { buildAnalyticsContainer } from "../../modules/analytics/analytics.container.js";
import { RebookingRepository } from "../../modules/rebooking/infrastructure/rebooking.repository.js";
import { RebookingService } from "../../modules/rebooking/application/rebooking.service.js";
import { RebookingWorker } from "../../modules/rebooking/workers/rebooking.worker.js";

const log = createModuleLogger("recovery-workers");

export function startRecoveryWorkers(app: FastifyInstance, redis: Redis | null): () => void {
  if (!env.RECOVERY_WORKERS_ENABLED || env.NODE_ENV === "test") {
    return () => undefined;
  }

  const { queueRecoveryService, waitTime, realtime } = app.queueDeps;
  queueRecoveryService.startWorkers(redis ?? undefined, waitTime);

  const noShowWorker = new NoShowAppointmentWorker({
    gracePeriodMinutes: 15,
    intervalMs: 2 * 60 * 1000,
    batchSize: 50,
  });
  const stopNoShow = noShowWorker.start();

  const { worker: analyticsWorker } = buildAnalyticsContainer();
  const stopAnalytics = analyticsWorker.start();

  const notificationService = app.notificationDeps?.service;
  let stopSmartNotif: (() => void) | undefined;
  let stopRebooking: (() => void) | undefined;

  if (notificationService) {
    const smartNotif = new SmartNotificationWorker(notificationService, 5 * 60 * 1000);
    realtime.onPositionChanged((e) => smartNotif.onPositionChanged(e));
    stopSmartNotif = smartNotif.start();

    const rebookingRepo = new RebookingRepository();
    const rebookingService = new RebookingService(rebookingRepo, notificationService);
    const rebookingWorker = new RebookingWorker(rebookingService);
    stopRebooking = rebookingWorker.start();
  }

  log.info("workers started: queue-recovery, no-show, analytics, smart-notifications, rebooking");

  return () => {
    queueRecoveryService.stopWorkers();
    stopNoShow();
    stopAnalytics();
    stopSmartNotif?.();
    stopRebooking?.();
    log.info("all workers stopped");
  };
}
