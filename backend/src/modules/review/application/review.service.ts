import type { ReviewDTO, CreateReviewRequest } from "../domain/review.types.js";
import type { PrismaReviewRepository } from "../infrastructure/review.repository.js";

export class ReviewService {
  constructor(private readonly repository: PrismaReviewRepository) {}

  async createReview(data: CreateReviewRequest, userId: string): Promise<ReviewDTO> {
    if (data.rating < 1 || data.rating > 5) {
      throw new Error("Rating must be between 1 and 5");
    }

    return this.repository.create(data, userId);
  }

  async getShopReviews(shopId: string): Promise<ReviewDTO[]> {
    return this.repository.findByShopId(shopId);
  }

  async getUserReviews(userId: string): Promise<ReviewDTO[]> {
    return this.repository.findByUserId(userId);
  }
}
