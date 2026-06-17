export type NotificationType =
  | "BOOKING_REMINDER"
  | "QUEUE_MOVEMENT"
  | "BARBER_READY"
  | "CANCELLATION"
  | "DELAY"
  | "NO_SHOW_DETECTED"
  | "CHAIR_ASSIGNED"
  | "SERVICE_COMPLETE"
  | "REBOOKING_REMINDER"
  | "ARRIVAL_ALERT";

export type NotificationPayload = {
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, string>;
};
