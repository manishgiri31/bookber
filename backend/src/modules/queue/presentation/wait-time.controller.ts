import type { FastifyReply, FastifyRequest } from "fastify";
import { barberDelaySchema, serviceOverrunSchema } from "../application/wait-time.schemas.js";
import type { WaitTimeEngine } from "../application/wait-time.engine.js";
import { WAIT_RECALC_TRIGGERS } from "../domain/wait-time.types.js";

export class WaitTimeController {
  constructor(private readonly waitTime: WaitTimeEngine) {}

  getEstimates = async (request: FastifyRequest) => {
    const { shopId } = request.params as { shopId: string };
    return this.waitTime.getEstimates(shopId);
  };

  recalculate = async (request: FastifyRequest, reply: FastifyReply) => {
    const { shopId } = request.params as { shopId: string };
    const result = await this.waitTime.recalculateShop(shopId, WAIT_RECALC_TRIGGERS.REBALANCE);
    return reply.send(result);
  };

  reportBarberDelay = async (request: FastifyRequest, reply: FastifyReply) => {
    const { shopId, barberId } = request.params as { shopId: string; barberId: string };
    const dto = barberDelaySchema.parse(request.body);
    await this.waitTime.recordBarberDelay(shopId, barberId, dto.delayMinutes);
    return reply.send({ ok: true });
  };

  reportOverrun = async (request: FastifyRequest, reply: FastifyReply) => {
    const { shopId, barberId } = request.params as { shopId: string; barberId: string };
    const dto = serviceOverrunSchema.parse(request.body);
    await this.waitTime.recordServiceOverrun(shopId, barberId, dto.overrunMinutes);
    return reply.send({ ok: true });
  };
}
