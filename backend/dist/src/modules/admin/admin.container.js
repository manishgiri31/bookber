import { PrismaAdminRepository } from "./infrastructure/admin.repository.js";
import { AdminService } from "./application/admin.service.js";
export function buildAdminDependencies(app) {
    const repository = new PrismaAdminRepository();
    const service = new AdminService(repository);
    return { repository, service };
}
