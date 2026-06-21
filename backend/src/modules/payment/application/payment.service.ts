import type { PaymentDTO, CreatePaymentRequest, ProcessPaymentRequest, RefundRequest, PaymentHistoryRequest, PaginationResult } from "../domain/payment.types.js";
import type { PrismaPaymentRepository } from "../infrastructure/payment.repository.js";
import { getRazorpayClient } from "../infrastructure/razorpay.client.js";

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

  // ─── Razorpay ────────────────────────────────────────────────────────────

  async createRazorpayOrder(bookingId: string, amount: number): Promise<{
    razorpayOrderId: string;
    amount: number;
    currency: string;
    keyId: string;
    isStub: boolean;
  }> {
    const razorpay = getRazorpayClient();

    const order = await razorpay.createOrder({
      amount,
      currency: "INR",
      receipt: `booking_${bookingId}_${Date.now()}`,
      notes: { bookingId },
    });

    // Create a PENDING payment record
    const idempotencyKey = `rzp_${order.id}`;
    const existingByKey = await this.repository.findByIdempotencyKey(idempotencyKey);
    if (!existingByKey) {
      await this.createPayment({
        bookingId,
        amount,
        method: "CARD",
        idempotencyKey,
      });
    }

    return {
      razorpayOrderId: order.id,
      amount: order.amount / 100, // back to rupees
      currency: order.currency,
      keyId: process.env["RAZORPAY_KEY_ID"] ?? "",
      isStub: !razorpay.isEnabled,
    };
  }

  async verifyRazorpayPayment(params: {
    bookingId: string;
    razorpayOrderId: string;
    razorpayPaymentId: string;
    razorpaySignature: string;
  }): Promise<PaymentDTO> {
    const razorpay = getRazorpayClient();

    const valid = razorpay.verifySignature({
      razorpayOrderId: params.razorpayOrderId,
      razorpayPaymentId: params.razorpayPaymentId,
      razorpaySignature: params.razorpaySignature,
    });

    if (!valid) {
      throw new Error("Invalid payment signature");
    }

    const idempotencyKey = `rzp_${params.razorpayOrderId}`;
    const payment = await this.repository.findByIdempotencyKey(idempotencyKey)
      ?? await this.repository.findByBookingId(params.bookingId);

    if (!payment) {
      throw new Error("Payment record not found");
    }

    return this.repository.updateStatus(
      payment.id,
      "PAID",
      params.razorpayPaymentId
    );
  }

  async handleWebhook(payload: string, signature: string): Promise<void> {
    const razorpay = getRazorpayClient();
    const valid = razorpay.verifyWebhookSignature(payload, signature);
    if (!valid) {
      throw new Error("Invalid webhook signature");
    }
    // Idempotently process the webhook — mark PAID if not already
    const event = JSON.parse(payload) as Record<string, any>;
    if (event["event"] === "payment.captured") {
      const razorpayPaymentId = event["payload"]?.payment?.entity?.id as string | undefined;
      const orderId = event["payload"]?.payment?.entity?.order_id as string | undefined;
      if (razorpayPaymentId && orderId) {
        const idempotencyKey = `rzp_${orderId}`;
        const payment = await this.repository.findByIdempotencyKey(idempotencyKey);
        if (payment && payment.status === "PENDING") {
          await this.repository.updateStatus(payment.id, "PAID", razorpayPaymentId);
        }
      }
    }
  }
}
