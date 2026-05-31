import { z } from "zod";
export const createPaymentSchema = z.object({
    bookingId: z.string().cuid(),
    amount: z.number().positive("Amount must be positive"),
    method: z.enum(["CASH", "UPI", "CARD"]),
    idempotencyKey: z.string().min(1).max(255).optional(),
    upiId: z.string().min(1).max(255).optional(),
    cardToken: z.string().min(1).max(255).optional()
}).refine((data) => {
    if (data.method === "UPI" && !data.upiId) {
        return false;
    }
    if (data.method === "CARD" && !data.cardToken) {
        return false;
    }
    return true;
}, {
    message: "UPI ID is required for UPI payments, card token is required for card payments",
    path: ["method"]
});
export const processPaymentSchema = z.object({
    paymentId: z.string().cuid(),
    transactionId: z.string().min(1).max(255),
    gatewayResponse: z.record(z.string(), z.any())
});
export const refundPaymentSchema = z.object({
    paymentId: z.string().cuid(),
    amount: z.number().positive("Refund amount must be positive"),
    reason: z.string().min(3).max(500),
    idempotencyKey: z.string().min(1).max(255).optional()
});
export const paymentHistorySchema = z.object({
    userId: z.string().cuid().optional(),
    shopId: z.string().cuid().optional(),
    bookingId: z.string().cuid().optional(),
    method: z.enum(["CASH", "UPI", "CARD"]).optional(),
    status: z.enum(["PENDING", "PAID", "FAILED", "REFUNDED", "PARTIALLY_REFUNDED"]).optional(),
    fromDate: z.string().datetime().optional(),
    toDate: z.string().datetime().optional(),
    limit: z.number().int().min(1).max(100).optional(),
    offset: z.number().int().min(0).optional()
});
export const webhookEventSchema = z.object({
    eventType: z.string(),
    payload: z.record(z.string(), z.any()),
    signature: z.string().optional()
});
