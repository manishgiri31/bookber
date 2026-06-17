import { createModuleLogger } from "../../../infrastructure/logging/structured-logger.js";
import type { AnalyticsService } from "../application/analytics.service.js";

const log = createModuleLogger("analytics-aggregator-worker");

export class AnalyticsAggregatorWorker {
  private timer: ReturnType<typeof setInterval> | null = null;

  constructor(
    private readonly service: AnalyticsService,
    private readonly intervalMs = 60 * 60 * 1000
  ) {}

  start(): () => void {
    this.scheduleAt2AM();
    log.info({ intervalMs: this.intervalMs }, "analytics aggregator worker started");
    return () => this.stop();
  }

  stop(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
      log.info("analytics aggregator worker stopped");
    }
  }

  private scheduleAt2AM(): void {
    const now = new Date();
    const next2AM = new Date(now);
    next2AM.setHours(2, 0, 0, 0);
    if (next2AM <= now) {
      next2AM.setDate(next2AM.getDate() + 1);
    }

    const delayMs = next2AM.getTime() - now.getTime();

    setTimeout(() => {
      this.run().catch((err) => log.error({ err }, "analytics aggregation run failed"));
      this.timer = setInterval(() => {
        this.run().catch((err) => log.error({ err }, "analytics aggregation run failed"));
      }, 24 * 60 * 60 * 1000);
    }, delayMs);

    log.info({ nextRunAt: next2AM.toISOString() }, "analytics aggregation scheduled");
  }

  async run(): Promise<void> {
    log.info("running daily analytics aggregation");
    const result = await this.service.runDailyAggregation();
    log.info(result, "daily analytics aggregation complete");
  }
}
