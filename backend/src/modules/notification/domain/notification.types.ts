export type NotificationType =
  | "BOOKING_REMINDER"
  | "QUEUE_MOVEMENT"
  | "BARBER_READY"
  | "CANCELLATION"
  | "DELAY";

export type NotificationPayload = {
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, string>;
};
