import 'package:flutter/material.dart';
import '../../../core/design/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/bb_button.dart';
import '../../../core/widgets/bb_snackbar.dart';
import '../../../core/widgets/bb_text_field.dart';
import '../dashboard/barber_provider.dart';

class ReceptionScreen extends ConsumerStatefulWidget {
  const ReceptionScreen({super.key});

  @override
  ConsumerState<ReceptionScreen> createState() => _ReceptionScreenState();
}

class _ReceptionScreenState extends ConsumerState<ReceptionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Reception Mode'),
        bottom: TabBar(
          controller: _tab,
          labelColor: colors.text,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: BBColors.amber,
          tabs: const [
            Tab(text: 'Walk-In'),
            Tab(text: 'Search Customer'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _WalkInTab(),
          _SearchCustomerTab(),
        ],
      ),
    );
  }
}

// ── Walk-In Tab ───────────────────────────────────────────────────────────────

class _WalkInTab extends ConsumerStatefulWidget {
  const _WalkInTab();

  @override
  ConsumerState<_WalkInTab> createState() => _WalkInTabState();
}

class _WalkInTabState extends ConsumerState<_WalkInTab> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _selectedService;
  String? _selectedChair;
  bool _adding = false;

  static const _services = ['Haircut', 'Fade', 'Beard Trim', 'Hair + Beard', 'Kids Haircut', 'Classic Shave'];
  static const _chairs = ['Chair 1', 'Chair 2', 'Chair 3'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: BBSpacing.base),
          Container(
            padding: const EdgeInsets.all(BBSpacing.base),
            decoration: BoxDecoration(
              color: BBColors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(BBRadius.lg),
              border: Border.all(color: BBColors.amber.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(AppIcons.personAdd,
                    color: BBColors.amber, size: 24),
                const SizedBox(width: BBSpacing.md),
                Expanded(
                  child: Text(
                    'Add a walk-in customer directly to the queue',
                    style: BBTypography.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BBSpacing.xl),
          BBTextField(
            label: 'Customer Name',
            hint: 'e.g. Rahul Kumar',
            controller: _nameCtrl,
            prefixIcon: AppIcons.personOutline,
          ),
          const SizedBox(height: BBSpacing.md),
          BBTextField(
            label: 'Phone (optional)',
            hint: '+91 98765 43210',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            prefixIcon: AppIcons.phone,
          ),
          const SizedBox(height: BBSpacing.md),
          Text(
            'SERVICE',
            style: BBTypography.textTheme.labelSmall?.copyWith(
              color: colors.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: BBSpacing.sm),
          Wrap(
            spacing: BBSpacing.sm,
            runSpacing: BBSpacing.sm,
            children: _services
                .map((s) => GestureDetector(
                      onTap: () => setState(() => _selectedService = s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedService == s
                              ? BBColors.amber
                              : colors.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(BBRadius.full),
                          border: Border.all(
                            color: _selectedService == s
                                ? BBColors.amber
                                : colors.border,
                          ),
                        ),
                        child: Text(
                          s,
                          style: BBTypography.textTheme.labelMedium?.copyWith(
                            color: _selectedService == s
                                ? colors.background
                                : colors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: BBSpacing.md),
          Text(
            'ASSIGN CHAIR (optional)',
            style: BBTypography.textTheme.labelSmall?.copyWith(
              color: colors.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: BBSpacing.sm),
          Row(
            children: _chairs
                .map((c) => Padding(
                      padding: const EdgeInsets.only(right: BBSpacing.sm),
                      child: GestureDetector(
                        onTap: () => setState(() =>
                            _selectedChair = _selectedChair == c ? null : c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedChair == c
                                ? BBColors.amber.withValues(alpha: 0.12)
                                : colors.surfaceVariant,
                            borderRadius:
                                BorderRadius.circular(BBRadius.full),
                            border: Border.all(
                              color: _selectedChair == c
                                  ? BBColors.amber
                                  : colors.border,
                            ),
                          ),
                          child: Text(
                            c,
                            style:
                                BBTypography.textTheme.labelMedium?.copyWith(
                              color: _selectedChair == c
                                  ? BBColors.amber
                                  : colors.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: BBSpacing.xl),
          BBButton(
            label: 'Add to Queue',
            icon: AppIcons.queue,
            loading: _adding,
            onPressed: _selectedService == null || _nameCtrl.text.isEmpty
                ? null
                : _addToQueue,
          ),
        ],
      ),
    );
  }

  Future<void> _addToQueue() async {
    if (_nameCtrl.text.isEmpty || _selectedService == null) return;
    setState(() => _adding = true);
    try {
      final dash = ref.read(barberDashProvider);
      if (dash.profile == null) throw Exception('Profile not loaded');
      final api = ref.read(apiClientProvider);
      await api.post<void>(
        '/shops/${dash.profile!.shopId}/queue/walk-in',
        body: {
          'customerName': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'serviceNames': [_selectedService!],
          if (_selectedChair != null) 'chairLabel': _selectedChair,
        },
      );
      if (mounted) {
        _nameCtrl.clear();
        _phoneCtrl.clear();
        setState(() {
          _selectedService = null;
          _selectedChair = null;
        });
        showBBSnackbar(context,
            message: 'Walk-in added to queue!', isSuccess: true);
      }
    } catch (e) {
      if (mounted) showBBSnackbar(context, message: e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }
}

// ── Search Customer Tab ────────────────────────────────────────────────────────

class _SearchCustomerTab extends StatefulWidget {
  const _SearchCustomerTab();

  @override
  State<_SearchCustomerTab> createState() => _SearchCustomerTabState();
}

class _SearchCustomerTabState extends State<_SearchCustomerTab> {
  final _searchCtrl = TextEditingController();

  static const _mockCustomers = [
    ('Rahul Kumar', '+91 98765 43210', '5 visits', 'Gold'),
    ('Priya Singh', '+91 87654 32109', '2 visits', 'Bronze'),
    ('Ankit Sharma', '+91 76543 21098', '12 visits', 'Platinum'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
          child: BBTextField(
            label: 'Search',
            hint: 'Name or phone number',
            controller: _searchCtrl,
            prefixIcon: AppIcons.search,
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: BBSpacing.pageHorizontal),
            itemCount: _mockCustomers.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: BBSpacing.sm),
            itemBuilder: (ctx, i) {
              final c = _mockCustomers[i];
              return Container(
                padding: const EdgeInsets.all(BBSpacing.base),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(BBRadius.lg),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: BBColors.amber.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          c.$1[0].toUpperCase(),
                          style:
                              BBTypography.textTheme.titleMedium?.copyWith(
                            color: BBColors.amber,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: BBSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.$1,
                            style:
                                BBTypography.textTheme.titleSmall?.copyWith(
                              color: colors.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            c.$2,
                            style:
                                BBTypography.textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          Text(
                            '${c.$3} · ${c.$4} tier',
                            style:
                                BBTypography.textTheme.labelSmall?.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Check In'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
