import type { FastifyReply, FastifyRequest } from "fastify";
import {
  analyticsDateRangeSchema,
  barberListFilterSchema,
  moderationActionSchema
} from "../application/admin.schemas.js";
import type { AdminService } from "../application/admin.service.js";

export class AdminController {
  constructor(private readonly service: AdminService) { }

  getDashboard = async (request: FastifyRequest, reply: FastifyReply) => {
    const { fromDate, toDate } = request.query as { fromDate?: string; toDate?: string };
    const from = fromDate ? new Date(fromDate) : undefined;
    const to = toDate ? new Date(toDate) : undefined;
    const dashboard = await this.service.getDashboard(from, to);
    return reply.send(dashboard);
  };

  getAnalyticsOverview = async (request: FastifyRequest, reply: FastifyReply) => {
    const { fromDate, toDate } = request.query as { fromDate?: string; toDate?: string };
    const from = fromDate ? new Date(fromDate) : undefined;
    const to = toDate ? new Date(toDate) : undefined;
    const analytics = await this.service.getAnalyticsOverview(from, to);
    return reply.send(analytics);
  };

  getBookingAnalytics = async (request: FastifyRequest, reply: FastifyReply) => {
    const { fromDate, toDate, shopId } = request.query as { fromDate?: string; toDate?: string; shopId?: string };
    const from = fromDate ? new Date(fromDate) : undefined;
    const to = toDate ? new Date(toDate) : undefined;
    const analytics = await this.service.getBookingAnalytics(from, to, shopId);
    return reply.send(analytics);
  };

  getEarningsOverview = async (request: FastifyRequest, reply: FastifyReply) => {
    const { fromDate, toDate } = request.query as { fromDate?: string; toDate?: string };
    const from = fromDate ? new Date(fromDate) : undefined;
    const to = toDate ? new Date(toDate) : undefined;
    const earnings = await this.service.getEarningsOverview(from, to);
    return reply.send(earnings);
  };

  getBarberModerationList = async (request: FastifyRequest, reply: FastifyReply) => {
    const { status, shopId, flaggedOnly, limit, offset } = request.query as {
      status?: string;
      shopId?: string;
      flaggedOnly?: string;
      limit?: string;
      offset?: string;
    };
    const dto = barberListFilterSchema.parse({
      status,
      shopId,
      flaggedOnly: flaggedOnly === "true",
      limit: limit ? parseInt(limit) : undefined,
      offset: offset ? parseInt(offset) : undefined
    });
    const result = await this.service.getBarberModerationList(
      dto.status,
      dto.shopId,
      dto.flaggedOnly,
      dto.limit || 20,
      dto.offset || 0
    );
    return reply.send(result);
  };

  getActiveQueueMonitoring = async (request: FastifyRequest, reply: FastifyReply) => {
    const queues = await this.service.getActiveQueueMonitoring();
    return reply.send({ queues });
  };

  executeModerationAction = async (request: FastifyRequest, reply: FastifyReply) => {
    const dto = moderationActionSchema.parse(request.body);
    const adminId = (request.user as any).id;
    const action: any = {
      targetId: dto.targetId,
      targetType: dto.targetType,
      action: dto.action,
      reason: dto.reason
    };
    if (dto.duration !== undefined) action.duration = dto.duration;
    if (dto.metadata !== undefined) action.metadata = dto.metadata;
    await this.service.executeModerationAction(action, adminId);
    return reply.send({ success: true });
  };
}
