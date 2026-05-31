import { z } from "zod";

const timeSchema = z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/, "Invalid HH:mm time");

export const createShopSchema = z.object({
  name: z.string().min(2).max(120),
  description: z.string().max(1000).optional(),
  address: z.string().min(3).max(200),
  city: z.string().min(2).max(100),
  state: z.string().min(2).max(100),
  country: z.string().min(2).max(100),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  openingTime: timeSchema.optional(),
  closingTime: timeSchema.optional(),
  services: z
    .array(
      z.object({
        name: z.string().min(2).max(120),
        description: z.string().max(1000).optional(),
        durationMinutes: z.number().int().min(5).max(600),
        price: z.number().nonnegative()
      })
    )
    .default([]),
  chairs: z
    .array(
      z.object({
        number: z.number().int().min(1)
      })
    )
    .default([])
});

export const updateShopSchema = createShopSchema.partial().extend({
  isActive: z.boolean().optional()
});

export const createServiceSchema = z.object({
  name: z.string().min(2).max(120),
  description: z.string().max(1000).optional(),
  durationMinutes: z.number().int().min(5).max(600),
  price: z.number().nonnegative()
});

export const updateServiceSchema = createServiceSchema.partial().extend({
  isActive: z.boolean().optional()
});

export const createChairSchema = z.object({
  number: z.number().int().min(1)
});

export const updateChairSchema = createChairSchema.partial().extend({
  status: z.enum(["AVAILABLE", "OCCUPIED", "CLEANING", "BLOCKED"]).optional()
});

export const shopSearchSchema = z.object({
  page: z.number().int().min(1).default(1),
  limit: z.number().int().min(1).max(100).default(20),
  query: z.string().optional(),
  city: z.string().optional(),
  isActive: z.boolean().optional(),
  latitude: z.number().min(-90).max(90).optional(),
  longitude: z.number().min(-180).max(180).optional(),
  radiusKm: z.number().min(0.1).max(100).optional()
});

export const serviceSearchSchema = z.object({
  page: z.number().int().min(1).default(1),
  limit: z.number().int().min(1).max(100).default(20),
  query: z.string().optional(),
  isActive: z.boolean().optional()
});

export type CreateShopDto = z.infer<typeof createShopSchema>;
export type UpdateShopDto = z.infer<typeof updateShopSchema>;
export type CreateServiceDto = z.infer<typeof createServiceSchema>;
export type UpdateServiceDto = z.infer<typeof updateServiceSchema>;
export type CreateChairDto = z.infer<typeof createChairSchema>;
export type UpdateChairDto = z.infer<typeof updateChairSchema>;
export type ShopSearchDto = z.infer<typeof shopSearchSchema>;
export type ServiceSearchDto = z.infer<typeof serviceSearchSchema>;
