import { z } from "zod";
export const barberDelaySchema = z.object({
    delayMinutes: z.number().int().min(1).max(120)
});
export const serviceOverrunSchema = z.object({
    overrunMinutes: z.number().int().min(1).max(120)
});
