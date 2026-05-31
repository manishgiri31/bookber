import type { FastifyReply, FastifyRequest } from "fastify";
import { registerTokenSchema, sendNotificationSchema } from "../application/notification.schemas.js";
import type { NotificationService } from "../application/notification.service.js";

export class NotificationController {
  constructor(private readonly service: NotificationService) {}

  registerToken = async (request: FastifyRequest, reply: FastifyReply) => {
    const dto = registerTokenSchema.parse(request.body);
    const result = await this.service.registerToken(request.user.id, dto);
    return reply.status(201).send({ token: result });
  };

  send = async (request: FastifyRequest, reply: FastifyReply) => {
    const dto = sendNotificationSchema.parse(request.body);
    const result = await this.service.send(dto);
    return reply.send(result);
  };

  deactivateToken = async (request: FastifyRequest, reply: FastifyReply) => {
    const { token } = request.params as { token: string };
    await this.service.deactivateToken(token);
    return reply.send({ ok: true });
  };
}
