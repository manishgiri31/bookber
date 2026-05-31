import { barberDelaySchema, serviceOverrunSchema } from "../application/wait-time.schemas.js";
import { WAIT_RECALC_TRIGGERS } from "../domain/wait-time.types.js";
export class WaitTimeController {
    waitTime;
    constructor(waitTime) {
        this.waitTime = waitTime;
    }
    getEstimates = async (request) => {
        const { shopId } = request.params;
        return this.waitTime.getEstimates(shopId);
    };
    recalculate = async (request, reply) => {
        const { shopId } = request.params;
        const result = await this.waitTime.recalculateShop(shopId, WAIT_RECALC_TRIGGERS.REBALANCE);
        return reply.send(result);
    };
    reportBarberDelay = async (request, reply) => {
        const { shopId, barberId } = request.params;
        const dto = barberDelaySchema.parse(request.body);
        await this.waitTime.recordBarberDelay(shopId, barberId, dto.delayMinutes);
        return reply.send({ ok: true });
    };
    reportOverrun = async (request, reply) => {
        const { shopId, barberId } = request.params;
        const dto = serviceOverrunSchema.parse(request.body);
        await this.waitTime.recordServiceOverrun(shopId, barberId, dto.overrunMinutes);
        return reply.send({ ok: true });
    };
}
