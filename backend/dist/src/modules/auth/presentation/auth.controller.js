import { env } from "../../../shared/config/env.js";
import { loginSchema, logoutSchema, refreshSchema, registerSchema } from "../application/auth.schemas.js";
function cookieOptions() {
    const base = {
        httpOnly: true,
        secure: env.COOKIE_SECURE,
        sameSite: env.COOKIE_SAME_SITE,
        path: "/"
    };
    if (env.COOKIE_DOMAIN) {
        base.domain = env.COOKIE_DOMAIN;
    }
    return base;
}
export class AuthController {
    authService;
    constructor(authService) {
        this.authService = authService;
    }
    register = async (request, reply) => {
        const dto = registerSchema.parse(request.body);
        const result = await this.authService.register({
            fullName: dto.fullName,
            email: dto.email,
            password: dto.password,
            role: dto.role,
            ...(dto.phoneNumber !== undefined ? { phoneNumber: dto.phoneNumber } : {})
        });
        this.setCookies(reply, result.tokens);
        return reply.status(201).send({ user: result.user });
    };
    login = async (request, reply) => {
        const dto = loginSchema.parse(request.body);
        const result = await this.authService.login(dto);
        this.setCookies(reply, result.tokens);
        return reply.send({ user: result.user });
    };
    refresh = async (request, reply) => {
        const refreshToken = request.cookies[env.REFRESH_TOKEN_COOKIE_NAME];
        const parsed = refreshSchema.parse(refreshToken !== undefined ? { refreshToken } : {});
        const result = await this.authService.refresh(parsed.refreshToken !== undefined ? { refreshToken: parsed.refreshToken } : {});
        this.setCookies(reply, result.tokens);
        return reply.send({ user: result.user });
    };
    logout = async (request, reply) => {
        const refreshToken = request.cookies[env.REFRESH_TOKEN_COOKIE_NAME];
        const parsed = logoutSchema.parse(refreshToken !== undefined ? { refreshToken } : {});
        await this.authService.logout(parsed.refreshToken !== undefined ? { refreshToken: parsed.refreshToken } : {});
        reply.clearCookie(env.ACCESS_TOKEN_COOKIE_NAME, cookieOptions());
        reply.clearCookie(env.REFRESH_TOKEN_COOKIE_NAME, cookieOptions());
        return reply.send({ ok: true });
    };
    setCookies(reply, tokens) {
        reply.setCookie(env.ACCESS_TOKEN_COOKIE_NAME, tokens.accessToken, {
            ...cookieOptions(),
            maxAge: 60 * 15
        });
        reply.setCookie(env.REFRESH_TOKEN_COOKIE_NAME, tokens.refreshToken, {
            ...cookieOptions(),
            maxAge: 60 * 60 * 24 * 30
        });
    }
}
