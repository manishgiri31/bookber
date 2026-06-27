import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_button.dart';
import '../../../core/widgets/bb_loading.dart';
import '../../shared/domain/shop_models.dart';
import '../shops/shops_provider.dart';
import 'booking_provider.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  const BookingFlowScreen({
    super.key,
    required this.shopId,
    this.shopName = '',
    this.joinQueue = false,
  });

  final String shopId;
  final String shopName;
  final bool joinQueue;

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  int _step = 0; // 0=services, 1=barber, 2=confirm
  bool _submitting = false;
  String? _submitError;

  late final _formArg = (shopId: widget.shopId, shopName: widget.shopName);

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final form = ref.watch(bookingFormFamily(_formArg));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(_stepTitle),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (_step + 1) / 3,
            backgroundColor: colors.border,
            valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
            minHeight: 3,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildStep(_step),
              ),
            ),
            if (_submitError != null)
              _ErrorBanner(
                message: _submitError!,
                onDismiss: () => setState(() => _submitError = null),
              ),
            _BottomBar(
              step: _step,
              canProceed: form.selectedService != null,
              submitting: _submitting,
              onBack: _step > 0 ? () => setState(() { _step--; _submitError = null; }) : null,
              onNext: _step == 0 && form.selectedService == null
                  ? null
                  : _handleNext,
            ),
          ],
        ),
      ),
    );
  }

  String get _stepTitle => switch (_step) {
        0 => 'Select Service',
        1 => 'Choose Barber',
        _ => 'Confirm Booking',
      };

  Widget _buildStep(int step) => switch (step) {
        0 => _ServicesStep(
            key: const ValueKey(0),
            shopId: widget.shopId,
            formArg: _formArg,
          ),
        1 => _BarberStep(
            key: const ValueKey(1),
            shopId: widget.shopId,
            formArg: _formArg,
          ),
        _ => _ConfirmStep(
            key: const ValueKey(2),
            formArg: _formArg,
            joinQueue: widget.joinQueue,
          ),
      };

  Future<void> _handleNext() async {
    if (_step < 2) {
      setState(() { _step++; _submitError = null; });
      return;
    }
    setState(() { _submitting = true; _submitError = null; });
    final form = ref.read(bookingFormFamily(_formArg));
    final result = await ref
        .read(bookingSubmitProvider.notifier)
        .submit(form.copyWith(joinQueue: widget.joinQueue));
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result != null) {
      context.go('/queue/${result.id}');
    } else {
      final st = ref.read(bookingSubmitProvider);
      setState(() => _submitError =
          st is BookingFailed ? st.message : 'Booking failed. Please try again.');
    }
  }
}

// ─────────────── Error banner ───────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpacing.base,
        vertical: BBSpacing.sm,
      ),
      color: colors.surfaceVariant,
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: colors.textSecondary, size: 18),
          const SizedBox(width: BBSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: BBTypography.textTheme.bodySmall
                  ?.copyWith(color: colors.text),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded,
                color: colors.textSecondary, size: 18),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─────────────── Step 1: Services ───────────────

class _ServicesStep extends ConsumerWidget {
  const _ServicesStep({
    super.key,
    required this.shopId,
    required this.formArg,
  });
  final String shopId;
  final ({String shopId, String shopName}) formArg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final async = ref.watch(shopServicesProvider(shopId));
    final form = ref.watch(bookingFormFamily(formArg));
    final notifier = ref.read(bookingFormFamily(formArg).notifier);

    return async.when(
      loading: () => const BBSkeletonListView(itemCount: 3),
      error: (e, _) => Center(
        child: Text(e.toString(),
            style: BBTypography.textTheme.bodyMedium
                ?.copyWith(color: context.bbColors.textSecondary)),
      ),
      data: (services) => ListView(
        padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
        children: [
          Text(
            'What do you need?',
            style: BBTypography.textTheme.headlineSmall?.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: BBSpacing.xs),
          Text(
            'Select one service to continue.',
            style: BBTypography.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: BBSpacing.xl),
          ...services.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: BBSpacing.sm),
              child: _ServiceRadioRow(
                service: s,
                selected: form.selectedService?.id == s.id,
                onTap: () => notifier.selectService(s),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRadioRow extends StatelessWidget {
  const _ServiceRadioRow({
    required this.service,
    required this.selected,
    required this.onTap,
  });
  final ServiceItem service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(BBSpacing.base),
        decoration: BoxDecoration(
          color: selected
              ? colors.accent.withValues(alpha: 0.08)
              : colors.surface,
          borderRadius: BorderRadius.circular(BBRadius.md),
          border: Border.all(
            color: selected ? colors.accent : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: BBTypography.textTheme.titleMedium?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${service.durationLabel} · ${service.priceLabel}',
                    style: BBTypography.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  if (service.description != null &&
                      service.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      service.description!,
                      style: BBTypography.textTheme.labelSmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: BBSpacing.md),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? colors.accent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? colors.accent : colors.textTertiary,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: colors.accentForeground,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────── Step 2: Barber ───────────────

class _BarberStep extends ConsumerWidget {
  const _BarberStep({
    super.key,
    required this.shopId,
    required this.formArg,
  });
  final String shopId;
  final ({String shopId, String shopName}) formArg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shopBarbersProvider(shopId));
    final form = ref.watch(bookingFormFamily(formArg));
    final notifier = ref.read(bookingFormFamily(formArg).notifier);

    return async.when(
      loading: () => const BBSkeletonListView(itemCount: 3),
      error: (_, _) => _BarberList(
        barbers: const [],
        form: form,
        notifier: notifier,
      ),
      data: (barbers) => _BarberList(
        barbers: barbers,
        form: form,
        notifier: notifier,
      ),
    );
  }
}

class _BarberList extends StatelessWidget {
  const _BarberList({
    required this.barbers,
    required this.form,
    required this.notifier,
  });
  final List<Barber> barbers;
  final BookingFormData form;
  final BookingFormNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return ListView(
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      children: [
        Text(
          'Choose a barber',
          style: BBTypography.textTheme.headlineSmall?.copyWith(
            color: colors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: BBSpacing.xs),
        Text(
          'Optional — or let us pick the fastest.',
          style: BBTypography.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: BBSpacing.xl),
        _SelectableTile(
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shuffle_rounded,
                size: 18, color: colors.textSecondary),
          ),
          title: 'Any Available',
          subtitle: 'Fastest option',
          selected: form.selectedBarberId == null,
          onTap: () => notifier.selectBarber(null, null),
        ),
        const SizedBox(height: BBSpacing.sm),
        ...barbers.map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: BBSpacing.sm),
            child: _SelectableTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    b.name.isNotEmpty ? b.name[0].toUpperCase() : 'B',
                    style: BBTypography.textTheme.titleMedium?.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              title: b.name,
              subtitle: b.isAvailable ? 'Available' : 'Busy',
              subtitleColor: b.isAvailable ? BBColors.success : null,
              selected: form.selectedBarberId == b.id,
              onTap: b.isAvailable
                  ? () => notifier.selectBarber(b.id, b.name)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.selected,
    this.subtitleColor,
    this.onTap,
  });
  final Widget leading;
  final String title;
  final String subtitle;
  final bool selected;
  final Color? subtitleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final disabled = onTap == null && !selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(BBSpacing.base),
        decoration: BoxDecoration(
          color: selected
              ? colors.accent.withValues(alpha: 0.08)
              : disabled
                  ? colors.surfaceVariant.withValues(alpha: 0.5)
                  : colors.surface,
          borderRadius: BorderRadius.circular(BBRadius.md),
          border: Border.all(
            color: selected ? colors.accent : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: BBSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: BBTypography.textTheme.titleMedium?.copyWith(
                      color: disabled ? colors.textTertiary : colors.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: BBTypography.textTheme.bodySmall?.copyWith(
                      color: subtitleColor ?? colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: colors.accent,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────── Step 3: Confirm ───────────────

class _ConfirmStep extends ConsumerWidget {
  const _ConfirmStep({
    super.key,
    required this.formArg,
    required this.joinQueue,
  });
  final ({String shopId, String shopName}) formArg;
  final bool joinQueue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final form = ref.watch(bookingFormFamily(formArg));

    return ListView(
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      children: [
        Text(
          'Review your booking',
          style: BBTypography.textTheme.headlineSmall?.copyWith(
            color: colors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: BBSpacing.xs),
        Text(
          'Everything look right? Tap Confirm to book.',
          style: BBTypography.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: BBSpacing.xl),
        _SummaryCard(form: form, joinQueue: joinQueue),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.form, required this.joinQueue});
  final BookingFormData form;
  final bool joinQueue;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final service = form.selectedService;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Shop', value: form.shopName),
          Divider(color: colors.border, height: 1, indent: BBSpacing.base),
          _SummaryRow(
            label: 'Service',
            value: service?.name ?? '—',
          ),
          Divider(color: colors.border, height: 1, indent: BBSpacing.base),
          _SummaryRow(
            label: 'Barber',
            value: form.selectedBarberName ?? 'Any Available',
          ),
          Divider(color: colors.border, height: 1, indent: BBSpacing.base),
          _SummaryRow(
            label: 'Mode',
            value: joinQueue ? 'Join Queue' : 'Book',
          ),
          if (service != null) ...[
            Divider(color: colors.border, height: 1, indent: BBSpacing.base),
            _SummaryRow(
              label: 'Duration',
              value: service.durationLabel,
            ),
          ],
          Divider(color: colors.border, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BBSpacing.base,
              vertical: BBSpacing.base,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: BBTypography.textTheme.titleMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  service != null ? service.priceLabel : '₹0',
                  style: BBTypography.textTheme.titleMedium?.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpacing.base,
        vertical: BBSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: BBTypography.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: BBSpacing.base),
          Expanded(
            child: Text(
              value,
              style: BBTypography.textTheme.bodyMedium?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── Bottom bar ───────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.step,
    required this.canProceed,
    required this.submitting,
    required this.onNext,
    this.onBack,
  });
  final int step;
  final bool canProceed;
  final bool submitting;
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (onBack != null) ...[
              BBButton(
                label: 'Back',
                onPressed: onBack,
                variant: BBButtonVariant.secondary,
                expand: false,
              ),
              const SizedBox(width: BBSpacing.sm),
            ],
            Expanded(
              child: BBButton(
                label: step == 2 ? 'Confirm Booking' : 'Continue',
                onPressed: step == 0 && !canProceed ? null : onNext,
                loading: submitting,
                disabled: step == 0 && !canProceed,
                icon: step == 2
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
                iconAfter: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
