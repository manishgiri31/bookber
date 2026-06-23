import { prisma } from "../../../shared/prisma/client.js";
import type { ReviewDTO, CreateReviewRequest } from "../domain/review.types.js";

export class PrismaReviewRepository {

  async create(data: CreateReviewRequest, userId: string): Promise<ReviewDTO> {
    const existing = await prisma.review.findFirst({
      where: { userId, shopId: data.shopId }
    });

    if (existing) {
      throw new Error("User has already reviewed this shop");
    }

    const review = await prisma.review.create({
      data: {
        userId,
        shopId: data.shopId,
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
      rating: review.rating,
      comment: review.comment,
      createdAt: review.createdAt
    };
  }
}
