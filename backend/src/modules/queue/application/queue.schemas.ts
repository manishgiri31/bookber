import { z } from "zod";

export const enqueueSchema = z.object({
  shopId: z.string().cuid(),
  bookingId: z.string().cuid().optional(),
  clientId: z.string().cuid().optional(),
  serviceId: z.string().cuid(),
  barberId: z.string().cuid().optional(),
  walkIn: z.boolean().default(false),
  priority: z.number().int().min(0).default(0)
});

export const rebalanceSchema = z.object({
  reason: z.string().min(3).max(200).optional()
});

export type EnqueueDto = z.infer<typeof enqueueSchema>;
export type RebalanceDto = z.infer<typeof rebalanceSchema>;
