import { PrismaClient } from "@prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";
import { createModuleLogger } from "../../infrastructure/logging/structured-logger.js";
import { observeDatabaseQuery } from "../../infrastructure/metrics/prometheus.js";
import { env } from "../config/index.js";

const log = createModuleLogger("prisma");
const adapter = new PrismaPg({ connectionString: env.DATABASE_URL });

export const prisma = new PrismaClient({
  adapter,
  log: [
    { emit: "event", level: "error" },
    { emit: "event", level: "warn" },
    { emit: "event", level: "query" }
  ]
});

prisma.$on("error", (event) => {
  log.error({ prisma: event }, "prisma error");
});

prisma.$on("warn", (event) => {
  log.warn({ prisma: event }, "prisma warning");
});

prisma.$on("query", (event) => {
  observeDatabaseQuery("sql", "query", event.duration / 1000);
});

export type AppPrismaClient = typeof prisma;
