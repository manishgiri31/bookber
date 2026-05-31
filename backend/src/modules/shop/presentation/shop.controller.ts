import type { FastifyReply, FastifyRequest } from "fastify";
import { getAuthUser } from "../../auth/presentation/auth-user.js";
import { createChairSchema, createServiceSchema, createShopSchema, shopSearchSchema, serviceSearchSchema, updateChairSchema, updateServiceSchema, updateShopSchema } from "../application/shop.schemas.js";
import type { ShopService } from "../application/shop.service.js";

export class ShopController {
  constructor(private readonly service: ShopService) { }

  createShop = async (request: FastifyRequest, reply: FastifyReply) => {
    const dto = createShopSchema.parse(request.body);
    const user = getAuthUser(request);
    const result = await this.service.createShop({ id: user.id, role: user.role }, dto);
    return reply.status(201).send({ shop: result });
  };

  updateShop = async (request: FastifyRequest, reply: FastifyReply) => {
    const { shopId } = request.params as { shopId: string };
    const dto = updateShopSchema.parse(request.body);
    const user = getAuthUser(request);
    const result = await this.service.updateShop({ id: user.id, role: user.role }, shopId, dto);
    return reply.send({ shop: result });
  };

  getShop = async (request: FastifyRequest) => {
    const { shopId } = request.params as { shopId: string };
    const result = await this.service.getShop(shopId);
    return { shop: result };
  };

  searchShops = async (request: FastifyRequest) => {
    const dto = shopSearchSchema.parse(request.query);
    const result = await this.service.searchShops(dto);
    return { shops: result.data, pagination: { total: result.total, page: result.page, limit: result.limit, totalPages: result.totalPages } };
  };

  getMyShop = async (request: FastifyRequest) => {
    const user = getAuthUser(request);
    const result = await this.service.getMyShop({ id: user.id, role: user.role });
    return { shop: result };
  };

  createService = async (request: FastifyRequest, reply: FastifyReply) => {
    const { shopId } = request.params as { shopId: string };
    const dto = createServiceSchema.parse(request.body);
    const user = getAuthUser(request);
    const result = await this.service.createService({ id: user.id, role: user.role }, shopId, dto);
    return reply.status(201).send({ service: result });
  };

  updateService = async (request: FastifyRequest, reply: FastifyReply) => {
    const { serviceId } = request.params as { serviceId: string };
    const dto = updateServiceSchema.parse(request.body);
    const user = getAuthUser(request);
    const result = await this.service.updateService({ id: user.id, role: user.role }, serviceId, dto);
    return reply.send({ service: result });
  };

  deleteService = async (request: FastifyRequest, reply: FastifyReply) => {
    const { serviceId } = request.params as { serviceId: string };
    const user = getAuthUser(request);
    const result = await this.service.deleteService({ id: user.id, role: user.role }, serviceId);
    return reply.send({ service: result });
  };

  searchServices = async (request: FastifyRequest) => {
    const { shopId } = request.params as { shopId: string };
    const dto = serviceSearchSchema.parse(request.query);
    const result = await this.service.searchServices(shopId, dto);
    return { services: result.data, pagination: { total: result.total, page: result.page, limit: result.limit, totalPages: result.totalPages } };
  };

  addChair = async (request: FastifyRequest, reply: FastifyReply) => {
    const { shopId } = request.params as { shopId: string };
    const dto = createChairSchema.parse(request.body);
    const user = getAuthUser(request);
    const result = await this.service.addChair({ id: user.id, role: user.role }, shopId, dto);
    return reply.status(201).send({ chair: result });
  };

  updateChair = async (request: FastifyRequest, reply: FastifyReply) => {
    const { chairId } = request.params as { chairId: string };
    const dto = updateChairSchema.parse(request.body);
    const user = getAuthUser(request);
    const result = await this.service.updateChair({ id: user.id, role: user.role }, chairId, dto);
    return reply.send({ chair: result });
  };
}
