import type { FastifyReply, FastifyRequest } from "fastify";
import type { ReviewService } from "../application/review.service.js";

export class ReviewController {
  constructor(private readonly service: ReviewService) {}

  create = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const dto = request.body as any;
    const review = await this.service.createReview(dto, user.id);
    return reply.status(201).send({ review });
  };

  getShopReviews = async (request: FastifyRequest) => {
    const { shopId } = request.params as { shopId: string };
    const reviews = await this.service.getShopReviews(shopId);
    return { reviews };
  };

  getUserReviews = async (request: FastifyRequest) => {
    const user = request.user as any;
    const reviews = await this.service.getUserReviews(user.id);
    return { reviews };
  };
}
