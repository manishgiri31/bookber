import type { FastifyRequest, FastifyReply } from "fastify";
import { z } from "zod";
import type { AnalyticsService } from "../application/analytics.service.js";
import { dateRangeSchema, shopParamSchema } from "./analytics.schemas.js";
import { HttpError } from "../../../shared/errors/http-error.js";
import { getAuthUser } from "../../auth/presentation/auth-user.js";
import { prisma } from "../../../shared/prisma/client.js";

type ShopParam = z.infer<typeof shopParamSchema>;
type DateRangeQuery = z.infer<typeof dateRangeSchema>;

async function requireOwnerOrAdmin(request: FastifyRequest, shopId: string) {
  const user = getAuthUser(request);
  if (user.role === "ADMIN") return;
  if (user.role === "BARBER") {
    const shop = await prisma.shop.findFirst({ where: { id: shopId, ownerId: user.id } });
    if (shop) return;
    const barber = await prisma.barber.findFirst({ where: { userId: user.id, shopId } });
    if (barber) return;
  }
  throw HttpError.forbidden("Forbidden");
}

export class AnalyticsController {
  constructor(private readonly service: AnalyticsService) {}

  async getDailyAnalytics(
    request: FastifyRequest<{ Params: ShopParam; Querystring: { date?: string } }>,
    reply: FastifyReply
  ) {
    await requireOwnerOrAdmin(request, request.params.shopId);
    const date = request.query.date ? new Date(request.query.date) : new Date(Date.now() - 86400_000);
    const result = await this.service.aggregateDay(request.params.shopId, date);
    return reply.send(result);
  }

  async getPeakHours(
    request: FastifyRequest<{ Params: ShopParam; Querystring: DateRangeQuery }>,
    reply: FastifyReply
  ) {
    await requireOwnerOrAdmin(request, request.params.shopId);
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
    await requireOwnerOrAdmin(request, request.params.shopId);
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
    await requireOwnerOrAdmin(request, request.params.shopId);
    const result = await this.service.getWeeklyInsights(request.params.shopId);
    return reply.send(result);
  }
}
