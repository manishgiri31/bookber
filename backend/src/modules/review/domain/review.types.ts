export type ReviewDTO = {
  id: string;
  userId: string;
  shopId: string;
  rating: number;
  comment: string | null;
  createdAt: Date;
};

export type CreateReviewRequest = {
  shopId: string;
  rating: number;
  comment?: string;
};
