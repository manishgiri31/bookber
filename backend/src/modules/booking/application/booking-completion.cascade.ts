/**
 * BookingCompletionCascade
 *
 * Runs as best-effort post-commit orchestration after a service is marked
 * COMPLETED.  Every step is wrapped in its own try/catch so a failure in one
 * does not prevent the others from running.
 *
 * Invariant: the main completeService transaction has already committed before
 * this runs, so these side-effects never roll back a completed service.
 */

import { prisma } from "../../../shared/prisma/client.js";
import type { LoyaltyService } from "../../loyalty/application/loyalty.service.js";
import type { NotificationService } from "../../notification/application/notification.service.js";
import type { Booking } from "@prisma/client";

// A minimal slice of what we need from the completed booking
export type CompletedBookingInfo = Booking & {
  service: { price: number; name: string };
  shop?: { name: string } | null;
};

export class BookingCompletionCascade {
  constructor(
    private readonly loyaltyService: LoyaltyService,
    private readonly notificationService: NotificationService
  ) {}

  async run(booking: CompletedBookingInfo): Promise<void> {
    await Promise.allSettled([
      this._createInvoice(booking),
      this._awardLoyaltyPoints(booking),
      this._requestReview(booking),
      this._notifyNextCustomer(booking),
    ]);
  }

  // ── 1. Invoice ──────────────────────────────────────────────────────────────
  // Creates a PENDING cash payment record so the booking appears in revenue
  // reports and payment history. Idempotent via Payment.bookingId @unique.
  private async _createInvoice(booking: CompletedBookingInfo): Promise<void> {
    const exists = await prisma.payment.findUnique({
      where: { bookingId: booking.id },
      select: { id: true }
    });
    if (exists) return; // already paid via Razorpay flow

    await prisma.payment.create({
      data: {
        bookingId: booking.id,
        amount: booking.service.price,
        method: "CASH",
        status: "PAID",
        completedAt: new Date()
      }
    });
  }

  // ── 2. Loyalty points ───────────────────────────────────────────────────────
  // Awards 10 points per completed booking. The loyaltyService.awardForBooking
  // existed but was never wired to completion — this is the wire.
  private async _awardLoyaltyPoints(booking: CompletedBookingInfo): Promise<void> {
    await this.loyaltyService.awardForBooking(booking.userId, booking.id);
  }

  // ── 3. Review request push notification ─────────────────────────────────────
  // Sends an FCM push so the customer is prompted to rate the service.
  // Uses the existing SERVICE_COMPLETE notification type + template.
  private async _requestReview(booking: CompletedBookingInfo): Promise<void> {
    const shopName = booking.shop?.name ?? "the shop";
    await this.notificationService.send({
      userId: booking.userId,
      type: "SERVICE_COMPLETE",
      title: "How was your haircut?",
      body: `Rate your experience at ${shopName} and help others choose.`,
      data: {
        bookingId: booking.id,
        action: "OPEN_REVIEW",
        shopId: booking.shopId
      }
    });
  }

  // ── 4. Notify the next customer that they're up ─────────────────────────────
  // The queue engine already emits a realtime socket event for the next booking
  // (emitBookingCalled inside tryAssignNext). This adds an FCM push for customers
  // who may not be in the app. We look for the booking that just moved to CALLED.
  private async _notifyNextCustomer(booking: CompletedBookingInfo): Promise<void> {
    const nextBooking = await prisma.booking.findFirst({
      where: {
        shopId: booking.shopId,
        status: "CALLED",
        updatedAt: { gte: new Date(Date.now() - 60_000) } // called within last 60 s
      },
      include: { service: { select: { name: true } } },
      orderBy: { updatedAt: "desc" }
    });
    if (!nextBooking) return;

    await this.notificationService.send({
      userId: nextBooking.userId,
      type: "BARBER_READY",
      title: "Your barber is ready! 💈",
      body: "Please scan the QR code at your barber's station to begin.",
      data: {
        bookingId: nextBooking.id,
        action: "SCAN_CHECKIN",
        shopId: nextBooking.shopId
      }
    });
  }
}
