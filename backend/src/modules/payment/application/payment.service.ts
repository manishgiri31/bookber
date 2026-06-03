import type { PaymentDTO, CreatePaymentRequest, ProcessPaymentRequest, RefundRequest, PaymentHistoryRequest, PaginationResult } from "../domain/payment.types.js";
import type { PrismaPaymentRepository } from "../infrastructure/payment.repository.js";

export class PaymentService {
  constructor(private readonly repository: PrismaPaymentRepository) {}

  async createPayment(data: CreatePaymentRequest): Promise<PaymentDTO> {
    // Check for idempotency
    if (data.idempotencyKey) {
      const existing = await this.repository.findByIdempotencyKey(data.idempotencyKey);
      if (existing) {
        return existing;
      }
    }

    // Check if payment already exists for this booking
    const existingPayment = await this.repository.findByBookingId(data.bookingId);
    if (existingPayment) {
      throw new Error("Payment already exists for this booking");
    }

    return this.repository.create(data);
  }

  async processPayment(data: ProcessPaymentRequest): Promise<PaymentDTO> {
    const payment = await this.repository.findById(data.paymentId);
    if (!payment) {
      throw new Error("Payment not found");
    }

    if (payment.status !== "PENDING") {
      throw new Error("Payment is not in pending state");
    }

    return this.repository.updateStatus(data.paymentId, "PAID", data.transactionId);
  }

  async refundPayment(data: RefundRequest): Promise<PaymentDTO> {
    const payment = await this.repository.findById(data.paymentId);
    if (!payment) {
      throw new Error("Payment not found");
    }

    if (payment.status !== "PAID") {
      throw new Error("Only paid payments can be refunded");
    }

    if (data.amount > payment.amount) {
      throw new Error("Refund amount cannot exceed payment amount");
    }

    return this.repository.processRefund(data.paymentId, data.amount, data.reason);
  }

  async getPaymentHistory(filters: PaymentHistoryRequest): Promise<PaginationResult<PaymentDTO>> {
    return this.repository.findHistory(filters);
  }

  async getPaymentById(id: string): Promise<PaymentDTO> {
    const payment = await this.repository.findById(id);
    if (!payment) {
      throw new Error("Payment not found");
    }
    return payment;
  }
}
