import { z } from "zod";

export const registerTokenSchema = z.object({
  token: z.string().min(10),
  platform: z.string().max(50).optional(),
  deviceId: z.string().max(100).optional()
});

export const sendNotificationSchema = z.object({
  userId: z.string().cuid(),
  type: z.enum(["BOOKING_REMINDER", "QUEUE_MOVEMENT", "BARBER_READY", "CANCELLATION", "DELAY"]),
  title: z.string().min(1).max(120),
  body: z.string().min(1).max(500),
  data: z.record(z.string(), z.unknown()).optional()
});

export type RegisterTokenDto = z.infer<typeof registerTokenSchema>;
export type SendNotificationDto = z.infer<typeof sendNotificationSchema>;
