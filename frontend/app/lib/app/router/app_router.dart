import 'package:flutter/material.dart';
import '../../core/design/app_icons.dart';
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
import '../../features/barber/qr/barber_qr_screen.dart';
import '../../features/barber/barber_shell.dart';
import '../../features/barber/employees/employees_screen.dart';
import '../../features/barber/reception/reception_screen.dart';
import '../../features/barber/services/barber_services_screen.dart';
import '../../features/barber/shop/shop_management_screen.dart';
import '../../features/customer/notifications/notifications_screen.dart';
import '../../features/customer/payment/checkout_screen.dart';
import '../../features/barber/bookings/barber_bookings_screen.dart';
import '../../features/barber/dashboard/barber_dashboard_screen.dart';
import '../../features/barber/profile/barber_profile_screen.dart';
import '../../features/barber/queue/barber_queue_screen.dart';
import '../../features/customer/arrival/smart_arrival_screen.dart';
import '../../features/customer/arrival/scan_checkin_screen.dart';
import '../../features/customer/gamification/gamification_screen.dart';
import '../../features/customer/booking/booking_flow_screen.dart';
import '../../features/customer/customer_shell.dart';
import '../../features/customer/favourites/favourites_screen.dart';
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
        if (path == '/' || path == '/login' || path == '/register') return null;
        return '/';
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
      GoRoute(
        path: '/favourites',
        builder: (_, _) => const FavouritesScreen(),
      ),
      GoRoute(
        path: '/arrival/:bookingId',
        builder: (_, state) =>
            SmartArrivalScreen(bookingId: state.pathParameters['bookingId']!),
      ),
      GoRoute(
        path: '/scan-checkin/:bookingId',
        builder: (_, state) =>
            ScanCheckInScreen(bookingId: state.pathParameters['bookingId']!),
      ),
      GoRoute(
        path: '/gamification',
        builder: (_, _) => const GamificationScreen(),
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
          path: '/barber/qr',
          builder: (_, _) => const BarberQrScreen()),
      GoRoute(
          path: '/barber/shop',
          builder: (_, _) => const ShopManagementScreen()),
      GoRoute(
          path: '/barber/reception',
          builder: (_, _) => const ReceptionScreen()),
      GoRoute(
          path: '/barber/employees',
          builder: (_, _) => const EmployeesScreen()),
      GoRoute(
          path: '/barber/services',
          builder: (_, _) => const BarberServicesScreen()),

      // Shared
      GoRoute(
          path: '/change-password',
          builder: (_, _) => const ChangePasswordScreen()),
      GoRoute(
          path: '/settings',
          builder: (_, _) => const AppSettingsScreen()),
      GoRoute(
          path: '/settings/notifications',
          builder: (_, _) => const NotificationPrefsScreen()),
      GoRoute(
          path: '/settings/privacy',
          builder: (_, _) => const PrivacySecurityScreen()),
      GoRoute(
          path: '/help',
          builder: (_, _) => const HelpCentreScreen()),
      GoRoute(
          path: '/support',
          builder: (_, _) => const ContactSupportScreen()),
      GoRoute(
          path: '/about',
          builder: (_, _) => const AboutScreen()),
      GoRoute(
          path: '/terms',
          builder: (_, _) => const TermsScreen()),
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
            _hide ? AppIcons.visibility : AppIcons.visibilityOff,
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
                  icon: AppIcons.brightnessAuto,
                  label: 'System Default',
                  subtitle: 'Matches your device setting',
                  selected: themeMode == ThemeMode.system,
                  onTap: () => ref
                      .read(themeProvider.notifier)
                      .setTheme(ThemeMode.system),
                ),
                Divider(color: colors.border, height: 1, indent: 52),
                _ThemeOption(
                  icon: AppIcons.lightMode,
                  label: 'Light',
                  subtitle: 'Always use light theme',
                  selected: themeMode == ThemeMode.light,
                  onTap: () => ref
                      .read(themeProvider.notifier)
                      .setTheme(ThemeMode.light),
                ),
                Divider(color: colors.border, height: 1, indent: 52),
                _ThemeOption(
                  icon: AppIcons.darkMode,
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
              Icon(AppIcons.checkCircleFill,
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
  int _overallRating = 0;
  final Map<String, int> _criteria = {
    'Haircut': 0,
    'Cleanliness': 0,
    'Wait Time': 0,
    'Staff': 0,
    'Value': 0,
  };
  final _commentCtrl = TextEditingController();
  double? _tipAmount;
  bool _loading = false;

  static const _tipOptions = [0.0, 20.0, 50.0, 100.0];

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
      body: SingleChildScrollView(
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

            // ── Overall rating ──────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Text(
                    'Overall',
                    style: BBTypography.textTheme.labelMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: BBSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (i) => GestureDetector(
                        onTap: () => setState(() => _overallRating = i + 1),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            i < _overallRating
                                ? AppIcons.starFill
                                : AppIcons.star,
                            size: 44,
                            color: BBColors.amber,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_overallRating > 0) ...[
                    const SizedBox(height: BBSpacing.xs),
                    Text(
                      ['', 'Poor', 'Fair', 'Good', 'Great', 'Excellent'][_overallRating],
                      style: BBTypography.textTheme.labelMedium?.copyWith(
                        color: BBColors.amber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: BBSpacing.xl),

            // ── Criteria rating ─────────────────────────────────────────
            Text(
              'RATE SPECIFIC ASPECTS',
              style: BBTypography.textTheme.labelSmall?.copyWith(
                color: colors.textTertiary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: BBSpacing.md),
            Container(
              padding: const EdgeInsets.all(BBSpacing.base),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(BBRadius.lg),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: _criteria.keys
                    .map((key) => Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: BBSpacing.sm),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(
                                  key,
                                  style:
                                      BBTypography.textTheme.labelMedium?.copyWith(
                                    color: colors.text,
                                  ),
                                ),
                              ),
                              ...List.generate(
                                5,
                                (i) => GestureDetector(
                                  onTap: () => setState(
                                      () => _criteria[key] = i + 1),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    child: Icon(
                                      i < (_criteria[key] ?? 0)
                                          ? AppIcons.starFill
                                          : AppIcons.star,
                                      size: 24,
                                      color: BBColors.amber,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: BBSpacing.xl),

            // ── Comment ─────────────────────────────────────────────────
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              style: TextStyle(color: colors.text),
              decoration: InputDecoration(
                hintText: 'Tell us about your experience...',
                hintStyle: TextStyle(color: colors.textTertiary),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: BBSpacing.xl),

            // ── Tip ─────────────────────────────────────────────────────
            Text(
              'TIP YOUR BARBER (optional)',
              style: BBTypography.textTheme.labelSmall?.copyWith(
                color: colors.textTertiary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: BBSpacing.sm),
            Row(
              children: _tipOptions
                  .map((t) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: BBSpacing.sm),
                          child: GestureDetector(
                            onTap: () => setState(() =>
                                _tipAmount = _tipAmount == t ? null : t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: BBSpacing.sm),
                              decoration: BoxDecoration(
                                color: _tipAmount == t
                                    ? BBColors.amber
                                    : colors.surfaceVariant,
                                borderRadius:
                                    BorderRadius.circular(BBRadius.md),
                                border: Border.all(
                                  color: _tipAmount == t
                                      ? BBColors.amber
                                      : colors.border,
                                ),
                              ),
                              child: Text(
                                t == 0 ? 'No tip' : '₹${t.toInt()}',
                                textAlign: TextAlign.center,
                                style:
                                    BBTypography.textTheme.labelMedium?.copyWith(
                                  color: _tipAmount == t
                                      ? colors.background
                                      : colors.text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: BBSpacing.xl),

            BBButton(
              label: 'Submit Review',
              onPressed: (_loading || _overallRating == 0) ? null : _submit,
              loading: _loading,
              disabled: _overallRating == 0,
            ),
            const SizedBox(height: BBSpacing.xl),
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
          'rating': _overallRating,
          'comment': _commentCtrl.text.trim(),
          'tags': <String>[],
          'criteria': _criteria
              .map((k, v) => MapEntry(k.toLowerCase().replaceAll(' ', '_'), v)),
          if (_tipAmount != null && _tipAmount! > 0) 'tip': _tipAmount,
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

// ─────────────── Payment History Screen ───────────────

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Payment History')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.receiptFill, size: 64, color: colors.textTertiary),
            const SizedBox(height: BBSpacing.base),
            Text(
              'No payments yet',
              style: BBTypography.textTheme.titleMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────── Notification Preferences Screen ───────────────

class NotificationPrefsScreen extends StatefulWidget {
  const NotificationPrefsScreen({super.key});

  @override
  State<NotificationPrefsScreen> createState() => _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends State<NotificationPrefsScreen> {
  bool _bookingUpdates = true;
  bool _queueAlerts = true;
  bool _offers = true;
  bool _loyaltyUpdates = true;
  bool _smsAlerts = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.pageHorizontal,
          vertical: BBSpacing.pageVertical,
        ),
        children: [
          _NotifSection(
            title: 'Push Notifications',
            children: [
              _SwitchRow(
                icon: AppIcons.calendar,
                label: 'Booking Updates',
                subtitle: 'Confirmations, cancellations, reminders',
                value: _bookingUpdates,
                onChanged: (v) => setState(() => _bookingUpdates = v),
              ),
              _SwitchRow(
                icon: AppIcons.queue,
                label: 'Queue Alerts',
                subtitle: "You're next, chair ready",
                value: _queueAlerts,
                onChanged: (v) => setState(() => _queueAlerts = v),
              ),
              _SwitchRow(
                icon: AppIcons.localOffer,
                label: 'Offers & Promotions',
                subtitle: 'Coupons, flash deals, seasonal offers',
                value: _offers,
                onChanged: (v) => setState(() => _offers = v),
              ),
              _SwitchRow(
                icon: AppIcons.loyalty,
                label: 'Loyalty Updates',
                subtitle: 'Points earned, tier upgrades',
                value: _loyaltyUpdates,
                onChanged: (v) => setState(() => _loyaltyUpdates = v),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.base),
          _NotifSection(
            title: 'SMS',
            children: [
              _SwitchRow(
                icon: AppIcons.sms,
                label: 'SMS Alerts',
                subtitle: 'Receive SMS for queue and booking updates',
                value: _smsAlerts,
                onChanged: (v) => setState(() => _smsAlerts = v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotifSection extends StatelessWidget {
  const _NotifSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: BBSpacing.sm),
          child: Text(
            title.toUpperCase(),
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
            children: children
                .expand((c) => [
                      c,
                      if (c != children.last)
                        Divider(color: colors.border, height: 1, indent: 52),
                    ])
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpacing.base,
        vertical: BBSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textSecondary),
          const SizedBox(width: BBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: BBTypography.textTheme.bodyMedium?.copyWith(
                    color: colors.text,
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: BBColors.amber,
          ),
        ],
      ),
    );
  }
}

// ─────────────── Privacy & Security Screen ───────────────

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _biometric = false;
  bool _shareLocation = true;
  bool _dataSaver = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.pageHorizontal,
          vertical: BBSpacing.pageVertical,
        ),
        children: [
          _NotifSection(
            title: 'Security',
            children: [
              _SwitchRow(
                icon: AppIcons.fingerprint,
                label: 'Biometric Login',
                subtitle: 'Use fingerprint or Face ID to sign in',
                value: _biometric,
                onChanged: (v) => setState(() => _biometric = v),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.base),
          _NotifSection(
            title: 'Privacy',
            children: [
              _SwitchRow(
                icon: AppIcons.locationOn,
                label: 'Share Location',
                subtitle: 'Used for finding nearby shops',
                value: _shareLocation,
                onChanged: (v) => setState(() => _shareLocation = v),
              ),
              _SwitchRow(
                icon: AppIcons.dataUsage,
                label: 'Data Saver',
                subtitle: 'Reduce data usage on mobile networks',
                value: _dataSaver,
                onChanged: (v) => setState(() => _dataSaver = v),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.xl),
          Container(
            padding: const EdgeInsets.all(BBSpacing.base),
            decoration: BoxDecoration(
              color: BBColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(BBRadius.lg),
              border: Border.all(color: BBColors.error.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Danger Zone',
                  style: BBTypography.textTheme.labelMedium?.copyWith(
                    color: BBColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: BBSpacing.sm),
                Text(
                  'Deleting your account is permanent and cannot be undone.',
                  style: BBTypography.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: BBSpacing.md),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: BBColors.error,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(AppIcons.deleteIcon, size: 18),
                  label: const Text('Delete My Account'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'All your data, bookings, and loyalty points will be permanently deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            style: TextButton.styleFrom(foregroundColor: BBColors.error),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deletion requested')),
      );
    }
  }
}

// ─────────────── Help Centre Screen ───────────────

class HelpCentreScreen extends StatelessWidget {
  const HelpCentreScreen({super.key});

  static const _faqs = [
    ('How do I book an appointment?', 'Browse shops, select services and barber, then confirm your booking from the shop detail page.'),
    ('Can I cancel my booking?', 'Yes, you can cancel from Booking History or the Queue Tracker screen while your booking is active.'),
    ('How do loyalty points work?', 'Earn 10 points for every ₹100 spent. Redeem 100 points for ₹10 off your next booking.'),
    ('What payment methods are accepted?', 'We accept UPI, debit/credit cards, and BookBer Wallet. Cash is also accepted at the shop.'),
    ('How do I track my queue position?', 'After booking, go to your active booking from the Home screen to see real-time queue updates.'),
    ('How do I refer friends?', 'Go to Profile → Referrals to find your unique referral code. Share it with friends and earn 50 points when they complete their first booking.'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Help Centre')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.pageHorizontal,
          vertical: BBSpacing.pageVertical,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(BBSpacing.base),
            decoration: BoxDecoration(
              color: BBColors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(BBRadius.lg),
              border: Border.all(color: BBColors.amber.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(AppIcons.support,
                    color: BBColors.amber, size: 28),
                const SizedBox(width: BBSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need more help?',
                        style: BBTypography.textTheme.titleSmall?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Chat with our support team',
                        style: BBTypography.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(AppIcons.arrowForwardSmall,
                    size: 14, color: BBColors.amber),
              ],
            ),
          ),
          const SizedBox(height: BBSpacing.xl),
          Text(
            'FREQUENTLY ASKED QUESTIONS',
            style: BBTypography.textTheme.labelSmall?.copyWith(
              color: colors.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: BBSpacing.sm),
          ..._faqs.map((faq) => _FaqItem(question: faq.$1, answer: faq.$2)),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      margin: const EdgeInsets.only(bottom: BBSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(BBRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(BBSpacing.base),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: BBTypography.textTheme.bodyMedium?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? AppIcons.arrowUp
                        : AppIcons.arrowDown,
                    size: 20,
                    color: colors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BBSpacing.base, 0, BBSpacing.base, BBSpacing.base),
              child: Text(
                widget.answer,
                style: BBTypography.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────── Contact Support Screen ───────────────

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Contact Support')),
      body: Padding(
        padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BBSpacing.base),
            Text(
              'How can we help you?',
              style: BBTypography.textTheme.headlineSmall?.copyWith(
                color: colors.text,
              ),
            ),
            const SizedBox(height: BBSpacing.xs),
            Text(
              'Describe your issue and we will get back to you within 24 hours.',
              style: BBTypography.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: BBSpacing.xl),
            TextField(
              controller: _ctrl,
              maxLines: 6,
              style: TextStyle(color: colors.text),
              decoration: InputDecoration(
                hintText: 'Describe your issue...',
                hintStyle: TextStyle(color: colors.textTertiary),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: BBSpacing.xl),
            ElevatedButton(
              onPressed: _sending
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(context);
                      setState(() => _sending = true);
                      await Future.delayed(const Duration(seconds: 1));
                      if (!mounted) return;
                      setState(() => _sending = false);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Message sent! We will reply within 24 hours.'),
                        ),
                      );
                      nav.pop();
                    },
              child: _sending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Message'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────── About Screen ───────────────

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('About BookBer')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.pageHorizontal,
          vertical: BBSpacing.pageVertical,
        ),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: BBColors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(BBRadius.xl),
                  ),
                  child: const Center(
                    child: Icon(AppIcons.scissors,
                        size: 40, color: BBColors.amber),
                  ),
                ),
                const SizedBox(height: BBSpacing.md),
                Text(
                  'BookBer',
                  style: BBTypography.textTheme.headlineLarge?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Premium Barber Booking',
                  style: BBTypography.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: BBSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(BBRadius.full),
                  ),
                  child: Text(
                    'Version 2.0.0',
                    style: BBTypography.textTheme.labelMedium?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BBSpacing.xl),
          Text(
            'BookBer is the fastest way to book your next haircut. Find the best barbers near you, join the queue in seconds, and track your appointment in real time.',
            style: BBTypography.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BBSpacing.xl),
          _AboutRow(icon: AppIcons.mail, label: 'support@bookber.app'),
          _AboutRow(icon: AppIcons.language, label: 'www.bookber.app'),
          _AboutRow(
              icon: AppIcons.privacy, label: 'Privacy Policy'),
          _AboutRow(
              icon: AppIcons.description, label: 'Terms of Service'),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BBSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textSecondary),
          const SizedBox(width: BBSpacing.md),
          Text(
            label,
            style: BBTypography.textTheme.bodyMedium?.copyWith(
              color: colors.text,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── Terms Screen ───────────────

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Terms & Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
        children: [
          const SizedBox(height: BBSpacing.base),
          _TermsSection(
            title: 'Terms of Service',
            body:
                'By using BookBer, you agree to book services honestly, treat barbers with respect, and arrive on time for your appointments. Excessive no-shows may result in account suspension.',
          ),
          const SizedBox(height: BBSpacing.base),
          _TermsSection(
            title: 'Privacy Policy',
            body:
                'We collect your name, email, phone number, and location (when permitted) to provide barber booking services. We do not sell your data to third parties. You can request deletion of your data at any time from Settings.',
          ),
          const SizedBox(height: BBSpacing.base),
          _TermsSection(
            title: 'Refund Policy',
            body:
                'Wallet top-ups are non-refundable once used. Booking cancellations made more than 30 minutes before the appointment may be eligible for a wallet credit.',
          ),
          const SizedBox(height: BBSpacing.xl),
          Text(
            'Last updated: June 2026',
            style: BBTypography.textTheme.labelSmall?.copyWith(
              color: colors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: BBTypography.textTheme.titleMedium?.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: BBSpacing.sm),
          Text(
            body,
            style: BBTypography.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
