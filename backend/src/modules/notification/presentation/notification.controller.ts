import type { FastifyReply, FastifyRequest } from "fastify";
import { registerTokenSchema, sendNotificationSchema } from "../application/notification.schemas.js";
import type { NotificationService } from "../application/notification.service.js";
import { getAuthUser } from "../../auth/presentation/auth-user.js";

export class NotificationController {
  constructor(private readonly service: NotificationService) {}

  registerToken = async (request: FastifyRequest, reply: FastifyReply) => {
    const dto = registerTokenSchema.parse(request.body);
    const userId = getAuthUser(request).id;
    const tokenInput: { token: string; platform?: string; deviceId?: string } = { token: dto.token };
    if (dto.platform !== undefined) tokenInput.platform = dto.platform;
    if (dto.deviceId !== undefined) tokenInput.deviceId = dto.deviceId;
    const result = await this.service.registerToken(userId, tokenInput);
    return reply.status(201).send({ token: result });
  };

  send = async (request: FastifyRequest, reply: FastifyReply) => {
    const dto = sendNotificationSchema.parse(request.body);
    const payload: Parameters<NotificationService["send"]>[0] = {
      userId: dto.userId,
      type: dto.type,
      title: dto.title,
      body: dto.body,
    };
    if (dto.data !== undefined) payload.data = dto.data as Record<string, string>;
    const result = await this.service.send(payload);
    return reply.send(result);
  };

  deactivateToken = async (request: FastifyRequest, reply: FastifyReply) => {
    const { token } = request.params as { token: string };
    await this.service.deactivateToken(token);
    return reply.send({ ok: true });
  };
}
