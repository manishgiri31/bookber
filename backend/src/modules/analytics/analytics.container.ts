import { AnalyticsRepository } from "./infrastructure/analytics.repository.js";
import { AnalyticsService } from "./application/analytics.service.js";
import { AnalyticsController } from "./presentation/analytics.controller.js";
import { AnalyticsAggregatorWorker } from "./workers/analytics-aggregator.worker.js";

export type AnalyticsDeps = {
  service: AnalyticsService;
  controller: AnalyticsController;
  worker: AnalyticsAggregatorWorker;
};

export function buildAnalyticsContainer(): AnalyticsDeps {
  const repo = new AnalyticsRepository();
  const service = new AnalyticsService(repo);
  const controller = new AnalyticsController(service);
  const worker = new AnalyticsAggregatorWorker(service);
  return { service, controller, worker };
}
