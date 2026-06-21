import { prisma } from "../../../shared/prisma/client.js";

export class PrismaWalletRepository {
  async getOrCreate(userId: string) {
    return prisma.wallet.upsert({
      where: { userId },
      create: { userId, balance: 0 },
      update: {},
      include: { transactions: { orderBy: { createdAt: "desc" }, take: 20 } },
    });
  }

  async getBalance(userId: string): Promise<number> {
    const wallet = await prisma.wallet.findUnique({ where: { userId } });
    return wallet?.balance ?? 0;
  }

  async credit(userId: string, amount: number, reason: string, refId?: string) {
    const wallet = await this.getOrCreate(userId);
    return prisma.$transaction([
      prisma.wallet.update({
        where: { id: wallet.id },
        data: { balance: { increment: amount } },
      }),
      prisma.walletTransaction.create({
        data: {
          walletId: wallet.id,
          amount,
          type: "CREDIT",
          reason,
          ...(refId !== undefined && { refId }),
        },
      }),
    ]);
  }

  async debit(userId: string, amount: number, reason: string, refId?: string) {
    const wallet = await this.getOrCreate(userId);
    if (wallet.balance < amount) throw new Error("Insufficient wallet balance");
    return prisma.$transaction([
      prisma.wallet.update({
        where: { id: wallet.id },
        data: { balance: { decrement: amount } },
      }),
      prisma.walletTransaction.create({
        data: {
          walletId: wallet.id,
          amount,
          type: "DEBIT",
          reason,
          ...(refId !== undefined && { refId }),
        },
      }),
    ]);
  }

  async getTransactions(userId: string) {
    const wallet = await prisma.wallet.findUnique({ where: { userId } });
    if (!wallet) return [];
    return prisma.walletTransaction.findMany({
      where: { walletId: wallet.id },
      orderBy: { createdAt: "desc" },
      take: 50,
    });
  }
}
