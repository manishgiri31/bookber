import { prisma } from "../../../shared/prisma/client.js";
import type { ReviewDTO, CreateReviewRequest } from "../domain/review.types.js";

export class PrismaReviewRepository {

  async create(data: CreateReviewRequest, userId: string): Promise<ReviewDTO> {
    const booking = await prisma.booking.findUnique({
      where: { id: data.bookingId },
      select: { id: true, userId: true, shopId: true, status: true }
    });
    if (!booking) throw new Error("Booking not found");
    if (booking.userId !== userId) throw new Error("Not your booking");
    if (booking.status !== "COMPLETED") throw new Error("Booking is not completed yet");

    const existing = await prisma.review.findUnique({
      where: { bookingId: data.bookingId }
    });
    if (existing) {
      throw new Error("Booking already reviewed");
    }

    const review = await prisma.review.create({
      data: {
        userId,
        shopId: booking.shopId,
        bookingId: booking.id,
        rating: data.rating,
        comment: data.comment || null
      }
    });

    return this.toDTO(review);
  }

  async findByShopId(shopId: string): Promise<ReviewDTO[]> {
    const reviews = await prisma.review.findMany({
      where: { shopId },
      orderBy: { createdAt: "desc" }
    });

    return reviews.map(r => this.toDTO(r));
  }

  async findByUserId(userId: string): Promise<ReviewDTO[]> {
    const reviews = await prisma.review.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" }
    });

    return reviews.map(r => this.toDTO(r));
  }

  private toDTO(review: any): ReviewDTO {
    return {
      id: review.id,
      userId: review.userId,
      shopId: review.shopId,
      bookingId: review.bookingId,
      rating: review.rating,
      comment: review.comment,
      createdAt: review.createdAt
    };
  }
}
