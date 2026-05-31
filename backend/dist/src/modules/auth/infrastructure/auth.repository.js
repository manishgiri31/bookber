import { prisma } from "../../../shared/prisma/client.js";
export class PrismaAuthRepository {
    async findByEmail(email) {
        return prisma.user.findUnique({
            where: { email }
        });
    }
    async findByPhoneNumber(phoneNumber) {
        return prisma.user.findUnique({
            where: { phoneNumber }
        });
    }
    async findByIdentifier(identifier) {
        return prisma.user.findFirst({
            where: {
                OR: [{ email: identifier }, { phoneNumber: identifier }]
            }
        });
    }
    async findById(id) {
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
    async createUser(input) {
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
    async incrementFailedLoginAttempts(userId) {
        await prisma.user.update({
            where: { id: userId },
            data: {
                failedLoginAttempts: {
                    increment: 1
                }
            }
        });
    }
    async lockAccount(userId, lockDurationMinutes) {
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
    async resetFailedLoginAttempts(userId) {
        await prisma.user.update({
            where: { id: userId },
            data: {
                failedLoginAttempts: 0,
                lockedUntil: null
            }
        });
    }
    async isAccountLocked(userId) {
        const user = await prisma.user.findUnique({
            where: { id: userId },
            select: { lockedUntil: true }
        });
        if (!user?.lockedUntil)
            return false;
        return user.lockedUntil > new Date();
    }
    async storeRefreshToken(input) {
        return prisma.refreshToken.create({ data: input });
    }
    async findActiveRefreshToken(token) {
        return prisma.refreshToken.findFirst({
            where: { token, revokedAt: null }
        });
    }
    async revokeRefreshToken(token) {
        await prisma.refreshToken.updateMany({
            where: { token, revokedAt: null },
            data: { revokedAt: new Date() }
        });
    }
    async revokeAllUserTokens(userId) {
        await prisma.refreshToken.updateMany({
            where: { userId, revokedAt: null },
            data: { revokedAt: new Date() }
        });
    }
    async rotateRefreshToken(oldToken, newToken) {
        await prisma.$transaction([
            prisma.refreshToken.update({
                where: { token: oldToken },
                data: { revokedAt: new Date() }
            }),
            prisma.refreshToken.create({ data: newToken })
        ]);
    }
}
