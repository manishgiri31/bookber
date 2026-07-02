import type { CookieSerializeOptions } from "@fastify/cookie";
import type { FastifyReply, FastifyRequest } from "fastify";
import { env } from "../../../shared/config/env.js";
import { loginSchema, logoutSchema, refreshSchema, registerSchema, updateProfileSchema } from "../application/auth.schemas.js";
import type { AuthService } from "../application/auth.service.js";

function cookieOptions(): CookieSerializeOptions {
  const base: CookieSerializeOptions = {
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
  constructor(private readonly authService: AuthService) {}

  register = async (request: FastifyRequest, reply: FastifyReply) => {
    const dto = registerSchema.parse(request.body);
    const result = await this.authService.register({
      fullName: dto.fullName,
      email: dto.email,
      password: dto.password,
      role: dto.role,
      ...(dto.phoneNumber !== undefined ? { phoneNumber: dto.phoneNumber } : {})
    });
    this.setCookies(reply, result.tokens);
    return reply.status(201).send({
      user: result.user,
      accessToken: result.tokens.accessToken,
      refreshToken: result.tokens.refreshToken,
    });
  };

  login = async (request: FastifyRequest, reply: FastifyReply) => {
    const dto = loginSchema.parse(request.body);
    const result = await this.authService.login(dto);
    this.setCookies(reply, result.tokens);
    return reply.send({
      user: result.user,
      accessToken: result.tokens.accessToken,
      refreshToken: result.tokens.refreshToken,
    });
  };

  refresh = async (request: FastifyRequest, reply: FastifyReply) => {
    // Accept refresh token from cookie (web) OR request body (mobile).
    // Mobile clients (Flutter/React Native) cannot set cookies, so they send
    // the refresh token in the JSON body instead.
    const cookieToken = request.cookies[env.REFRESH_TOKEN_COOKIE_NAME];
    const bodyToken = (request.body as Record<string, unknown> | null | undefined)?.refreshToken;
    const rawToken = cookieToken ?? (typeof bodyToken === "string" ? bodyToken : undefined);
    const parsed = refreshSchema.parse(
      rawToken !== undefined ? { refreshToken: rawToken } : {}
    );
    const result = await this.authService.refresh(
      parsed.refreshToken !== undefined ? { refreshToken: parsed.refreshToken } : {}
    );
    this.setCookies(reply, result.tokens);
    return reply.send({
      user: result.user,
      accessToken: result.tokens.accessToken,
      refreshToken: result.tokens.refreshToken,
    });
  };

  logout = async (request: FastifyRequest, reply: FastifyReply) => {
    // Same cookie-or-body fallback so mobile clients can properly revoke tokens.
    const cookieToken = request.cookies[env.REFRESH_TOKEN_COOKIE_NAME];
    const bodyToken = (request.body as Record<string, unknown> | null | undefined)?.refreshToken;
    const rawToken = cookieToken ?? (typeof bodyToken === "string" ? bodyToken : undefined);
    const parsed = logoutSchema.parse(
      rawToken !== undefined ? { refreshToken: rawToken } : {}
    );
    await this.authService.logout(
      parsed.refreshToken !== undefined ? { refreshToken: parsed.refreshToken } : {}
    );
    reply.clearCookie(env.ACCESS_TOKEN_COOKIE_NAME, cookieOptions());
    reply.clearCookie(env.REFRESH_TOKEN_COOKIE_NAME, cookieOptions());
    return reply.send({ ok: true });
  };

  updateMe = async (request: FastifyRequest, reply: FastifyReply) => {
    const dto = updateProfileSchema.parse(request.body);
    const user = await this.authService.updateProfile(request.user.sub, dto);
    return reply.send({ user });
  };

  changePassword = async (request: FastifyRequest, reply: FastifyReply) => {
    const { currentPassword, newPassword } = (request.body as { currentPassword: string; newPassword: string }) ?? {};
    if (!currentPassword || !newPassword) {
      return reply.status(400).send({ message: "currentPassword and newPassword are required" });
    }
    await this.authService.changePassword(request.user.sub, { currentPassword, newPassword });
    return reply.send({ ok: true });
  };

  private setCookies(reply: FastifyReply, tokens: { accessToken: string; refreshToken: string }) {
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
