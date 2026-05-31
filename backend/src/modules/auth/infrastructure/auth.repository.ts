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

  async incrementFailedLoginAttempts(userId: string): Promise<void> {
    await prisma.user.update({
      where: { id: userId },
      data: {
        failedLoginAttempts: {
          increment: 1
        }
      }
    });
  }

  async lockAccount(userId: string, lockDurationMinutes: number): Promise<void> {
    const lockedUntil = new Date(Date.now() + lockDurationMinutes * 60 * 1000);
    await prisma.user.update({
      where: { id: userId },
      data: {
        lockedUntil,
        failedLoginAttempts: {
          increment: 1
        }
      }
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

  async isAccountLocked(userId: string): Promise<boolean> {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { lockedUntil: true }
    });
    if (!user?.lockedUntil) return false;
    return user.lockedUntil > new Date();
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
