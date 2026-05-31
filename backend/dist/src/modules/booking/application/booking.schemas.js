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
