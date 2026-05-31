import type { FastifyReply, FastifyRequest } from "fastify";
import { getAuthUser } from "../../auth/presentation/auth-user.js";
import { enqueueSchema, rebalanceSchema } from "../application/queue.schemas.js";
import type { QueueCoordinator } from "../application/queue-coordinator.service.js";

export class QueueController {
  constructor(private readonly coordinator: QueueCoordinator) {}

  enqueue = async (request: FastifyRequest, reply: FastifyReply) => {
    const { shopId } = request.params as { shopId: string };
    const dto = enqueueSchema.parse({ ...(request.body as object), shopId });
    const booking = await this.coordinator.enqueue(getAuthUser(request), dto);
    return reply.status(201).send({ booking });
  };

  checkIn = async (request: FastifyRequest, reply: FastifyReply) => {
    const { bookingId } = request.params as { bookingId: string };
    const booking = await this.coordinator.checkIn(getAuthUser(request), bookingId);
    return reply.send({ booking });
  };

  rebalance = async (request: FastifyRequest, reply: FastifyReply) => {
    const { shopId } = request.params as { shopId: string };
    rebalanceSchema.parse(request.body ?? {});
    const queue = await this.coordinator.rebalance(shopId);
    return reply.send({ queue });
  };

  markInService = async (request: FastifyRequest, reply: FastifyReply) => {
    const { bookingId } = request.params as { bookingId: string };
    const booking = await this.coordinator.markInService(getAuthUser(request), bookingId);
    return reply.send({ booking });
  };

  complete = async (request: FastifyRequest, reply: FastifyReply) => {
    const { bookingId } = request.params as { bookingId: string };
    const booking = await this.coordinator.complete(getAuthUser(request), bookingId);
    return reply.send({ booking });
  };

  skip = async (request: FastifyRequest, reply: FastifyReply) => {
    const { bookingId } = request.params as { bookingId: string };
    const booking = await this.coordinator.skip(getAuthUser(request), bookingId);
    return reply.send({ booking });
  };

  list = async (request: FastifyRequest) => {
    const { shopId } = request.params as { shopId: string };
    const queue = await this.coordinator.list(shopId);
    return { queue };
  };
}
