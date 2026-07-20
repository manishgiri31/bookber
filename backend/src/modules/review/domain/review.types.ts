export type ReviewDTO = {
  id: string;
  userId: string;
  shopId: string;
  bookingId: string | null;
  rating: number;
  comment: string | null;
  createdAt: Date;
};

export type CreateReviewRequest = {
  bookingId: string;
  rating: number;
  comment?: string | undefined;
};
