import { z } from "zod";

export const createBookingSchema = z.object({
  shopId: z.string().cuid(),
  serviceId: z.string().cuid(),
  barberId: z.string().cuid().optional(),
  walkIn: z.boolean().default(false)
});

export const cancelBookingSchema = z.object({
  reason: z.string().min(3).max(500).optional()
});

export const scanCheckInSchema = z.object({
  token: z.string().min(1).max(64)
});

export type CreateBookingDto = z.infer<typeof createBookingSchema>;
export type CancelBookingDto = z.infer<typeof cancelBookingSchema>;
export type ScanCheckInDto = z.infer<typeof scanCheckInSchema>;
