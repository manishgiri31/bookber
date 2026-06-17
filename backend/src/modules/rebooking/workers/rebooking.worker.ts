import { createModuleLogger } from "../../../infrastructure/logging/structured-logger.js";
import type { RebookingService } from "../application/rebooking.service.js";

const log = createModuleLogger("rebooking-worker");

export class RebookingWorker {
  private scheduleTimer: ReturnType<typeof setInterval> | null = null;
  private dispatchTimer: ReturnType<typeof setInterval> | null = null;

  constructor(
    private readonly service: RebookingService,
    private readonly scheduleIntervalMs = 60 * 60 * 1000,
    private readonly dispatchIntervalMs = 15 * 60 * 1000
  ) {}

  start(): () => void {
    this.scheduleTimer = setInterval(() => {
      this.service
        .scheduleRemindersForRecentCompletions()
        .catch((err) => log.error({ err }, "reminder scheduling sweep failed"));
    }, this.scheduleIntervalMs);

    this.dispatchTimer = setInterval(() => {
      this.service
        .dispatchDueReminders()
        .catch((err) => log.error({ err }, "reminder dispatch sweep failed"));
    }, this.dispatchIntervalMs);

    // Run both immediately on start
    this.service.scheduleRemindersForRecentCompletions().catch(() => undefined);
    this.service.dispatchDueReminders().catch(() => undefined);

    log.info(
      { scheduleIntervalMs: this.scheduleIntervalMs, dispatchIntervalMs: this.dispatchIntervalMs },
      "rebooking worker started"
    );

    return () => this.stop();
  }

  stop(): void {
    if (this.scheduleTimer) clearInterval(this.scheduleTimer);
    if (this.dispatchTimer) clearInterval(this.dispatchTimer);
    this.scheduleTimer = null;
    this.dispatchTimer = null;
    log.info("rebooking worker stopped");
  }
}
