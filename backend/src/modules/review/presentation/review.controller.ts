import type { FastifyReply, FastifyRequest } from "fastify";
import { getAuthUser } from "../../auth/presentation/auth-user.js";
import { createReviewSchema } from "../application/review.schemas.js";
import type { ReviewService } from "../application/review.service.js";

const CONFLICT_MESSAGES = new Set(["Booking already reviewed"]);
const FORBIDDEN_MESSAGES = new Set(["Not your booking"]);
const NOT_FOUND_MESSAGES = new Set(["Booking not found"]);

export class ReviewController {
  constructor(private readonly service: ReviewService) {}

  create = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = getAuthUser(request);
    const dto = createReviewSchema.parse(request.body);
    try {
      const review = await this.service.createReview(dto, user.id);
      return reply.status(201).send({ review });
    } catch (err: any) {
      const message = err?.message ?? "";
      if (CONFLICT_MESSAGES.has(message)) {
        return reply.status(409).send({ error: { code: "CONFLICT", message } });
      }
      if (FORBIDDEN_MESSAGES.has(message)) {
        return reply.status(403).send({ error: { code: "FORBIDDEN", message } });
      }
      if (NOT_FOUND_MESSAGES.has(message)) {
        return reply.status(404).send({ error: { code: "NOT_FOUND", message } });
      }
      if (message === "Booking is not completed yet") {
        return reply.status(400).send({ error: { code: "BAD_REQUEST", message } });
      }
      throw err;
    }
  };

  getShopReviews = async (request: FastifyRequest) => {
    const { shopId } = request.params as { shopId: string };
    const reviews = await this.service.getShopReviews(shopId);
    return { reviews };
  };

  getUserReviews = async (request: FastifyRequest) => {
    const user = getAuthUser(request);
    const reviews = await this.service.getUserReviews(user.id);
    return { reviews };
  };
}
