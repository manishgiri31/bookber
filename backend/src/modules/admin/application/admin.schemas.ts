import { z } from "zod";

export const moderationActionSchema = z.object({
  targetId: z.string().cuid(),
  targetType: z.enum(["BARBER", "SHOP", "USER"]),
  action: z.enum(["SUSPEND", "ACTIVATE", "BAN", "WARN", "VERIFY"]),
  reason: z.string().min(10).max(500),
  duration: z.number().int().positive().optional(),
  metadata: z.record(z.string(), z.any()).optional()
});

export const reportFilterSchema = z.object({
  type: z.enum(["BOOKING", "BARBER", "SHOP", "PAYMENT", "FRAUD"]).optional(),
  status: z.enum(["PENDING", "UNDER_REVIEW", "RESOLVED", "DISMISSED"]).optional(),
  priority: z.enum(["LOW", "MEDIUM", "HIGH", "URGENT"]).optional(),
  fromDate: z.string().datetime().optional(),
  toDate: z.string().datetime().optional(),
  limit: z.number().int().min(1).max(100).optional(),
  offset: z.number().int().min(0).optional()
});

export const createReportSchema = z.object({
  type: z.enum(["BOOKING", "BARBER", "SHOP", "PAYMENT", "FRAUD"]),
  targetId: z.string().cuid(),
  targetType: z.enum(["BOOKING", "BARBER", "SHOP", "PAYMENT"]),
  reason: z.string().min(10).max(200),
  description: z.string().min(20).max(1000),
  priority: z.enum(["LOW", "MEDIUM", "HIGH", "URGENT"]).default("MEDIUM"),
  metadata: z.record(z.string(), z.any()).optional()
});

export const resolveReportSchema = z.object({
  reportId: z.string().cuid(),
  resolution: z.enum(["RESOLVED", "DISMISSED"]),
  notes: z.string().min(10).max(500)
});

export const fraudAlertFilterSchema = z.object({
  type: z.enum(["SUSPICIOUS_BOOKING", "PAYMENT_FRAUD", "ACCOUNT_ABUSE", "FAKE_REVIEWS"]).optional(),
  severity: z.enum(["LOW", "MEDIUM", "HIGH", "CRITICAL"]).optional(),
  status: z.enum(["PENDING", "INVESTIGATING", "CONFIRMED", "FALSE_POSITIVE", "RESOLVED"]).optional(),
  limit: z.number().int().min(1).max(100).optional(),
  offset: z.number().int().min(0).optional()
});

export const resolveFraudAlertSchema = z.object({
  alertId: z.string().cuid(),
  status: z.enum(["CONFIRMED", "FALSE_POSITIVE", "RESOLVED"]),
  actionTaken: z.string().min(10).max(500),
  notes: z.string().min(10).max(500).optional()
});

export const analyticsDateRangeSchema = z.object({
  fromDate: z.string().datetime(),
  toDate: z.string().datetime(),
  shopId: z.string().cuid().optional(),
  barberId: z.string().cuid().optional()
});

export const barberListFilterSchema = z.object({
  status: z.enum(["ACTIVE", "SUSPENDED", "PENDING"]).optional(),
  shopId: z.string().cuid().optional(),
  flaggedOnly: z.boolean().optional(),
  limit: z.number().int().min(1).max(100).optional(),
  offset: z.number().int().min(0).optional()
});

export type ModerationActionDto = z.infer<typeof moderationActionSchema>;
export type ReportFilterDto = z.infer<typeof reportFilterSchema>;
export type CreateReportDto = z.infer<typeof createReportSchema>;
export type ResolveReportDto = z.infer<typeof resolveReportSchema>;
export type FraudAlertFilterDto = z.infer<typeof fraudAlertFilterSchema>;
export type ResolveFraudAlertDto = z.infer<typeof resolveFraudAlertSchema>;
export type AnalyticsDateRangeDto = z.infer<typeof analyticsDateRangeSchema>;
export type BarberListFilterDto = z.infer<typeof barberListFilterSchema>;
