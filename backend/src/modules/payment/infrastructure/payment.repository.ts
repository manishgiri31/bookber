import { PrismaClient } from "@prisma/client";
import type { PaymentDTO, CreatePaymentRequest, ProcessPaymentRequest, RefundRequest, PaymentHistoryRequest, PaginationResult } from "../domain/payment.types.js";

export class PrismaPaymentRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async create(data: CreatePaymentRequest): Promise<PaymentDTO> {
    const payment = await this.prisma.payment.create({
      data: {
        bookingId: data.bookingId,
        amount: data.amount,
        method: data.method,
        idempotencyKey: data.idempotencyKey || null
      }
    });

    return this.toDTO(payment);
  }

  async findById(id: string): Promise<PaymentDTO | null> {
    const payment = await this.prisma.payment.findUnique({
      where: { id }
    });

    return payment ? this.toDTO(payment) : null;
  }

  async findByBookingId(bookingId: string): Promise<PaymentDTO | null> {
    const payment = await this.prisma.payment.findUnique({
      where: { bookingId }
    });

    return payment ? this.toDTO(payment) : null;
  }

  async findByIdempotencyKey(idempotencyKey: string): Promise<PaymentDTO | null> {
    const payment = await this.prisma.payment.findUnique({
      where: { idempotencyKey }
    });

    return payment ? this.toDTO(payment) : null;
  }

  async updateStatus(id: string, status: string, transactionId?: string): Promise<PaymentDTO> {
    const payment = await this.prisma.payment.update({
      where: { id },
      data: {
        status: status as any,
        transactionId: transactionId || null,
        completedAt: status === "PAID" ? new Date() : null
      }
    });

    return this.toDTO(payment);
  }

  async processRefund(id: string, amount: number, reason: string): Promise<PaymentDTO> {
    const payment = await this.prisma.payment.update({
      where: { id },
      data: {
        status: "REFUNDED",
        refundedAmount: amount,
        refundReason: reason
      }
    });

    return this.toDTO(payment);
  }

  async findHistory(filters: PaymentHistoryRequest): Promise<PaginationResult<PaymentDTO>> {
    const where: any = {};
    
    if (filters.userId) {
      where.booking = { userId: filters.userId };
    }
    if (filters.shopId) {
      where.booking = { ...where.booking, shopId: filters.shopId };
    }
    if (filters.bookingId) {
      where.bookingId = filters.bookingId;
    }
    if (filters.method) {
      where.method = filters.method;
    }
    if (filters.status) {
      where.status = filters.status;
    }
    if (filters.fromDate || filters.toDate) {
      where.createdAt = {};
      if (filters.fromDate) {
        where.createdAt.gte = new Date(filters.fromDate);
      }
      if (filters.toDate) {
        where.createdAt.lte = new Date(filters.toDate);
      }
    }

    const limit = filters.limit || 50;
    const offset = filters.offset || 0;

    const [data, total] = await Promise.all([
      this.prisma.payment.findMany({
        where,
        include: {
          booking: {
            select: {
              id: true,
              userId: true,
              shopId: true,
              barberId: true,
              serviceId: true,
              arrivalWindowStart: true,
              arrivalWindowEnd: true,
              status: true
            }
          }
        },
        orderBy: { createdAt: "desc" },
        take: limit,
        skip: offset
      }),
      this.prisma.payment.count({ where })
    ]);

    return {
      data: data.map(p => this.toDTO(p)),
      total,
      limit,
      offset,
      hasMore: offset + data.length < total
    };
  }

  private toDTO(payment: any): PaymentDTO {
    return {
      id: payment.id,
      bookingId: payment.bookingId,
      amount: payment.amount,
      method: payment.method,
      status: payment.status,
      transactionId: payment.transactionId,
      idempotencyKey: payment.idempotencyKey,
      refundedAmount: payment.refundedAmount,
      refundReason: payment.refundReason,
      completedAt: payment.completedAt,
      createdAt: payment.createdAt,
      updatedAt: payment.updatedAt
    };
  }
}
