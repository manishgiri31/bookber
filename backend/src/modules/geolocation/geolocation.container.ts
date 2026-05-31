import { PrismaGeolocationRepository } from "./infrastructure/geolocation.repository.js";
import { GeolocationService } from "./application/geolocation.service.js";
import type { FastifyInstance } from "fastify";

export function buildGeolocationDependencies(app: FastifyInstance) {
  const repository = new PrismaGeolocationRepository();
  const service = new GeolocationService(repository);

  return { repository, service };
}

declare module "fastify" {
  interface FastifyInstance {
    geoDeps: ReturnType<typeof buildGeolocationDependencies>;
  }
}
