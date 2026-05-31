export type AnalyticsOverview = {
  totalUsers: number;
  totalBarbers: number;
  totalShops: number;
  totalBookings: number;
  totalRevenue: number;
  activeBookings: number;
  completedBookings: number;
  cancelledBookings: number;
  averageRating: number;
  totalReviews: number;
};

export type BookingAnalytics = {
  totalBookings: number;
  bookingsByStatus: Record<string, number>;
  bookingsByDay: Array<{ date: string; count: number }>;
  bookingsByHour: Array<{ hour: number; count: number }>;
  averageServiceDuration: number;
  cancellationRate: number;
  noShowRate: number;
  topServices: Array<{ serviceId: string; serviceName: string; count: number; revenue: number }>;
  topShops: Array<{ shopId: string; shopName: string; count: number; revenue: number }>;
};

export type EarningsOverview = {
  totalRevenue: number;
  revenueByPeriod: Array<{ period: string; revenue: number }>;
  revenueByPaymentMethod: Record<string, number>;
  revenueByShop: Array<{ shopId: string; shopName: string; revenue: number; commission: number }>;
  pendingPayouts: number;
  completedPayouts: number;
  averageOrderValue: number;
};

export type BarberModeration = {
  barberId: string;
  barberName: string;
  email: string;
  phoneNumber: string;
  shopId: string;
  shopName: string;
  status: "ACTIVE" | "SUSPENDED" | "PENDING";
  totalBookings: number;
  completedBookings: number;
  cancelledBookings: number;
  averageRating: number;
  totalRevenue: number;
  flaggedForReview: boolean;
  lastActiveAt: Date;
  createdAt: Date;
};

export type Report = {
  id: string;
  type: "BOOKING" | "BARBER" | "SHOP" | "PAYMENT" | "FRAUD";
  reporterId: string;
  reporterType: "CLIENT" | "BARBER" | "ADMIN";
  targetId: string;
  targetType: "BOOKING" | "BARBER" | "SHOP" | "PAYMENT";
  reason: string;
  description: string;
  status: "PENDING" | "UNDER_REVIEW" | "RESOLVED" | "DISMISSED";
  priority: "LOW" | "MEDIUM" | "HIGH" | "URGENT";
  metadata: Record<string, any> | null;
  resolvedBy: string | null;
  resolvedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
};

export type FraudDetectionAlert = {
  id: string;
  type: "SUSPICIOUS_BOOKING" | "PAYMENT_FRAUD" | "ACCOUNT_ABUSE" | "FAKE_REVIEWS";
  severity: "LOW" | "MEDIUM" | "HIGH" | "CRITICAL";
  targetId: string;
  targetType: "BOOKING" | "PAYMENT" | "USER" | "SHOP";
  description: string;
  evidence: Record<string, any>;
  status: "PENDING" | "INVESTIGATING" | "CONFIRMED" | "FALSE_POSITIVE" | "RESOLVED";
  actionTaken: string | null;
  reviewedBy: string | null;
  reviewedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
};

export type ActiveQueueMonitoring = {
  shopId: string;
  shopName: string;
  totalQueued: number;
  averageWaitTime: number;
  longestWaitTime: number;
  activeBarbers: number;
  availableChairs: number;
  queueByBarber: Array<{
    barberId: string;
    barberName: string;
    queueLength: number;
    averageWaitTime: number;
  }>;
  lastUpdated: Date;
};

export type AdminDashboard = {
  analytics: AnalyticsOverview;
  bookingAnalytics: BookingAnalytics;
  earnings: EarningsOverview;
  activeQueues: ActiveQueueMonitoring[];
  recentReports: Report[];
  fraudAlerts: FraudDetectionAlert[];
};

export type ModerationAction = {
  targetId: string;
  targetType: "BARBER" | "SHOP" | "USER";
  action: "SUSPEND" | "ACTIVATE" | "BAN" | "WARN" | "VERIFY";
  reason: string;
  duration?: number; // in days for temporary suspensions
  metadata?: Record<string, any>;
};

export type ReportFilter = {
  type?: string;
  status?: string;
  priority?: string;
  fromDate?: Date;
  toDate?: Date;
  limit?: number;
  offset?: number;
};

export type PaginationResult<T> = {
  data: T[];
  total: number;
  limit: number;
  offset: number;
  hasMore: boolean;
};
