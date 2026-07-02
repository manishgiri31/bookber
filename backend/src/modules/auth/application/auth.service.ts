import bcrypt from "bcrypt";
import crypto from "node:crypto";
import type { FastifyInstance } from "fastify";
import type { UserRole } from "@prisma/client";
import { env } from "../../../shared/config/env.js";
import { Errors } from "../../../shared/http/app-error.js";
import type { AuthSession, AuthUser, TokenPair } from "../domain/auth.types.js";
import type { AuthRepository } from "../infrastructure/auth.repository.js";
import type { TokenService } from "../infrastructure/token.service.js";

const MAX_FAILED_LOGIN_ATTEMPTS = 5;
const ACCOUNT_LOCK_DURATION_MINUTES = 15;

function randomJti() {
  return crypto.randomUUID();
}

export class AuthService {
  constructor(
    private readonly app: FastifyInstance,
    private readonly repository: AuthRepository,
    private readonly tokens: TokenService
  ) { }

  async register(input: { fullName: string; email: string; phoneNumber?: string; password: string; role: UserRole }) {
    const existingByEmail = await this.repository.findByEmail(input.email);
    if (existingByEmail) throw Errors.conflict("Email already registered");

    if (input.phoneNumber) {
      const existingByPhone = await this.repository.findByPhoneNumber(input.phoneNumber);
      if (existingByPhone) throw Errors.conflict("Phone number already registered");
    }

    const passwordHash = await bcrypt.hash(input.password, env.PASSWORD_BCRYPT_ROUNDS);
    const user = await this.repository.createUser({
      fullName: input.fullName,
      email: input.email,
      phoneNumber: input.phoneNumber ?? null,
      password: passwordHash,
      role: input.role
    });

    return this.issueTokens(user);
  }

  async login(input: { identifier: string; password: string }) {
    const user = await this.repository.findByIdentifier(input.identifier);
    if (!user) {
      throw Errors.unauthenticated("Invalid email or password");
    }

    const lockedUntil = await this.repository.getLockedUntil(user.id);
    if (lockedUntil) {
      const minutesRemaining = Math.ceil((lockedUntil.getTime() - Date.now()) / 60_000);
      throw Errors.forbidden(
        `Account temporarily locked due to too many failed login attempts. Try again in ${minutesRemaining} minute(s).`
      );
    }

    const passwordMatch = await bcrypt.compare(input.password, user.password);
    if (!passwordMatch) {
      await this.handleFailedLogin(user.id);
      throw Errors.unauthenticated("Invalid email or password");
    }

    await this.repository.resetFailedLoginAttempts(user.id);

    const authUser = await this.repository.findById(user.id);
    if (!authUser) throw Errors.unauthenticated("Invalid email or password");

    return this.issueTokens(authUser);
  }

  async refresh(input: { refreshToken?: string }) {
    const token = input.refreshToken;
    if (!token) throw Errors.unauthenticated();

    const record = await this.repository.findActiveRefreshToken(token);
    if (!record) throw Errors.unauthenticated();
    if (record.expiresAt.getTime() < Date.now()) throw Errors.unauthenticated();

    const user = await this.repository.findById(record.userId);
    if (!user) throw Errors.unauthenticated();

    return this.rotateRefreshToken(user, token);
  }

  async getMe(userId: string): Promise<AuthUser> {
    const user = await this.repository.findById(userId);
    if (!user) throw Errors.unauthenticated();
    return user;
  }

  async logout(input: { refreshToken?: string }) {
    if (!input.refreshToken) return;
    await this.repository.revokeRefreshToken(input.refreshToken);
  }

  async updateProfile(userId: string, input: { phoneNumber?: string | null | undefined; fullName?: string | undefined }): Promise<AuthUser> {
    if (input.phoneNumber) {
      const existing = await this.repository.findByPhoneNumber(input.phoneNumber);
      if (existing && existing.id !== userId) throw Errors.conflict("Phone number already registered");
    }
    return this.repository.updateProfile(userId, input);
  }

  async changePassword(userId: string, input: { currentPassword: string; newPassword: string }) {
    const authUser = await this.repository.findById(userId);
    if (!authUser) throw Errors.unauthenticated();
    const fullUser = await this.repository.findByEmail(authUser.email);
    if (!fullUser) throw Errors.unauthenticated();
    const match = await bcrypt.compare(input.currentPassword, fullUser.password);
    if (!match) throw Errors.unauthenticated("Current password is incorrect");
    const newHash = await bcrypt.hash(input.newPassword, env.PASSWORD_BCRYPT_ROUNDS);
    await this.repository.updatePassword(userId, newHash);
  }

  private async handleFailedLogin(userId: string) {
    const attempts = await this.repository.incrementFailedLoginAttempts(userId);
    if (attempts >= MAX_FAILED_LOGIN_ATTEMPTS) {
      await this.repository.lockAccount(userId, ACCOUNT_LOCK_DURATION_MINUTES);
    }
  }

  private async issueTokens(user: AuthUser): Promise<{ user: AuthUser; tokens: TokenPair }> {
    const sessionId = crypto.randomUUID();
    const accessJti = randomJti();
    const refreshJti = randomJti();
    const familyId = randomJti();
    const refreshToken = await this.tokens.signRefreshToken({
      sub: user.id,
      jti: refreshJti,
      sid: sessionId,
      fam: familyId
    });

    await this.repository.storeRefreshToken({
      userId: user.id,
      token: refreshToken,
      expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 30)
    });

    await this.writeSession({
      userId: user.id,
      familyId,
      refreshJti,
      role: user.role
    }, sessionId);

    const accessToken = await this.tokens.signAccessToken({
      sub: user.id,
      role: user.role,
      jti: accessJti,
      sid: sessionId
    });

    return {
      user,
      tokens: {
        accessToken,
        refreshToken,
        refreshJti,
        refreshFamilyId: familyId,
        sessionId
      }
    };
  }

  private async rotateRefreshToken(user: AuthUser, oldToken: string) {
    const sessionId = crypto.randomUUID();
    const refreshJti = randomJti();
    const familyId = randomJti();
    const refreshToken = await this.tokens.signRefreshToken({
      sub: user.id,
      jti: refreshJti,
      sid: sessionId,
      fam: familyId
    });

    await this.repository.rotateRefreshToken(oldToken, {
      userId: user.id,
      token: refreshToken,
      expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 30)
    });

    await this.writeSession(
      {
        userId: user.id,
        familyId,
        refreshJti,
        role: user.role
      },
      sessionId
    );

    const accessToken = await this.tokens.signAccessToken({
      sub: user.id,
      role: user.role,
      jti: randomJti(),
      sid: sessionId
    });

    return {
      user,
      tokens: {
        accessToken,
        refreshToken,
        refreshJti,
        refreshFamilyId: familyId,
        sessionId
      }
    };
  }

  private async writeSession(session: AuthSession, sessionId: string) {
    const redis = this.app.redis;
    if (!redis) return;
    const ttlSeconds = env.JWT_REFRESH_TTL.endsWith("d")
      ? Number.parseInt(env.JWT_REFRESH_TTL, 10) * 24 * 60 * 60
      : 30 * 24 * 60 * 60;
    await redis.set(`auth:session:${sessionId}`, JSON.stringify(session), "EX", ttlSeconds);
  }

  private async readSession(sessionId: string) {
    const redis = this.app.redis;
    if (!redis) return null;
    const raw = await redis.get(`auth:session:${sessionId}`);
    return raw ? (JSON.parse(raw) as AuthSession) : null;
  }

  private async deleteSession(sessionId: string) {
    const redis = this.app.redis;
    if (!redis) return;
    await redis.del(`auth:session:${sessionId}`);
  }
}
