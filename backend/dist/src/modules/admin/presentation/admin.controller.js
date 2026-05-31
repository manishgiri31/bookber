import { barberListFilterSchema, moderationActionSchema } from "../application/admin.schemas.js";
export class AdminController {
    service;
    constructor(service) {
        this.service = service;
    }
    getDashboard = async (request, reply) => {
        const { fromDate, toDate } = request.query;
        const from = fromDate ? new Date(fromDate) : undefined;
        const to = toDate ? new Date(toDate) : undefined;
        const dashboard = await this.service.getDashboard(from, to);
        return reply.send(dashboard);
    };
    getAnalyticsOverview = async (request, reply) => {
        const { fromDate, toDate } = request.query;
        const from = fromDate ? new Date(fromDate) : undefined;
        const to = toDate ? new Date(toDate) : undefined;
        const analytics = await this.service.getAnalyticsOverview(from, to);
        return reply.send(analytics);
    };
    getBookingAnalytics = async (request, reply) => {
        const { fromDate, toDate, shopId } = request.query;
        const from = fromDate ? new Date(fromDate) : undefined;
        const to = toDate ? new Date(toDate) : undefined;
        const analytics = await this.service.getBookingAnalytics(from, to, shopId);
        return reply.send(analytics);
    };
    getEarningsOverview = async (request, reply) => {
        const { fromDate, toDate } = request.query;
        const from = fromDate ? new Date(fromDate) : undefined;
        const to = toDate ? new Date(toDate) : undefined;
        const earnings = await this.service.getEarningsOverview(from, to);
        return reply.send(earnings);
    };
    getBarberModerationList = async (request, reply) => {
        const { status, shopId, flaggedOnly, limit, offset } = request.query;
        const dto = barberListFilterSchema.parse({
            status,
            shopId,
            flaggedOnly: flaggedOnly === "true",
            limit: limit ? parseInt(limit) : undefined,
            offset: offset ? parseInt(offset) : undefined
        });
        const result = await this.service.getBarberModerationList(dto.status, dto.shopId, dto.flaggedOnly, dto.limit || 20, dto.offset || 0);
        return reply.send(result);
    };
    getActiveQueueMonitoring = async (request, reply) => {
        const queues = await this.service.getActiveQueueMonitoring();
        return reply.send({ queues });
    };
    executeModerationAction = async (request, reply) => {
        const dto = moderationActionSchema.parse(request.body);
        const adminId = request.user.id;
        const action = {
            targetId: dto.targetId,
            targetType: dto.targetType,
            action: dto.action,
            reason: dto.reason
        };
        if (dto.duration !== undefined)
            action.duration = dto.duration;
        if (dto.metadata !== undefined)
            action.metadata = dto.metadata;
        await this.service.executeModerationAction(action, adminId);
        return reply.send({ success: true });
    };
}
