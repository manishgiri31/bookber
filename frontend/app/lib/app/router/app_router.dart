import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/booking/booking_flow_screen.dart';
import '../../features/booking/booking_success_screen.dart';
import '../../features/booking/presentation/pages/booking_history_page.dart';
import '../../features/customer/home/home_screen.dart';
import '../../features/customer/explore/explore_screen.dart';
import '../../features/customer/shop_detail/shop_detail_screen.dart';
import '../../features/payment/payment_screen.dart';
import '../../features/payment/payment_success_screen.dart';
import '../../features/queue/live_queue_screen.dart';
import '../../features/review/review_screen.dart';
import '../../features/barber/dashboard/barber_home_screen.dart';
import '../../features/barber/queue/barber_queue_screen.dart';
import '../../features/barber/schedule/barber_schedule_screen.dart';
import '../../features/admin/dashboard/admin_overview_screen.dart';
import '../../features/admin/shops/admin_shops_screen.dart';
import '../../features/admin/users/admin_users_screen.dart';
import '../../features/admin/bookings/admin_bookings_screen.dart';
import '../../features/admin/reports/admin_reports_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import 'route_guards.dart';
import 'route_paths.dart';

final appRouterKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: appRouterKey,
    initialLocation: RoutePaths.splash,
    refreshListenable: GoRouterRefreshStream(ref.watch(authControllerProvider.notifier).stream),
    redirect: authRedirect,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: RoutePaths.explore,
            builder: (context, state) => const ExploreScreen(),
          ),
          GoRoute(
            path: RoutePaths.bookings,
            builder: (context, state) => const BookingHistoryPage(),
          ),
          GoRoute(
            path: RoutePaths.profile,
            builder: (context, state) => const CustomerProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.shopDetail,
        builder: (context, state) => ShopDetailScreen(
          shopId: state.pathParameters['shopId']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.bookingFlow,
        builder: (context, state) => BookingFlowScreen(
          shopId: state.pathParameters['shopId']!,
          shopName: '',
        ),
      ),
      GoRoute(
        path: RoutePaths.bookingSuccess,
        builder: (context, state) => const BookingSuccessScreen(),
      ),
      GoRoute(
        path: RoutePaths.liveQueue,
        builder: (context, state) => LiveQueueScreen(
          shopId: state.pathParameters['shopId']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.payment,
        builder: (context, state) => PaymentScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.paymentSuccess,
        builder: (context, state) => PaymentSuccessScreen(
          paymentId: state.pathParameters['paymentId']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.review,
        builder: (context, state) => ReviewScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => BarberShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.barberHome,
            builder: (context, state) => const BarberHomeScreen(),
          ),
          GoRoute(
            path: RoutePaths.barberQueue,
            builder: (context, state) => const BarberQueueScreen(),
          ),
          GoRoute(
            path: RoutePaths.barberSchedule,
            builder: (context, state) => const BarberScheduleScreen(),
          ),
          GoRoute(
            path: RoutePaths.barberProfile,
            builder: (context, state) => const BarberProfileScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.adminHome,
            builder: (context, state) => const AdminOverviewScreen(),
          ),
          GoRoute(
            path: RoutePaths.adminShops,
            builder: (context, state) => const AdminShopsScreen(),
          ),
          GoRoute(
            path: RoutePaths.adminUsers,
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: RoutePaths.adminBookings,
            builder: (context, state) => const AdminBookingsScreen(),
          ),
          GoRoute(
            path: RoutePaths.adminReports,
            builder: (context, state) => const AdminReportsScreen(),
          ),
        ],
      ),
    ],
  );
});

final appRouterProvider = routerProvider;

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child);
  }
}

class BarberShell extends StatelessWidget {
  const BarberShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child);
  }
}

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child);
  }
}

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Customer Profile')));
  }
}

class BarberProfileScreen extends StatelessWidget {
  const BarberProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Barber Profile')));
  }
}
