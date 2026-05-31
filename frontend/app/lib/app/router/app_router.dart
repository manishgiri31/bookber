import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/booking/presentation/pages/booking_confirmation_page.dart';
import '../../features/booking/presentation/pages/booking_history_page.dart';
import '../../features/booking/presentation/pages/booking_timing_page.dart';
import '../../features/booking/presentation/pages/barber_details_page.dart';
import '../../features/booking/presentation/pages/home_discovery_page.dart';
import '../../features/booking/presentation/pages/queue_tracking_page.dart';
import '../../features/booking/presentation/pages/services_selection_page.dart';
import '../../features/barber_dashboard/presentation/pages/barber_dashboard_page.dart';
import '../../features/maps/presentation/map_screen.dart';
import 'route_paths.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = _RouterNotifier(ref);
  ref.onDispose(routerNotifier.dispose);

  return GoRouter(
    initialLocation: RoutePaths.home,
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider).asData?.value;
      if (auth == null) return null;
      if (!auth.isAuthenticated && state.matchedLocation != RoutePaths.home) {
        return RoutePaths.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomeDiscoveryPage(),
      ),
      GoRoute(path: '/', builder: (context, state) => const MapScreen()),
      GoRoute(
        path: '/barber/:barberId',
        builder: (context, state) =>
            BarberDetailsPage(barberId: state.pathParameters['barberId']!),
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
      GoRoute(
        path: '/queue/:bookingId',
        builder: (context, state) =>
            QueueTrackingPage(bookingId: state.pathParameters['bookingId']!),
      ),
      GoRoute(
        path: RoutePaths.history,
        builder: (context, state) => const BookingHistoryPage(),
      ),
      GoRoute(
        path: RoutePaths.barberDashboard,
        builder: (context, state) => const BarberDashboardPage(),
      ),
    ],
  );
});

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this.ref) {
    ref.listen(authControllerProvider, (previous, next) => notifyListeners());
  }

  final Ref ref;
}
