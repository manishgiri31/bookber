import { PrismaGeolocationRepository } from "./infrastructure/geolocation.repository.js";
import { GeolocationService } from "./application/geolocation.service.js";
export function buildGeolocationDependencies(app) {
    const repository = new PrismaGeolocationRepository();
    const service = new GeolocationService(repository);
    return { repository, service };
}
