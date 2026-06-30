import { Errors } from "../../../shared/http/app-error.js";
import type { AuthUser } from "../../auth/domain/auth.types.js";
import type { QueueEngineService } from "../../queue/application/queue-engine.service.js";
import type { CreateBookingDto, CancelBookingDto } from "./booking.schemas.js";
import type { PrismaBookingRepository } from "../infrastructure/booking.repository.js";
import type { BookingCompletionCascade } from "./booking-completion.cascade.js";
import { prisma } from "../../../shared/prisma/client.js";

export class BookingService {
  constructor(
    private readonly repository: PrismaBookingRepository,
    private readonly queueEngine: QueueEngineService,
    private readonly cascade?: BookingCompletionCascade
  ) {}

  async createBooking(user: AuthUser, dto: CreateBookingDto) {
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

  async checkIn(user: AuthUser, bookingId: string) {
    return this.queueEngine.checkIn(user, bookingId);
  }

  async checkInByScan(user: AuthUser, token: string) {
    return this.queueEngine.checkInByScan(user, token);
  }

  async startService(user: AuthUser, bookingId: string) {
    return this.queueEngine.startService(user, bookingId);
  }

  async completeService(user: AuthUser, bookingId: string) {
    const booking = await this.queueEngine.completeService(user, bookingId);

    // Run the post-commit cascade (invoice, loyalty, review prompt, next-customer push).
    // This is fire-and-forget: a cascade failure must never surface to the barber.
    if (this.cascade) {
      const bookingWithDetails = await prisma.booking.findUnique({
        where: { id: booking.id },
        include: {
          service: { select: { price: true, name: true } },
          shop: { select: { name: true } }
        }
      });
      if (bookingWithDetails) {
        this.cascade.run(bookingWithDetails).catch((err: unknown) => {
          console.error("[cascade]", bookingId, err);
        });
      }
    }

    return booking;
  }

  async cancelBooking(user: AuthUser, bookingId: string, dto: CancelBookingDto) {
    return this.queueEngine.cancelBooking(user, bookingId, dto.reason);
  }

  async markNoShow(user: AuthUser, bookingId: string) {
    return this.queueEngine.markNoShow(user, bookingId);
  }

  async getBooking(user: AuthUser, bookingId: string) {
    const booking = await this.repository.findBookingById(prisma, bookingId);
    if (!booking) throw Errors.notFound("Booking not found");
    if (user.role !== "ADMIN" && user.id !== booking.userId && booking.barber?.userId !== user.id) {
      throw Errors.forbidden();
    }
    return booking;
  }

  async listShopBookings(user: AuthUser, shopId: string) {
    const bookings = await this.repository.findActiveBookingsForShop(prisma, shopId);
    if (user.role === "ADMIN") return bookings;
    // Shop owners see all bookings; barber employees see their own assignments
    const isOwner = await prisma.shop.findFirst({ where: { id: shopId, ownerId: user.id } });
    if (isOwner) return bookings;
    return bookings.filter((b) => b.barber?.userId === user.id);
  }

  async listUserBookings(user: AuthUser, status?: string) {
    return this.repository.findBookingsByUserId(prisma, user.id, status);
  }
}
