import { getAuthUser } from "../../auth/presentation/auth-user.js";
import { enqueueSchema, rebalanceSchema } from "../application/queue.schemas.js";
export class QueueController {
    coordinator;
    constructor(coordinator) {
        this.coordinator = coordinator;
    }
    enqueue = async (request, reply) => {
        const { shopId } = request.params;
        const dto = enqueueSchema.parse({ ...request.body, shopId });
        const booking = await this.coordinator.enqueue(getAuthUser(request), dto);
        return reply.status(201).send({ booking });
    };
    checkIn = async (request, reply) => {
        const { bookingId } = request.params;
        const booking = await this.coordinator.checkIn(getAuthUser(request), bookingId);
        return reply.send({ booking });
    };
    rebalance = async (request, reply) => {
        const { shopId } = request.params;
        rebalanceSchema.parse(request.body ?? {});
        const queue = await this.coordinator.rebalance(shopId);
        return reply.send({ queue });
    };
    markInService = async (request, reply) => {
        const { bookingId } = request.params;
        const booking = await this.coordinator.markInService(getAuthUser(request), bookingId);
        return reply.send({ booking });
    };
    complete = async (request, reply) => {
        const { bookingId } = request.params;
        const booking = await this.coordinator.complete(getAuthUser(request), bookingId);
        return reply.send({ booking });
    };
    skip = async (request, reply) => {
        const { bookingId } = request.params;
        const booking = await this.coordinator.skip(getAuthUser(request), bookingId);
        return reply.send({ booking });
    };
    list = async (request) => {
        const { shopId } = request.params;
        const queue = await this.coordinator.list(shopId);
        return { queue };
    };
}
