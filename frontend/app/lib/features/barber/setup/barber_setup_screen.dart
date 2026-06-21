import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/bb_button.dart';
import '../../../core/widgets/bb_text_field.dart';
import '../dashboard/barber_provider.dart';

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
          'latitude': 0.0,
          'longitude': 0.0,
          'services': [],
          'chairs': [
            {'number': 1},
          ],
        },
      );
      if (!mounted) return;
      // Reload barber dashboard after setup
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
          icon: const Icon(Icons.arrow_back_rounded),
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
              prefixIcon: Icons.store_rounded,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: BBSpacing.base),
            BBTextField(
              label: 'Description',
              hint: 'Brief description of your shop',
              controller: _descCtrl,
              prefixIcon: Icons.description_outlined,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: BBSpacing.base),
            BBTextField(
              label: 'Street Address *',
              hint: 'e.g. 123 Main Street',
              controller: _addressCtrl,
              prefixIcon: Icons.location_on_outlined,
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
                    prefixIcon: Icons.location_city_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: BBSpacing.sm),
                Expanded(
                  child: BBTextField(
                    label: 'State *',
                    hint: 'e.g. Maharashtra',
                    controller: _stateCtrl,
                    prefixIcon: Icons.map_outlined,
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
              prefixIcon: Icons.public_rounded,
              textInputAction: TextInputAction.done,
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
                    const Icon(Icons.error_outline_rounded,
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
              icon: Icons.store_rounded,
            ),
            const SizedBox(height: BBSpacing.xxl),
          ],
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
                  color: BBColors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(BBRadius.lg),
                ),
                child: const Icon(
                  Icons.content_cut_rounded,
                  size: 32,
                  color: BBColors.amber,
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
                icon: Icons.queue_rounded,
                title: 'Live Queue Management',
                subtitle: 'Manage walk-ins and bookings in real time',
              ),
              const SizedBox(height: BBSpacing.md),
              _FeatureRow(
                icon: Icons.bar_chart_rounded,
                title: 'Analytics & Earnings',
                subtitle: 'Track your daily performance',
              ),
              const SizedBox(height: BBSpacing.md),
              _FeatureRow(
                icon: Icons.notifications_outlined,
                title: 'Instant Notifications',
                subtitle: 'Get alerts when customers book',
              ),
              const Spacer(),
              BBButton(
                label: 'Set Up My Shop',
                onPressed: onContinue,
                icon: Icons.arrow_forward_rounded,
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
            color: BBColors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(BBRadius.md),
          ),
          child: Icon(icon, size: 20, color: BBColors.amber),
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
