import { prisma } from "../../../shared/prisma/client.js";
import type { ScheduledReminder } from "../domain/rebooking.types.js";

export class RebookingRepository {
  async scheduleReminder(input: ScheduledReminder): Promise<void> {
    await prisma.rebookingReminder.upsert({
      where: {
        // Treat (userId, serviceId, lastVisitAt) as natural key via a raw check below
        id: "__never__",
      },
      create: {
        userId: input.userId,
        shopId: input.shopId,
        serviceId: input.serviceId,
        lastVisitAt: input.lastVisitAt,
        reminderAt: input.reminderAt,
      },
      update: {},
    }).catch(async () => {
      // Upsert by natural key manually to avoid composite unique requirement
      const existing = await prisma.rebookingReminder.findFirst({
        where: {
          userId: input.userId,
          serviceId: input.serviceId,
          lastVisitAt: input.lastVisitAt,
        },
      });
      if (!existing) {
        await prisma.rebookingReminder.create({
          data: {
            userId: input.userId,
            shopId: input.shopId,
            serviceId: input.serviceId,
            lastVisitAt: input.lastVisitAt,
            reminderAt: input.reminderAt,
          },
        });
      }
    });
  }

  async findDueReminders(limit = 100) {
    const now = new Date();
    return prisma.rebookingReminder.findMany({
      where: {
        reminderAt: { lte: now },
        sentAt: null,
        dismissed: false,
      },
      take: limit,
      include: {
        user: { select: { id: true, fullName: true } },
        service: { select: { id: true, name: true, category: true, shopId: true } },
      },
    });
  }

  async markSent(id: string): Promise<void> {
    await prisma.rebookingReminder.update({
      where: { id },
      data: { sentAt: new Date() },
    });
  }

  async findCompletedBookingsSince(since: Date, limit = 500) {
    return prisma.booking.findMany({
      where: {
        status: "COMPLETED",
        updatedAt: { gte: since },
      },
      select: {
        userId: true,
        shopId: true,
        serviceId: true,
        service: { select: { category: true, rebookIntervalDays: true } },
        updatedAt: true,
      },
      take: limit,
      orderBy: { updatedAt: "desc" },
    });
  }
}
