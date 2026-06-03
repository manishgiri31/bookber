import type { FastifyReply, FastifyRequest } from "fastify";
import type { PaymentService } from "../application/payment.service.js";

export class PaymentController {
  constructor(private readonly service: PaymentService) { }

  create = async (request: FastifyRequest, reply: FastifyReply) => {
    const dto = request.body as any;
    const payment = await this.service.createPayment(dto);
    return reply.status(201).send({ payment });
  };

  process = async (request: FastifyRequest, reply: FastifyReply) => {
    const dto = request.body as any;
    const payment = await this.service.processPayment(dto);
    return reply.send({ payment });
  };

  refund = async (request: FastifyRequest, reply: FastifyReply) => {
    const dto = request.body as any;
    const payment = await this.service.refundPayment(dto);
    return reply.send({ payment });
  };

  getHistory = async (request: FastifyRequest) => {
    const dto = request.query as any;
    const result = await this.service.getPaymentHistory(dto);
    return result;
  };

  getById = async (request: FastifyRequest, reply: FastifyReply) => {
    const { paymentId } = request.params as { paymentId: string };
    const payment = await this.service.getPaymentById(paymentId);
    return reply.send({ payment });
  };
}
