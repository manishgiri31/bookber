import type { ServiceCategory } from "@prisma/client";

export const DEFAULT_REBOOK_INTERVALS: Record<ServiceCategory, number> = {
  HAIRCUT: 30,
  BEARD: 14,
  COMBO: 21,
  SHAVE: 10,
  COLOR: 45,
  TREATMENT: 21,
  OTHER: 30,
};

export type ScheduledReminder = {
  userId: string;
  shopId: string;
  serviceId: string;
  serviceCategory: ServiceCategory;
  lastVisitAt: Date;
  reminderAt: Date;
};
