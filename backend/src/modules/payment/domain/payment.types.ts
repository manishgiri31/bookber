export type PaymentMethod = "CASH" | "UPI" | "CARD";

export type PaymentStatus = "PENDING" | "PAID" | "FAILED" | "REFUNDED" | "PARTIALLY_REFUNDED";

export type PaymentDTO = {
  id: string;
  bookingId: string;
  amount: number;
  method: PaymentMethod;
  status: PaymentStatus;
  transactionId: string | null;
  idempotencyKey: string | null;
  refundedAmount: number;
  refundReason: string | null;
  completedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
};

export type PaymentWithBooking = PaymentDTO & {
  booking: {
    id: string;
    userId: string;
    shopId: string;
    barberId: string;
    serviceId: string;
    arrivalWindowStart: Date;
    arrivalWindowEnd: Date;
    status: string;
  };
};

export type CreatePaymentRequest = {
  bookingId: string;
  amount: number;
  method: PaymentMethod;
  idempotencyKey?: string;
  upiId?: string;
  cardToken?: string;
};

export type ProcessPaymentRequest = {
  paymentId: string;
  transactionId: string;
  gatewayResponse: Record<string, any>;
};

export type RefundRequest = {
  paymentId: string;
  amount: number;
  reason: string;
  idempotencyKey?: string;
};

export type PaymentHistoryRequest = {
  userId?: string;
  shopId?: string;
  bookingId?: string;
  method?: PaymentMethod;
  status?: PaymentStatus;
  fromDate?: Date;
  toDate?: Date;
  limit?: number;
  offset?: number;
};

export type PaymentTransactionLog = {
  id: string;
  paymentId: string;
  action: "CREATED" | "PROCESSED" | "FAILED" | "REFUNDED" | "WEBHOOK_RECEIVED";
  status: PaymentStatus;
  gatewayResponse: Record<string, any> | null;
  errorMessage: string | null;
  metadata: Record<string, any> | null;
  createdAt: Date;
};

export type WebhookEvent = {
  id: string;
  paymentId: string;
  eventType: string;
  payload: Record<string, any>;
  processedAt: Date | null;
  receivedAt: Date;
};

export type PaymentMetrics = {
  totalPayments: number;
  totalAmount: number;
  successfulPayments: number;
  failedPayments: number;
  refundedPayments: number;
  refundAmount: number;
  averagePaymentAmount: number;
  methodBreakdown: Record<PaymentMethod, { count: number; amount: number }>;
};

export type PaginationResult<T> = {
  data: T[];
  total: number;
  limit: number;
  offset: number;
  hasMore: boolean;
};
