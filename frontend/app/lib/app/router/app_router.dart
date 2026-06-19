import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../features/admin/bookings/admin_bookings_screen.dart';
import '../../features/admin/dashboard/admin_overview_screen.dart';
import '../../features/admin/reports/admin_reports_screen.dart';
import '../../features/admin/shops/admin_shops_screen.dart';
import '../../features/admin/users/admin_users_screen.dart';
import '../../features/auth/presentation/change_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/barber/dashboard/barber_home_screen.dart';
import '../../features/barber/profile/barber_profile_screen.dart';
import '../../features/barber/queue/barber_queue_screen.dart';
import '../../features/barber/schedule/barber_schedule_screen.dart';
import '../../features/barber/widgets/barber_bottom_nav.dart';
import '../../features/booking/booking_flow_screen.dart';
import '../../features/booking/booking_success_screen.dart';
import '../../features/booking/presentation/pages/barber_details_page.dart';
import '../../features/booking/presentation/pages/booking_history_page.dart';
import '../../features/booking/presentation/pages/booking_confirmation_page.dart';
import '../../features/booking/presentation/pages/services_selection_page.dart';
import '../../features/booking/presentation/pages/booking_timing_page.dart';
import '../../features/customer/explore/explore_screen.dart';
import '../../features/customer/home/home_screen.dart';
import '../../features/customer/profile/customer_profile_screen.dart';
import '../../features/customer/shop_detail/shop_detail_screen.dart';
import '../../features/customer/widgets/customer_nav_bar.dart';
import '../../features/maps/presentation/map_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/my_reviews_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/payment/payment_screen.dart';
import '../../features/payment/payment_success_screen.dart';
import '../../features/queue/live_queue_screen.dart';
import '../../features/review/review_screen.dart';
import '../../features/splash/splash_screen.dart';
import 'route_guards.dart';
import 'route_paths.dart';

final appRouterKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: appRouterKey,
    initialLocation: RoutePaths.splash,
    refreshListenable:
        GoRouterRefreshStream(ref.watch(authControllerProvider.notifier).stream),
    redirect: authRedirect,
    routes: [
      // ── Public ──────────────────────────────────────────────
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

      // ── Customer shell (bottom nav) ──────────────────────────
      ShellRoute(
        builder: (context, state, child) => _CustomerShell(child: child),
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

      // ── Search → redirect to explore ────────────────────────
      GoRoute(
        path: '/search',
        redirect: (context, state) {
          final service = state.uri.queryParameters['service'];
          if (service != null && service.isNotEmpty) {
            return '/home/explore?service=$service';
          }
          return '/home/explore';
        },
      ),

      // ── Barber walk-in (redirect to queue screen) ────────────
      GoRoute(
        path: '/barber/walkin',
        redirect: (_, __) => RoutePaths.barberQueue,
      ),

      // ── Customer standalone routes ───────────────────────────
      GoRoute(
        path: RoutePaths.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RoutePaths.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.myReviews,
        builder: (context, state) => const MyReviewsScreen(),
      ),
      GoRoute(
        path: RoutePaths.map,
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: RoutePaths.history,
        builder: (context, state) => const BookingHistoryPage(),
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
          shopName: state.uri.queryParameters['name'] ?? '',
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
      GoRoute(
        path: RoutePaths.services,
        builder: (context, state) => const ServicesSelectionPage(),
      ),
      GoRoute(
        path: RoutePaths.timing,
        builder: (context, state) => const BookingTimingPage(),
      ),
      GoRoute(
        path: RoutePaths.confirmation,
        builder: (context, state) => const BookingConfirmationPage(),
      ),

      // ── Barber shell (bottom nav) ────────────────────────────
      ShellRoute(
        builder: (context, state, child) => _BarberShell(child: child),
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
      GoRoute(
        path: RoutePaths.barberDetails,
        builder: (context, state) => BarberDetailsPage(
          barberId: state.pathParameters['barberId']!,
        ),
      ),

      // ── Admin shell ──────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => _AdminShell(child: child),
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

// ── GoRouter refresh helper ────────────────────────────────────

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// ── Customer shell ─────────────────────────────────────────────

class _CustomerShell extends ConsumerWidget {
  const _CustomerShell({required this.child});
  final Widget child;

  static const _tabs = [
    RoutePaths.home,
    RoutePaths.explore,
    RoutePaths.bookings,
    RoutePaths.profile,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    for (int i = _tabs.length - 1; i >= 0; i--) {
      if (location.startsWith(_tabs[i])) {
        currentIndex = i;
        break;
      }
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: child,
        bottomNavigationBar: CustomerNavBar(
          currentIndex: currentIndex,
          onTap: (index) => context.go(_tabs[index]),
        ),
      ),
    );
  }
}

// ── Barber shell ───────────────────────────────────────────────

class _BarberShell extends StatelessWidget {
  const _BarberShell({required this.child});
  final Widget child;

  static const _tabs = [
    RoutePaths.barberHome,
    RoutePaths.barberQueue,
    RoutePaths.barberSchedule,
    RoutePaths.barberProfile,
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    for (int i = _tabs.length - 1; i >= 0; i--) {
      if (location.startsWith(_tabs[i])) {
        currentIndex = i;
        break;
      }
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: child,
        bottomNavigationBar: BarberBottomNav(
          currentIndex: currentIndex,
          onTap: (index) => context.go(_tabs[index]),
        ),
      ),
    );
  }
}

// ── Admin shell ────────────────────────────────────────────────

class _AdminShell extends StatelessWidget {
  const _AdminShell({required this.child});
  final Widget child;

  static const _tabs = [
    RoutePaths.adminHome,
    RoutePaths.adminShops,
    RoutePaths.adminUsers,
    RoutePaths.adminBookings,
    RoutePaths.adminReports,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    for (int i = _tabs.length - 1; i >= 0; i--) {
      if (location.startsWith(_tabs[i])) {
        currentIndex = i;
        break;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(_tabs[index]),
        backgroundColor: colors.bgSurface,
        indicatorColor: BBColors.brandPrimaryDim,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store_rounded),
            label: 'Shops',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
