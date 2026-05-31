import { getAuthUser } from "../../auth/presentation/auth-user.js";
import { cancelBookingSchema, createBookingSchema } from "../application/booking.schemas.js";
export class BookingController {
    service;
    constructor(service) {
        this.service = service;
    }
    create = async (request, reply) => {
        const dto = createBookingSchema.parse(request.body);
        const booking = await this.service.createBooking(getAuthUser(request), dto);
        return reply.status(201).send({ booking });
    };
    checkIn = async (request, reply) => {
        const { bookingId } = request.params;
        const booking = await this.service.checkIn(getAuthUser(request), bookingId);
        return reply.send({ booking });
    };
    startService = async (request, reply) => {
        const { bookingId } = request.params;
        const booking = await this.service.startService(getAuthUser(request), bookingId);
        return reply.send({ booking });
    };
    completeService = async (request, reply) => {
        const { bookingId } = request.params;
        const booking = await this.service.completeService(getAuthUser(request), bookingId);
        return reply.send({ booking });
    };
    markNoShow = async (request, reply) => {
        const { bookingId } = request.params;
        const booking = await this.service.markNoShow(getAuthUser(request), bookingId);
        return reply.send({ booking });
    };
    cancel = async (request, reply) => {
        const { bookingId } = request.params;
        const dto = cancelBookingSchema.parse(request.body ?? {});
        const booking = await this.service.cancelBooking(getAuthUser(request), bookingId, dto);
        return reply.send({ booking });
    };
    getOne = async (request) => {
        const { bookingId } = request.params;
        const booking = await this.service.getBooking(getAuthUser(request), bookingId);
        return { booking };
    };
    listShop = async (request) => {
        const { shopId } = request.params;
        const bookings = await this.service.listShopBookings(getAuthUser(request), shopId);
        return { bookings };
    };
}
