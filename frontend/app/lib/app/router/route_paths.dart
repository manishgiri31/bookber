abstract class RoutePaths {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';

  static const home = '/home';
  static const explore = '/home/explore';
  static const bookings = '/home/bookings';
  static const profile = '/home/profile';
  static const shopDetail = '/shop/:shopId';
  static const bookingFlow = '/book/:shopId';
  static const bookingSuccess = '/booking-success';
  static const liveQueue = '/queue/:shopId';
  static const payment = '/payment/:bookingId';
  static const paymentSuccess = '/payment-success/:paymentId';
  static const review = '/review/:bookingId';

  static const barberHome = '/barber';
  static const barberQueue = '/barber/queue';
  static const barberSchedule = '/barber/schedule';
  static const barberProfile = '/barber/profile';

  static const adminHome = '/admin';
  static const adminShops = '/admin/shops';
  static const adminUsers = '/admin/users';
  static const adminBookings = '/admin/bookings';
  static const adminReports = '/admin/reports';

  static const barberDashboard = barberHome;
  static const barberDetails = '/barber/:barberId';
  static const services = '/booking/services';
  static const timing = '/booking/timing';
  static const confirmation = '/booking/confirm';
  static const queue = liveQueue;
  static const history = '/history';
}
