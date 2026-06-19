import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../features/auth/domain/auth_state.dart';
import 'route_paths.dart';

String? authRedirect(BuildContext context, GoRouterState state) {
  final authState = ProviderScope.containerOf(context).read(authControllerProvider);
  final isAuth = authState is AuthAuthenticated;
  final isLoading = authState is AuthLoading;

  const publicRoutes = [
    RoutePaths.splash,
    RoutePaths.onboarding,
    RoutePaths.login,
    RoutePaths.register,
  ];

  final isPublic = publicRoutes.contains(state.matchedLocation);

  // During loading stay put — let the current screen show its own spinner.
  if (isLoading) return null;

  if (!isAuth && !isPublic) {
    return RoutePaths.login;
  }

  if (isAuth) {
    final user = authState.user;

    // Authenticated user on a public screen (except splash) → send to role home.
    if (isPublic && state.matchedLocation != RoutePaths.splash) {
      return user.role == 'barber'
          ? RoutePaths.barberHome
          : user.role == 'admin'
              ? RoutePaths.adminHome
              : RoutePaths.home;
    }

    // Wrong-role guards
    if (state.matchedLocation.startsWith('/barber') && user.role != 'barber') {
      return RoutePaths.home;
    }
    if (state.matchedLocation.startsWith('/admin') && user.role != 'admin') {
      return RoutePaths.home;
    }
  }

  return null;
}
