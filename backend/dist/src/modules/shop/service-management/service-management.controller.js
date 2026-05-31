import { createServiceSchema, updateServiceSchema } from "./service-management.schemas.js";
export class ServiceManagementController {
    service;
    constructor(service) {
        this.service = service;
    }
    addService = async (request, reply) => {
        const { shopId } = request.params;
        const dto = createServiceSchema.parse(request.body);
        const result = await this.service.addService(request.user, shopId, dto);
        return reply.status(201).send({ service: result });
    };
    updateService = async (request, reply) => {
        const { serviceId } = request.params;
        const dto = updateServiceSchema.parse(request.body);
        const result = await this.service.updateService(request.user, serviceId, dto);
        return reply.send({ service: result });
    };
    deleteService = async (request, reply) => {
        const { serviceId } = request.params;
        await this.service.deleteService(request.user, serviceId);
        return reply.send({ ok: true });
    };
}
