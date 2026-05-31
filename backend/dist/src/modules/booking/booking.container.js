import { PrismaBookingRepository } from "./infrastructure/booking.repository.js";
import { BookingService } from "./application/booking.service.js";
export function buildBookingDependencies(engine) {
    const repository = new PrismaBookingRepository();
    const service = new BookingService(repository, engine);
    return { repository, service };
}
export function buildBookingDependenciesFromApp(app) {
    return buildBookingDependencies(app.queueDeps.engine);
}
