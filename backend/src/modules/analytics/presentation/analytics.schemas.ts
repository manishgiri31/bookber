import { z } from "zod";

export const dateRangeSchema = z.object({
  from: z.string().datetime(),
  to: z.string().datetime(),
});

export const shopParamSchema = z.object({
  shopId: z.string().cuid(),
});

export const dailyAnalyticsQuerySchema = z.object({
  date: z.string().datetime().optional(),
});
