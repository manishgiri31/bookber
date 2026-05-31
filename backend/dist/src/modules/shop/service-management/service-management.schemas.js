import { z } from "zod";
const baseServiceSchema = z.object({
    name: z.string().min(2).max(120),
    description: z.string().max(1000).optional(),
    durationMin: z.number().int().min(5).max(600),
    price: z.number().nonnegative(),
    category: z
        .enum(["HAIRCUT", "BEARD", "SHAVE", "COLOR", "TREATMENT", "PACKAGE", "OTHER"])
        .default("OTHER"),
    barberId: z.string().cuid().optional(),
    isBarberSpecific: z.boolean().default(false),
    isCombo: z.boolean().default(false)
});
export const createServiceSchema = baseServiceSchema.extend({
    comboItems: z
        .array(z.object({
        serviceId: z.string().cuid(),
        quantity: z.number().int().min(1).default(1)
    }))
        .default([])
});
export const updateServiceSchema = baseServiceSchema.partial().extend({
    status: z.enum(["ACTIVE", "INACTIVE"]).optional(),
    comboItems: z
        .array(z.object({
        serviceId: z.string().cuid(),
        quantity: z.number().int().min(1).default(1)
    }))
        .optional()
});
