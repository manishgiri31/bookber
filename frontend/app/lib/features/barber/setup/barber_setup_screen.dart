import 'package:flutter/material.dart';
import '../../../core/design/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/bb_button.dart';
import '../../../core/widgets/bb_text_field.dart';
import '../dashboard/barber_provider.dart';
import '../../../core/design/bb_colors.dart';

class BarberSetupScreen extends ConsumerStatefulWidget {
  const BarberSetupScreen({super.key});

  @override
  ConsumerState<BarberSetupScreen> createState() => _BarberSetupScreenState();
}

class _BarberSetupScreenState extends ConsumerState<BarberSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'India');
  final _descCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  int _step = 0;
  int _chairs = 2;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _addressCtrl.text.trim().isEmpty ||
        _cityCtrl.text.trim().isEmpty ||
        _stateCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all required fields');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final location = ref.read(locationProvider).valueOrNull;
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        '/shops',
        body: {
          'name': _nameCtrl.text.trim(),
          'description': _descCtrl.text.trim().isNotEmpty
              ? _descCtrl.text.trim()
              : null,
          'address': _addressCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'state': _stateCtrl.text.trim(),
          'country': _countryCtrl.text.trim(),
          'latitude': location?.latitude ?? 0.0,
          'longitude': location?.longitude ?? 0.0,
          'services': [],
          'chairs': List.generate(_chairs, (i) => {'number': i + 1}),
        },
      );
      if (!mounted) return;
      await ref.read(barberDashProvider.notifier).refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    if (_step == 0) {
      return _WelcomeStep(onContinue: () => setState(() => _step = 1));
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Set Up Your Shop'),
        leading: IconButton(
          icon: const Icon(AppIcons.arrowBack),
          onPressed: () => setState(() => _step = 0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.pageHorizontal,
          vertical: BBSpacing.pageVertical,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shop Details',
              style: BBTypography.textTheme.headlineSmall?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BBSpacing.xs),
            Text(
              'Tell us about your barber shop.',
              style: BBTypography.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: BBSpacing.xl),
            BBTextField(
              label: 'Shop Name *',
              hint: 'e.g. Classic Cuts',
              controller: _nameCtrl,
              prefixIcon: AppIcons.store,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: BBSpacing.base),
            BBTextField(
              label: 'Description',
              hint: 'Brief description of your shop',
              controller: _descCtrl,
              prefixIcon: AppIcons.description,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: BBSpacing.base),
            BBTextField(
              label: 'Street Address *',
              hint: 'e.g. 123 Main Street',
              controller: _addressCtrl,
              prefixIcon: AppIcons.locationOn,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: BBSpacing.base),
            Row(
              children: [
                Expanded(
                  child: BBTextField(
                    label: 'City *',
                    hint: 'e.g. Mumbai',
                    controller: _cityCtrl,
                    prefixIcon: AppIcons.locationCity,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: BBSpacing.sm),
                Expanded(
                  child: BBTextField(
                    label: 'State *',
                    hint: 'e.g. Maharashtra',
                    controller: _stateCtrl,
                    prefixIcon: AppIcons.map,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BBSpacing.base),
            BBTextField(
              label: 'Country',
              hint: 'India',
              controller: _countryCtrl,
              prefixIcon: AppIcons.public,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: BBSpacing.base),
            // Chairs stepper
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: BBSpacing.base,
                vertical: BBSpacing.md,
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(BBRadius.lg),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.chair,
                      size: 18, color: colors.textSecondary),
                  const SizedBox(width: BBSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Number of Chairs',
                          style: BBTypography.textTheme.labelSmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                        Text(
                          '$_chairs chair${_chairs == 1 ? '' : 's'}',
                          style: BBTypography.textTheme.bodyMedium?.copyWith(
                            color: colors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _StepperButton(
                        icon: AppIcons.remove,
                        onTap: _chairs > 1
                            ? () => setState(() => _chairs--)
                            : null,
                      ),
                      const SizedBox(width: BBSpacing.sm),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$_chairs',
                          textAlign: TextAlign.center,
                          style: BBTypography.textTheme.titleMedium?.copyWith(
                            color: colors.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: BBSpacing.sm),
                      _StepperButton(
                        icon: AppIcons.add,
                        onTap: _chairs < 20
                            ? () => setState(() => _chairs++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Location indicator
            Consumer(
              builder: (context, ref, _) {
                final locationAsync = ref.watch(locationProvider);
                return locationAsync.when(
                  data: (loc) {
                    if (loc == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: BBSpacing.sm),
                      child: Row(
                        children: [
                          Icon(AppIcons.myLocation,
                              size: 14, color: BBColors.success),
                          const SizedBox(width: 4),
                          Text(
                            loc.cityName != null
                                ? 'Location detected: ${loc.cityName}'
                                : 'Location detected',
                            style: BBTypography.textTheme.labelSmall?.copyWith(
                              color: BBColors.success,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                );
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: BBSpacing.base),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: BBSpacing.base,
                  vertical: BBSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: BBColors.errorSurface,
                  borderRadius: BorderRadius.circular(BBRadius.md),
                  border: Border.all(color: BBColors.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.error,
                        color: BBColors.error, size: 18),
                    const SizedBox(width: BBSpacing.sm),
                    Expanded(
                      child: Text(
                        _error!,
                        style: BBTypography.textTheme.bodySmall
                            ?.copyWith(color: BBColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: BBSpacing.xl),
            BBButton(
              label: 'Create Shop',
              onPressed: _submit,
              loading: _loading,
              icon: AppIcons.store,
            ),
            const SizedBox(height: BBSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? colors.surfaceVariant : colors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(BBRadius.md),
          border: Border.all(color: colors.border),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? colors.text : colors.textTertiary,
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BBSpacing.pageHorizontal,
            vertical: BBSpacing.pageVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(BBRadius.lg),
                ),
                child: Icon(
                  AppIcons.scissors,
                  size: 32,
                  color: colors.accent,
                ),
              ),
              const SizedBox(height: BBSpacing.xl),
              Text(
                'Welcome to BookBer',
                style: BBTypography.textTheme.displaySmall?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: BBSpacing.sm),
              Text(
                "Let's get your shop set up. You'll be able to manage bookings, "
                'your queue, and track your earnings — all in one place.',
                style: BBTypography.textTheme.bodyLarge?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: BBSpacing.xl),
              _FeatureRow(
                icon: AppIcons.queue,
                title: 'Live Queue Management',
                subtitle: 'Manage walk-ins and bookings in real time',
              ),
              const SizedBox(height: BBSpacing.md),
              _FeatureRow(
                icon: AppIcons.barChart,
                title: 'Analytics & Earnings',
                subtitle: 'Track your daily performance',
              ),
              const SizedBox(height: BBSpacing.md),
              _FeatureRow(
                icon: AppIcons.notifications,
                title: 'Instant Notifications',
                subtitle: 'Get alerts when customers book',
              ),
              const Spacer(),
              BBButton(
                label: 'Set Up My Shop',
                onPressed: onContinue,
                icon: AppIcons.arrowForward,
              ),
              const SizedBox(height: BBSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(BBRadius.md),
          ),
          child: Icon(icon, size: 20, color: colors.accent),
        ),
        const SizedBox(width: BBSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: BBTypography.textTheme.titleSmall?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: BBTypography.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
