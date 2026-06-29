abstract final class ApiEndpoints {
  // Base
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://clump-passion-cruelty.ngrok-free.dev',
  );
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'https://clump-passion-cruelty.ngrok-free.dev',
  );

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String changePassword = '/auth/change-password';
  static const String me = '/auth/me';
  static const String updateMe = '/auth/me';

  // Shops
  static const String shops = '/shops';
  static String shopById(String id) => '/shops/$id';
  static const String myShop = '/shops/my';
  static String shopServices(String shopId) => '/shops/$shopId/services';
  static String shopChairs(String shopId) => '/shops/$shopId/chairs';
  static String shopQueue(String shopId) => '/shops/$shopId/queue';
  static String shopWaitEstimates(String shopId) =>
      '/shops/$shopId/wait-estimates';
  static String shopReviews(String shopId) => '/shops/$shopId/reviews';
  static String shopAnalytics(String shopId, String type) =>
      '/shops/$shopId/analytics/$type';

  // Queue
  static String enqueue(String shopId) => '/shops/$shopId/queue/enqueue';
  static const String walkIn = '/api/queue/walk-in';
  static String queueEntryStatus(String entryId) =>
      '/api/queue/$entryId/status';

  // Bookings
  static const String bookings = '/bookings';
  static String bookingById(String id) => '/bookings/$id';
  static String checkIn(String id) => '/bookings/$id/check-in';
  static String startService(String id) => '/bookings/$id/start';
  static String completeService(String id) => '/bookings/$id/complete';
  static String noShow(String id) => '/bookings/$id/no-show';
  static String cancelBooking(String id) => '/bookings/$id/cancel';
  static String shopBookings(String shopId) => '/bookings/shops/$shopId';

  // Barbers
  static const String barberMe = '/api/barbers/me';
  static String barberStats(String id) => '/api/barbers/$id/stats';
  static String barberQueue(String id) => '/api/barbers/$id/queue';
  static String barberBookings(String id) => '/api/barbers/$id/bookings';
  static String barberStatus(String id) => '/api/barbers/$id/status';
  static String barberWorkingHours(String id) =>
      '/api/barbers/$id/working-hours';

  // Reviews
  static const String reviews = '/reviews';
  static const String myReviews = '/reviews/my';

  // Notifications
  static const String notificationTokens = '/notifications/tokens';
  static String revokeToken(String token) => '/notifications/tokens/$token';

  // Payments
  static const String payments = '/payments';
  static String paymentById(String id) => '/payments/$id';
  static const String paymentHistory = '/payments/history';
  static const String processPayment = '/payments/process';
  static const String refundPayment = '/payments/refund';
  static const String razorpayOrder = '/payments/razorpay/order';
  static const String razorpayVerify = '/payments/razorpay/verify';

  // Discovery / Geolocation
  static const String nearbyShops = '/geolocation/nearby';
  static const String topRatedShops = '/geolocation/top-rated';
  static const String searchGeolocation = '/geolocation/search';
  static const String mapMarkers = '/geolocation/markers';
  static String shopsByCity(String city) => '/geolocation/city/$city';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminAnalyticsOverview = '/admin/analytics/overview';
  static const String adminAnalyticsBookings = '/admin/analytics/bookings';
  static const String adminAnalyticsEarnings = '/admin/analytics/earnings';
  static const String adminBarbers = '/admin/barbers';
  static const String adminModerationAction = '/admin/moderation/action';
  static const String adminActiveQueues = '/admin/queues/active';

  // Wallet
  static const String walletBalance = '/wallet/balance';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletTopUp = '/wallet/topup';

  // Loyalty
  static const String loyaltyAccount = '/loyalty/account';
  static const String loyaltyTransactions = '/loyalty/transactions';

  // Referral
  static const String referralMyCode = '/referral/my-code';
  static const String referralMyReferrals = '/referral/my-referrals';
  static const String referralApply = '/referral/apply';

  // Loyalty (redeem)
  static const String loyaltyRedeem = '/loyalty/redeem';

  // Coupons
  static const String validateCoupon = '/coupons/validate';
}
