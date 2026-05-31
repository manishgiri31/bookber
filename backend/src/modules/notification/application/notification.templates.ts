import type { NotificationPayload } from "../domain/notification.types.js";

export function buildNotificationTemplate(input: NotificationPayload) {
  switch (input.type) {
    case "BOOKING_REMINDER":
      return {
        title: input.title || "Booking reminder",
        body: input.body || "Your appointment is coming up soon.",
        data: input.data ?? {}
      };
    case "QUEUE_MOVEMENT":
      return {
        title: input.title || "Queue update",
        body: input.body || "Your position in the queue has changed.",
        data: input.data ?? {}
      };
    case "BARBER_READY":
      return {
        title: input.title || "Barber is ready",
        body: input.body || "Please head to the chair now.",
        data: input.data ?? {}
      };
    case "CANCELLATION":
      return {
        title: input.title || "Booking cancelled",
        body: input.body || "Your booking has been cancelled.",
        data: input.data ?? {}
      };
    case "DELAY":
      return {
        title: input.title || "Delay update",
        body: input.body || "There is a delay at the shop.",
        data: input.data ?? {}
      };
    default:
      return {
        title: input.title,
        body: input.body,
        data: input.data ?? {}
      };
  }
}
