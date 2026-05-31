import { AuthService } from "./application/auth.service.js";
import { PrismaAuthRepository } from "./infrastructure/auth.repository.js";
import { TokenService } from "./infrastructure/token.service.js";
export function buildAuthDependencies(app) {
    const repository = new PrismaAuthRepository();
    const tokenService = new TokenService(app);
    const authService = new AuthService(app, repository, tokenService);
    return {
        repository,
        tokenService,
        authService
    };
}
