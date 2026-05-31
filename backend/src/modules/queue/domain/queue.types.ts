import type { BookingStatus, ChairStatus, QueueLane, QueueStatus } from "@prisma/client";

export type QueueSnapshotEntry = {
  activeQueueId: string;
  bookingId: string;
  shopId: string;
  barberId: string | null;
  userId: string;
  serviceId: string;
  lane: QueueLane;
  position: number;
  queueStatus: QueueStatus;
  bookingStatus: BookingStatus;
  estimatedWaitMinutes: number;
  estimatedServiceStart: Date | null;
  arrivalWindowStart: Date;
  arrivalWindowEnd: Date;
  chairId: string | null;
  walkIn: boolean;
};

export type QueueSnapshot = {
  shopId: string;
  version: number;
  bookBer: QueueSnapshotEntry[];
  walkIn: QueueSnapshotEntry[];
};

export type ChairView = {
  id: string;
  shopId: string;
  number: number;
  status: ChairStatus;
  reservedForBookBer: boolean;
  bookingId: string | null;
  activeServiceStart: Date | null;
  activeServiceEnd: Date | null;
};
