export type DailyAnalytic = {
  shopId: string;
  date: Date;
  totalBookings: number;
  totalWalkIns: number;
  completedBookings: number;
  cancelledBookings: number;
  noShows: number;
  avgWaitMinutes: number;
  avgServiceMinutes: number;
  totalRevenue: number;
  peakHour: number | null;
  chairUtilizationPct: number;
  queueAbandonments: number;
};

export type HourlyBucket = {
  hour: number;
  bookingCount: number;
  walkInCount: number;
  avgWaitMinutes: number;
};

export type PeakHourReport = {
  shopId: string;
  from: Date;
  to: Date;
  byHour: HourlyBucket[];
  peakHour: number | null;
  slowestHour: number | null;
};

export type UtilizationReport = {
  shopId: string;
  from: Date;
  to: Date;
  chairs: ChairUtilization[];
  barbers: BarberUtilization[];
  overallChairPct: number;
};

export type ChairUtilization = {
  chairId: string;
  chairNumber: number;
  utilizationPct: number;
  totalServiceMinutes: number;
  servicesCount: number;
};

export type BarberUtilization = {
  barberId: string;
  barberName: string;
  utilizationPct: number;
  totalServiceMinutes: number;
  servicesCount: number;
  avgServiceMinutes: number;
};

export type WeeklyInsights = {
  shopId: string;
  weekStart: Date;
  weekEnd: Date;
  revenue: number;
  revenueChange: number;
  totalBookings: number;
  bookingsChange: number;
  walkIns: number;
  walkInsChange: number;
  avgWaitMinutes: number;
  waitChange: number;
  queueAbandonmentRate: number;
  abandonmentChange: number;
  noShowRate: number;
  peakDay: string | null;
  lowUtilizationAlerts: LowUtilizationAlert[];
};

export type LowUtilizationAlert = {
  entityType: "CHAIR" | "BARBER";
  entityId: string;
  label: string;
  utilizationPct: number;
  message: string;
};
