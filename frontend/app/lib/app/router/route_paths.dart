abstract class RoutePaths {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';

  // Customer shell tabs
  static const home = '/home';
  static const explore = '/home/explore';
  static const bookings = '/home/bookings';
  static const profile = '/home/profile';

  // Customer standalone routes
  static const shopDetail = '/shop/:shopId';
  static const bookingFlow = '/book/:shopId';
  static const bookingSuccess = '/booking-success';
  static const liveQueue = '/queue/:shopId';
  static const payment = '/payment/:bookingId';
  static const paymentSuccess = '/payment-success/:paymentId';
  static const review = '/review/:bookingId';
  static const notifications = '/notifications';
  static const map = '/map';
  static const history = '/history';
  static const changePassword = '/change-password';
  static const editProfile = '/edit-profile';
  static const myReviews = '/my-reviews';

  // Booking sub-steps (used within BookingFlowScreen via internal navigation)
  static const services = '/booking/services';
  static const timing = '/booking/timing';
  static const confirmation = '/booking/confirm';

  // Barber shell tabs
  static const barberHome = '/barber';
  static const barberQueue = '/barber/queue';
  static const barberSchedule = '/barber/schedule';
  static const barberProfile = '/barber/profile';

  // Barber detail (deep link)
  static const barberDetails = '/barber/:barberId';

  // Admin shell tabs
  static const adminHome = '/admin';
  static const adminShops = '/admin/shops';
  static const adminUsers = '/admin/users';
  static const adminBookings = '/admin/bookings';
  static const adminReports = '/admin/reports';

  // Aliases
  static const barberDashboard = barberHome;
  static const queue = liveQueue;

  // Helpers — produce filled paths for context.go(...)
  static String shopDetailPath(String shopId) => '/shop/$shopId';
  static String bookingFlowPath(String shopId) => '/book/$shopId';
  static String liveQueuePath(String shopId) => '/queue/$shopId';
  static String paymentPath(String bookingId) => '/payment/$bookingId';
  static String paymentSuccessPath(String paymentId) => '/payment-success/$paymentId';
  static String reviewPath(String bookingId) => '/review/$bookingId';
  static String barberDetailPath(String barberId) => '/barber/$barberId';
}
