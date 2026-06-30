import type { FastifyReply, FastifyRequest } from "fastify";
import { getAuthUser } from "../../auth/presentation/auth-user.js";
import { cancelBookingSchema, createBookingSchema, scanCheckInSchema } from "../application/booking.schemas.js";
import type { BookingService } from "../application/booking.service.js";

export class BookingController {
  constructor(private readonly service: BookingService) {}

  create = async (request: FastifyRequest, reply: FastifyReply) => {
    const dto = createBookingSchema.parse(request.body);
    const booking = await this.service.createBooking(getAuthUser(request), dto);
    return reply.status(201).send({ booking });
  };

  checkIn = async (request: FastifyRequest, reply: FastifyReply) => {
    const { bookingId } = request.params as { bookingId: string };
    const booking = await this.service.checkIn(getAuthUser(request), bookingId);
    return reply.send({ booking });
  };

  // POST /bookings/check-in/scan  — customer scans the barber's permanent QR code
  scanCheckIn = async (request: FastifyRequest, reply: FastifyReply) => {
    const { token } = scanCheckInSchema.parse(request.body);
    const booking = await this.service.checkInByScan(getAuthUser(request), token);
    return reply.send({ booking });
  };

  startService = async (request: FastifyRequest, reply: FastifyReply) => {
    const { bookingId } = request.params as { bookingId: string };
    const booking = await this.service.startService(getAuthUser(request), bookingId);
    return reply.send({ booking });
  };

  completeService = async (request: FastifyRequest, reply: FastifyReply) => {
    const { bookingId } = request.params as { bookingId: string };
    const booking = await this.service.completeService(getAuthUser(request), bookingId);
    return reply.send({ booking });
  };

  markNoShow = async (request: FastifyRequest, reply: FastifyReply) => {
    const { bookingId } = request.params as { bookingId: string };
    const booking = await this.service.markNoShow(getAuthUser(request), bookingId);
    return reply.send({ booking });
  };

  cancel = async (request: FastifyRequest, reply: FastifyReply) => {
    const { bookingId } = request.params as { bookingId: string };
    const dto = cancelBookingSchema.parse(request.body ?? {});
    const booking = await this.service.cancelBooking(getAuthUser(request), bookingId, dto);
    return reply.send({ booking });
  };

  getOne = async (request: FastifyRequest) => {
    const { bookingId } = request.params as { bookingId: string };
    const booking = await this.service.getBooking(getAuthUser(request), bookingId);
    return { booking };
  };

  listShop = async (request: FastifyRequest) => {
    const { shopId } = request.params as { shopId: string };
    const bookings = await this.service.listShopBookings(getAuthUser(request), shopId);
    return { bookings };
  };

  listMine = async (request: FastifyRequest) => {
    const query = request.query as { status?: string };
    const bookings = await this.service.listUserBookings(getAuthUser(request), query.status);
    return { bookings };
  };

  addReferenceImage = async (request: FastifyRequest, reply: FastifyReply) => {
    const { bookingId } = request.params as { bookingId: string };
    const { url } = (request.body ?? {}) as { url?: string };
    if (!url) return reply.status(400).send({ message: "url is required" });
    const image = await this.service.addReferenceImage(getAuthUser(request), bookingId, url);
    return reply.status(201).send({ image });
  };

  listReferenceImages = async (request: FastifyRequest) => {
    const { bookingId } = request.params as { bookingId: string };
    const images = await this.service.listReferenceImages(getAuthUser(request), bookingId);
    return { images };
  };
}
