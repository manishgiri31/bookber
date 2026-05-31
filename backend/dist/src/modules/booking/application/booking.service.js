import { Errors } from "../../../shared/http/app-error.js";
import { prisma } from "../../../shared/prisma/client.js";
export class BookingService {
    repository;
    queueEngine;
    constructor(repository, queueEngine) {
        this.repository = repository;
        this.queueEngine = queueEngine;
    }
    async createBooking(user, dto) {
        if (!["CLIENT", "BARBER", "ADMIN"].includes(user.role)) {
            throw Errors.forbidden();
        }
        const existing = await this.repository.findActiveBookingForUser(prisma, user.id, dto.shopId);
        if (existing && !dto.walkIn) {
            throw Errors.conflict("You already have an active queue reservation at this shop");
        }
        return this.queueEngine.reserveQueue(user, {
            shopId: dto.shopId,
            serviceId: dto.serviceId,
            userId: user.id,
            barberId: dto.barberId,
            walkIn: dto.walkIn
        });
    }
    async checkIn(user, bookingId) {
        return this.queueEngine.checkIn(user, bookingId);
    }
    async startService(user, bookingId) {
        return this.queueEngine.startService(user, bookingId);
    }
    async completeService(user, bookingId) {
        return this.queueEngine.completeService(user, bookingId);
    }
    async cancelBooking(user, bookingId, dto) {
        return this.queueEngine.cancelBooking(user, bookingId, dto.reason);
    }
    async markNoShow(user, bookingId) {
        return this.queueEngine.markNoShow(user, bookingId);
    }
    async getBooking(user, bookingId) {
        const booking = await this.repository.findBookingById(prisma, bookingId);
        if (!booking)
            throw Errors.notFound("Booking not found");
        if (user.role !== "ADMIN" && user.id !== booking.userId && booking.barber?.userId !== user.id) {
            throw Errors.forbidden();
        }
        return booking;
    }
    async listShopBookings(user, shopId) {
        const bookings = await this.repository.findActiveBookingsForShop(prisma, shopId);
        if (user.role === "ADMIN")
            return bookings;
        return bookings.filter((b) => b.userId === user.id || b.barber?.userId === user.id);
    }
}
