import { PrismaServiceManagementRepository } from "./service-management.repository.js";
import { ServiceManagementService } from "./service-management.service.js";

export function buildServiceManagementDependencies() {
  const repository = new PrismaServiceManagementRepository();
  const service = new ServiceManagementService(repository);

  return { repository, service };
}

declare module "fastify" {
  interface FastifyInstance {
    serviceDeps: ReturnType<typeof buildServiceManagementDependencies>;
  }
}
