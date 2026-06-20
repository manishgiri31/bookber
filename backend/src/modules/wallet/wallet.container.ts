import { PrismaWalletRepository } from "./infrastructure/wallet.repository.js";
import { WalletService } from "./application/wallet.service.js";

export interface WalletDependencies {
  repo: PrismaWalletRepository;
  service: WalletService;
}

export function buildWalletDependencies(): WalletDependencies {
  const repo = new PrismaWalletRepository();
  const service = new WalletService(repo);
  return { repo, service };
}
