import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_button.dart';
import '../../../core/widgets/bb_loading.dart';
import '../../../core/widgets/bb_snackbar.dart';
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
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 3,
            backgroundColor: colors.border,
            valueColor:
                const AlwaysStoppedAnimation<Color>(BBColors.amber),
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
            _BottomBar(
              step: _step,
              canProceed: form.selectedServices.isNotEmpty,
              submitting: _submitting,
              onBack: _step > 0 ? () => setState(() => _step--) : null,
              onNext: _step == 0 && form.selectedServices.isEmpty
                  ? null
                  : _handleNext,
            ),
          ],
        ),
      ),
    );
  }

  String get _stepTitle => switch (_step) {
        0 => 'Select Services',
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
      setState(() => _step++);
      return;
    }
    setState(() => _submitting = true);
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
      showBBSnackbar(
        context,
        message: st is BookingFailed ? st.message : 'Booking failed.',
        isError: true,
      );
    }
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
      loading: () => const Center(child: BBLoader()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (services) => ListView(
        padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
        children: [
          Text(
            'What do you need?',
            style: BBTypography.textTheme.headlineSmall?.copyWith(
              color: colors.text,
            ),
          ),
          const SizedBox(height: BBSpacing.sm),
          Text(
            'Select one or more services',
            style: BBTypography.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: BBSpacing.xl),
          ...services.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: BBSpacing.sm),
              child: _ServiceCheckRow(
                service: s,
                selected: form.selectedServices.any((ss) => ss.id == s.id),
                onTap: () => notifier.toggleService(s),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCheckRow extends StatelessWidget {
  const _ServiceCheckRow({
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
              ? BBColors.amber.withValues(alpha: 0.08)
              : colors.surface,
          borderRadius: BorderRadius.circular(BBRadius.md),
          border: Border.all(
            color: selected ? BBColors.amber : colors.border,
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
                    ),
                  ),
                  Text(
                    '${service.durationLabel} · ${service.priceLabel}',
                    style: BBTypography.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? BBColors.amber : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? BBColors.amber : colors.textTertiary,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Color(0xFF09090B),
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
      loading: () => const Center(child: BBLoader()),
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
          ),
        ),
        const SizedBox(height: BBSpacing.sm),
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
                  color: BBColors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    b.name.isNotEmpty ? b.name[0].toUpperCase() : 'B',
                    style: BBTypography.textTheme.titleMedium?.copyWith(
                      color: BBColors.amber,
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
              ? BBColors.amber.withValues(alpha: 0.08)
              : disabled
                  ? colors.surfaceVariant.withValues(alpha: 0.5)
                  : colors.surface,
          borderRadius: BorderRadius.circular(BBRadius.md),
          border: Border.all(
            color: selected ? BBColors.amber : colors.border,
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
              const Icon(
                Icons.check_circle_rounded,
                color: BBColors.amber,
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
          'Confirm Booking',
          style: BBTypography.textTheme.headlineSmall?.copyWith(
            color: colors.text,
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
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          _Row(
            label: 'Shop',
            value: form.shopName,
            colors: colors,
          ),
          Divider(color: colors.border, height: BBSpacing.base * 2),
          _Row(
            label: 'Services',
            value: form.selectedServices.map((s) => s.name).join(', '),
            colors: colors,
          ),
          Divider(color: colors.border, height: BBSpacing.base * 2),
          _Row(
            label: 'Barber',
            value: form.selectedBarberName ?? 'Any Available',
            colors: colors,
          ),
          Divider(color: colors.border, height: BBSpacing.base * 2),
          _Row(
            label: 'Mode',
            value: joinQueue ? 'Join Queue' : 'Book',
            colors: colors,
          ),
          Divider(color: colors.border, height: BBSpacing.base * 2),
          _Row(
            label: 'Duration',
            value: '${form.totalDuration} min',
            colors: colors,
          ),
          Divider(color: colors.border, height: BBSpacing.base * 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: BBTypography.textTheme.titleLarge?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '₹${form.totalAmount.toStringAsFixed(0)}',
                style: BBTypography.textTheme.titleLarge?.copyWith(
                  color: BBColors.amber,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.colors,
  });
  final String label;
  final String value;
  final BBColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
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
                label: step == 2 ? 'Confirm' : 'Continue',
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
