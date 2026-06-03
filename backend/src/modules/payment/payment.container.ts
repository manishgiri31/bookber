import type { FastifyInstance } from "fastify";
import { PrismaPaymentRepository } from "./infrastructure/payment.repository.js";
import { PaymentService } from "./application/payment.service.js";

export function buildPaymentDependencies(app: FastifyInstance) {
  const repository = new PrismaPaymentRepository(app.prisma);
  const service = new PaymentService(repository);

  return { repository, service };
}

declare module "fastify" {
  interface FastifyInstance {
    paymentDeps: ReturnType<typeof buildPaymentDependencies>;
  }
}
