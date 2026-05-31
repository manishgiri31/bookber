import { registerTokenSchema, sendNotificationSchema } from "../application/notification.schemas.js";
export class NotificationController {
    service;
    constructor(service) {
        this.service = service;
    }
    registerToken = async (request, reply) => {
        const dto = registerTokenSchema.parse(request.body);
        const result = await this.service.registerToken(request.user.id, dto);
        return reply.status(201).send({ token: result });
    };
    send = async (request, reply) => {
        const dto = sendNotificationSchema.parse(request.body);
        const result = await this.service.send(dto);
        return reply.send(result);
    };
    deactivateToken = async (request, reply) => {
        const { token } = request.params;
        await this.service.deactivateToken(token);
        return reply.send({ ok: true });
    };
}
