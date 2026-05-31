import { PrismaAdminRepository } from "./infrastructure/admin.repository.js";
import { AdminService } from "./application/admin.service.js";
import type { FastifyInstance } from "fastify";

export function buildAdminDependencies(app: FastifyInstance) {
  const repository = new PrismaAdminRepository();
  const service = new AdminService(repository);

  return { repository, service };
}

declare module "fastify" {
  interface FastifyInstance {
    adminDeps: ReturnType<typeof buildAdminDependencies>;
  }
}
