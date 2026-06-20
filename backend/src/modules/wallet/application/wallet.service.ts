import type { PrismaWalletRepository } from "../infrastructure/wallet.repository.js";

export class WalletService {
  constructor(private readonly repo: PrismaWalletRepository) {}

  async getWallet(userId: string) {
    return this.repo.getOrCreate(userId);
  }

  async topUp(userId: string, amount: number, refId: string) {
    if (amount <= 0) throw new Error("Amount must be positive");
    return this.repo.credit(userId, amount, "Wallet top-up", refId);
  }

  async getTransactions(userId: string) {
    return this.repo.getTransactions(userId);
  }

  async credit(userId: string, amount: number, reason: string, refId?: string) {
    return this.repo.credit(userId, amount, reason, refId);
  }

  async debit(userId: string, amount: number, reason: string, refId?: string) {
    return this.repo.debit(userId, amount, reason, refId);
  }
}
