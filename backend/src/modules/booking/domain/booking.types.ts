export type BookingStatus =
  | "QUEUED"
  | "READY"
  | "CALLED"
  | "IN_SERVICE"
  | "COMPLETED"
  | "CANCELLED"
  | "NO_SHOW";

export type QueueLane = "BOOKBER" | "WALKIN";

export type BookingQueueView = {
  id: string;
  shopId: string;
  userId: string;
  barberId: string | null;
  serviceId: string;
  status: BookingStatus;
  queueLane: QueueLane;
  queuePosition: number;
  estimatedWaitMinutes: number;
  arrivalWindowStart: Date;
  arrivalWindowEnd: Date;
  estimatedServiceStart: Date | null;
  estimatedServiceEnd: Date | null;
  walkIn: boolean;
};
