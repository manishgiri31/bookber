import type { FastifyReply, FastifyRequest } from "fastify";
import { createServiceSchema, updateServiceSchema } from "./service-management.schemas.js";
import type { ServiceManagementService } from "./service-management.service.js";

export class ServiceManagementController {
  constructor(private readonly service: ServiceManagementService) {}

  addService = async (request: FastifyRequest, reply: FastifyReply) => {
    const { shopId } = request.params as { shopId: string };
    const dto = createServiceSchema.parse(request.body);
    const result = await this.service.addService(request.user, shopId, dto);
    return reply.status(201).send({ service: result });
  };

  updateService = async (request: FastifyRequest, reply: FastifyReply) => {
    const { serviceId } = request.params as { serviceId: string };
    const dto = updateServiceSchema.parse(request.body);
    const result = await this.service.updateService(request.user, serviceId, dto);
    return reply.send({ service: result });
  };

  deleteService = async (request: FastifyRequest, reply: FastifyReply) => {
    const { serviceId } = request.params as { serviceId: string };
    await this.service.deleteService(request.user, serviceId);
    return reply.send({ ok: true });
  };
}
