import type { FastifyRequest, FastifyReply } from "fastify";
import { z } from "zod";
import type { AnalyticsService } from "../application/analytics.service.js";
import { dateRangeSchema, shopParamSchema } from "./analytics.schemas.js";
import { HttpError } from "../../../shared/errors/http-error.js";

type ShopParam = z.infer<typeof shopParamSchema>;
type DateRangeQuery = z.infer<typeof dateRangeSchema>;

function requireOwnerOrAdmin(request: FastifyRequest, shopId: string) {
  const user = (request as any).user as { id: string; role: string; shopId?: string } | undefined;
  if (!user) throw HttpError.unauthorized();
  if (user.role === "ADMIN") return;
  if (user.role === "BARBER" && user.shopId === shopId) return;
  throw HttpError.forbidden();
}

export class AnalyticsController {
  constructor(private readonly service: AnalyticsService) {}

  async getDailyAnalytics(
    request: FastifyRequest<{ Params: ShopParam; Querystring: { date?: string } }>,
    reply: FastifyReply
  ) {
    requireOwnerOrAdmin(request, request.params.shopId);
    const date = request.query.date ? new Date(request.query.date) : new Date(Date.now() - 86400_000);
    const result = await this.service.aggregateDay(request.params.shopId, date);
    return reply.send(result);
  }

  async getPeakHours(
    request: FastifyRequest<{ Params: ShopParam; Querystring: DateRangeQuery }>,
    reply: FastifyReply
  ) {
    requireOwnerOrAdmin(request, request.params.shopId);
    const { from, to } = request.query;
    const result = await this.service.getPeakHours(
      request.params.shopId,
      new Date(from),
      new Date(to)
    );
    return reply.send(result);
  }

  async getUtilization(
    request: FastifyRequest<{ Params: ShopParam; Querystring: DateRangeQuery }>,
    reply: FastifyReply
  ) {
    requireOwnerOrAdmin(request, request.params.shopId);
    const { from, to } = request.query;
    const result = await this.service.getUtilization(
      request.params.shopId,
      new Date(from),
      new Date(to)
    );
    return reply.send(result);
  }

  async getWeeklyInsights(
    request: FastifyRequest<{ Params: ShopParam }>,
    reply: FastifyReply
  ) {
    requireOwnerOrAdmin(request, request.params.shopId);
    const result = await this.service.getWeeklyInsights(request.params.shopId);
    return reply.send(result);
  }
}
