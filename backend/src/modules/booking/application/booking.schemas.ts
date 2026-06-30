import { z } from "zod";

export const createBookingSchema = z.object({
  shopId: z.string().cuid(),
  serviceId: z.string().cuid(),
  barberId: z.string().cuid().optional(),
  walkIn: z.boolean().default(false),
  scheduledStart: z.string().datetime().optional(),
  travelMinutes: z.number().int().min(0).max(120).optional(),
  notes: z.string().max(500).optional(),
  referenceImageUrls: z.array(z.string().url()).max(5).optional()
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
