import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/bb_colors.dart';
import '../../core/design/bb_tokens.dart';
import '../../core/design/bb_typography.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/widgets/bb_button.dart';
import '../../features/admin/admin_screen.dart';
import '../../features/auth/data/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/barber/analytics/analytics_screen.dart';
import '../../features/barber/barber_shell.dart';
import '../../features/barber/shop/shop_management_screen.dart';
import '../../features/customer/notifications/notifications_screen.dart';
import '../../features/customer/payment/checkout_screen.dart';
import '../../features/barber/bookings/barber_bookings_screen.dart';
import '../../features/barber/dashboard/barber_dashboard_screen.dart';
import '../../features/barber/profile/barber_profile_screen.dart';
import '../../features/barber/queue/barber_queue_screen.dart';
import '../../features/customer/booking/booking_flow_screen.dart';
import '../../features/customer/customer_shell.dart';
import '../../features/customer/home/home_screen.dart';
import '../../features/customer/loyalty/loyalty_screen.dart';
import '../../features/customer/profile/bookings_screen.dart';
import '../../features/customer/profile/my_reviews_screen.dart';
import '../../features/customer/profile/profile_screen.dart';
import '../../features/customer/queue/queue_tracker_screen.dart';
import '../../features/customer/referral/referral_screen.dart';
import '../../features/customer/shops/shop_detail_screen.dart';
import '../../features/customer/shops/shops_screen.dart';
import '../../features/customer/wallet/wallet_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _customerKey = GlobalKey<NavigatorState>();
final _barberKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: AuthStateListenable(ref),
    redirect: (ctx, state) {
      final auth = ref.read(authProvider);
      final path = state.uri.path;

      if (auth is AuthInitial || auth is AuthLoading) {
        return path == '/' ? null : '/';
      }
      if (auth is AuthUnauthenticated || auth is AuthError) {
        if (path == '/login' || path == '/register') return null;
        return '/login';
      }
      if (auth is AuthAuthenticated) {
        if (path == '/' || path == '/login' || path == '/register') {
          if (auth.user.isBarber) return '/barber';
          if (auth.user.isAdmin) return '/admin';
          return '/home';
        }
        if (auth.user.isBarber &&
            !path.startsWith('/barber') &&
            path != '/change-password' &&
            path != '/settings') {
          return '/barber';
        }
        if (auth.user.isCustomer && path.startsWith('/barber')) {
          return '/home';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/admin', builder: (_, _) => const AdminScreen()),

      // Customer shell
      ShellRoute(
        navigatorKey: _customerKey,
        builder: (_, _, child) => CustomerShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/shops', builder: (_, _) => const ShopsScreen()),
          GoRoute(
              path: '/bookings', builder: (_, _) => const BookingsScreen()),
          GoRoute(
              path: '/profile', builder: (_, _) => const ProfileScreen()),
        ],
      ),

      // Customer full-screen routes
      GoRoute(
        path: '/shops/:shopId',
        builder: (_, state) =>
            ShopDetailScreen(shopId: state.pathParameters['shopId']!),
      ),
      GoRoute(
        path: '/shops/:shopId/book',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return BookingFlowScreen(
            shopId: state.pathParameters['shopId']!,
            shopName: extra['shopName']?.toString() ?? '',
            joinQueue: extra['joinQueue'] == true,
          );
        },
      ),
      GoRoute(
        path: '/queue/:bookingId',
        builder: (_, state) =>
            QueueTrackerScreen(bookingId: state.pathParameters['bookingId']!),
      ),
      GoRoute(
        path: '/reviews',
        builder: (_, _) => const MyReviewsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CheckoutScreen(
            bookingId: extra['bookingId']?.toString() ?? '',
            amount: (extra['amount'] as num?)?.toDouble() ?? 0.0,
            shopName: extra['shopName']?.toString() ?? '',
            serviceName: extra['serviceName']?.toString() ?? '',
          );
        },
      ),
      GoRoute(
        path: '/payments/history',
        builder: (_, _) => const PaymentHistoryScreen(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (_, _) => const WalletScreen(),
      ),
      GoRoute(
        path: '/loyalty',
        builder: (_, _) => const LoyaltyScreen(),
      ),
      GoRoute(
        path: '/referral',
        builder: (_, _) => const ReferralScreen(),
      ),

      // Barber shell
      ShellRoute(
        navigatorKey: _barberKey,
        builder: (_, _, child) => BarberShell(child: child),
        routes: [
          GoRoute(
              path: '/barber',
              builder: (_, _) => const BarberDashboardScreen()),
          GoRoute(
              path: '/barber/queue',
              builder: (_, _) => const BarberQueueScreen()),
          GoRoute(
              path: '/barber/bookings',
              builder: (_, _) => const BarberBookingsScreen()),
          GoRoute(
              path: '/barber/profile',
              builder: (_, _) => const BarberProfileScreen()),
          GoRoute(
              path: '/barber/analytics',
              builder: (_, _) => const BarberAnalyticsScreen()),
        ],
      ),

      // Barber full-screen routes (outside shell — no bottom nav)
      GoRoute(
          path: '/barber/shop',
          builder: (_, _) => const ShopManagementScreen()),

      // Shared
      GoRoute(
          path: '/change-password',
          builder: (_, _) => const ChangePasswordScreen()),
      GoRoute(
          path: '/settings',
          builder: (_, _) => const AppSettingsScreen()),
      GoRoute(
          path: '/review/:bookingId',
          builder: (_, state) =>
              ReviewScreen(bookingId: state.pathParameters['bookingId']!)),
    ],
  );
});

class AuthStateListenable extends ChangeNotifier {
  AuthStateListenable(Ref ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
  }
}

// ─────────────── Change Password Screen ───────────────

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() {
        _error = 'New passwords do not match';
        _loading = false;
      });
      return;
    }
    if (_newCtrl.text.length < 6) {
      setState(() {
        _error = 'Password must be at least 6 characters';
        _loading = false;
      });
      return;
    }
    try {
      final api = ref.read(apiClientProvider);
      await api.patch<void>(
        '/auth/change-password',
        body: {
          'currentPassword': _currentCtrl.text,
          'newPassword': _newCtrl.text,
        },
      );
      setState(() {
        _success = true;
        _loading = false;
      });
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BBSpacing.base),
            _PwField(label: 'Current Password', ctrl: _currentCtrl),
            const SizedBox(height: BBSpacing.md),
            _PwField(label: 'New Password', ctrl: _newCtrl),
            const SizedBox(height: BBSpacing.md),
            _PwField(label: 'Confirm New Password', ctrl: _confirmCtrl),
            if (_error != null) ...[
              const SizedBox(height: BBSpacing.sm),
              Container(
                padding: const EdgeInsets.all(BBSpacing.md),
                decoration: BoxDecoration(
                  color: BBColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(BBRadius.md),
                  border: Border.all(
                      color: BBColors.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _error!,
                  style: BBTypography.textTheme.bodySmall
                      ?.copyWith(color: BBColors.error),
                ),
              ),
            ],
            if (_success) ...[
              const SizedBox(height: BBSpacing.sm),
              Container(
                padding: const EdgeInsets.all(BBSpacing.md),
                decoration: BoxDecoration(
                  color: BBColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(BBRadius.md),
                  border: Border.all(
                      color: BBColors.success.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Password updated successfully!',
                  style: BBTypography.textTheme.bodySmall
                      ?.copyWith(color: BBColors.success),
                ),
              ),
            ],
            const SizedBox(height: BBSpacing.xl),
            BBButton(
              label: 'Update Password',
              onPressed: _loading ? null : _submit,
              loading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}

class _PwField extends StatefulWidget {
  const _PwField({required this.label, required this.ctrl});
  final String label;
  final TextEditingController ctrl;

  @override
  State<_PwField> createState() => _PwFieldState();
}

class _PwFieldState extends State<_PwField> {
  bool _hide = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return TextField(
      controller: widget.ctrl,
      obscureText: _hide,
      style: TextStyle(color: colors.text),
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          icon: Icon(
            _hide ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _hide = !_hide),
        ),
      ),
    );
  }
}

// ─────────────── App Settings Screen ───────────────

class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.pageHorizontal,
          vertical: BBSpacing.pageVertical,
        ),
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 2, bottom: BBSpacing.sm),
            child: Text(
              'THEME',
              style: BBTypography.textTheme.labelSmall?.copyWith(
                color: colors.textTertiary,
                letterSpacing: 1,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(BBRadius.lg),
              border: Border.all(color: colors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _ThemeOption(
                  icon: Icons.brightness_auto_rounded,
                  label: 'System Default',
                  subtitle: 'Matches your device setting',
                  selected: themeMode == ThemeMode.system,
                  onTap: () => ref
                      .read(themeProvider.notifier)
                      .setTheme(ThemeMode.system),
                ),
                Divider(color: colors.border, height: 1, indent: 52),
                _ThemeOption(
                  icon: Icons.light_mode_rounded,
                  label: 'Light',
                  subtitle: 'Always use light theme',
                  selected: themeMode == ThemeMode.light,
                  onTap: () => ref
                      .read(themeProvider.notifier)
                      .setTheme(ThemeMode.light),
                ),
                Divider(color: colors.border, height: 1, indent: 52),
                _ThemeOption(
                  icon: Icons.dark_mode_rounded,
                  label: 'Dark',
                  subtitle: 'Always use dark theme',
                  selected: themeMode == ThemeMode.dark,
                  onTap: () => ref
                      .read(themeProvider.notifier)
                      .setTheme(ThemeMode.dark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.base,
          vertical: BBSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? BBColors.amber.withValues(alpha: 0.12)
                    : colors.surfaceVariant,
                borderRadius: BorderRadius.circular(BBRadius.sm),
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected ? BBColors.amber : colors.textSecondary,
              ),
            ),
            const SizedBox(width: BBSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: BBTypography.textTheme.bodyMedium?.copyWith(
                      color: colors.text,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: BBTypography.textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded,
                  size: 20, color: BBColors.amber),
          ],
        ),
      ),
    );
  }
}

// ─────────────── Review Screen ───────────────

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Leave a Review')),
      body: Padding(
        padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BBSpacing.base),
            Text(
              'How was your experience?',
              style: BBTypography.textTheme.headlineSmall
                  ?.copyWith(color: colors.text),
            ),
            const SizedBox(height: BBSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 44,
                      color: BBColors.amber,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: BBSpacing.xl),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              style: TextStyle(color: colors.text),
              decoration: const InputDecoration(
                hintText: 'Tell us about your experience...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: BBSpacing.xl),
            BBButton(
              label: 'Submit Review',
              onPressed: (_loading || _rating == 0) ? null : _submit,
              loading: _loading,
              disabled: _rating == 0,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<void>(
        '/reviews',
        body: {
          'bookingId': widget.bookingId,
          'rating': _rating,
          'comment': _commentCtrl.text.trim(),
          'tags': <String>[],
        },
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }
}
