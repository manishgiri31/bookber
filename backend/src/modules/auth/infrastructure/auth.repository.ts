import type { RefreshToken, User, UserRole } from "@prisma/client";
import type { AuthUser } from "../domain/auth.types.js";
import { prisma } from "../../../shared/prisma/client.js";

export type CreateUserInput = {
  fullName: string;
  email: string;
  phoneNumber: string | null;
  password: string;
  role: UserRole;
};

export type StoreRefreshTokenInput = {
  userId: string;
  token: string;
  expiresAt: Date;
};

export class PrismaAuthRepository {
  async findByEmail(email: string): Promise<User | null> {
    return prisma.user.findUnique({
      where: { email }
    });
  }

  async findByPhoneNumber(phoneNumber: string): Promise<User | null> {
    return prisma.user.findUnique({
      where: { phoneNumber }
    });
  }

  async findByIdentifier(identifier: string): Promise<User | null> {
    return prisma.user.findFirst({
      where: {
        OR: [{ email: identifier }, { phoneNumber: identifier }]
      }
    });
  }

  async findById(id: string): Promise<AuthUser | null> {
    return prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        fullName: true,
        email: true,
        phoneNumber: true,
        role: true,
        profileImage: true
      }
    });
  }

  async createUser(input: CreateUserInput): Promise<AuthUser> {
    const user = await prisma.user.create({
      data: input,
      select: {
        id: true,
        fullName: true,
        email: true,
        phoneNumber: true,
        role: true,
        profileImage: true
      }
    });
    return user;
  }

  async incrementFailedLoginAttempts(userId: string): Promise<number> {
    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        failedLoginAttempts: {
          increment: 1
        }
      },
      select: { failedLoginAttempts: true }
    });
    return user.failedLoginAttempts;
  }

  async lockAccount(userId: string, lockDurationMinutes: number): Promise<void> {
    const lockedUntil = new Date(Date.now() + lockDurationMinutes * 60 * 1000);
    await prisma.user.update({
      where: { id: userId },
      data: { lockedUntil }
    });
  }

  async resetFailedLoginAttempts(userId: string): Promise<void> {
    await prisma.user.update({
      where: { id: userId },
      data: {
        failedLoginAttempts: 0,
        lockedUntil: null
      }
    });
  }

  async getLockedUntil(userId: string): Promise<Date | null> {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { lockedUntil: true }
    });
    if (!user?.lockedUntil || user.lockedUntil <= new Date()) return null;
    return user.lockedUntil;
  }

  async storeRefreshToken(input: StoreRefreshTokenInput) {
    return prisma.refreshToken.create({ data: input });
  }

  async findActiveRefreshToken(token: string): Promise<RefreshToken | null> {
    return prisma.refreshToken.findFirst({
      where: { token, revokedAt: null }
    });
  }

  async revokeRefreshToken(token: string): Promise<void> {
    await prisma.refreshToken.updateMany({
      where: { token, revokedAt: null },
      data: { revokedAt: new Date() }
    });
  }

  async revokeAllUserTokens(userId: string): Promise<void> {
    await prisma.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() }
    });
  }

  async updatePassword(userId: string, newPasswordHash: string): Promise<void> {
    await prisma.user.update({
      where: { id: userId },
      data: { password: newPasswordHash }
    });
  }

  async updateProfile(userId: string, input: { phoneNumber?: string | null | undefined; fullName?: string | undefined }): Promise<AuthUser> {
    return prisma.user.update({
      where: { id: userId },
      data: {
        ...(input.fullName !== undefined ? { fullName: input.fullName } : {}),
        ...(input.phoneNumber !== undefined ? { phoneNumber: input.phoneNumber } : {}),
      },
      select: {
        id: true,
        fullName: true,
        email: true,
        phoneNumber: true,
        role: true,
        profileImage: true,
      }
    });
  }

  async rotateRefreshToken(oldToken: string, newToken: StoreRefreshTokenInput): Promise<void> {
    await prisma.$transaction([
      prisma.refreshToken.update({
        where: { token: oldToken },
        data: { revokedAt: new Date() }
      }),
      prisma.refreshToken.create({ data: newToken })
    ]);
  }
}

export type AuthRepository = PrismaAuthRepository;
